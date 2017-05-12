=head1

Locale::CLDR::Locales::Es::Any::419 - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::419;
# This file auto generated from Data\common\main\es_419.xml
#	on Fri 29 Apr  7:00:37 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Es::Any');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'digits-ordinal-masculine-adjective','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'digits-ordinal' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-masculine=),
				},
			},
		},
		'digits-ordinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ª.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ª.),
				},
			},
		},
		'digits-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=º.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=º.),
				},
			},
		},
		'digits-ordinal-masculine-adjective' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%dord-mascabbrev=.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%dord-mascabbrev=.),
				},
			},
		},
		'dord-mascabbrev' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(º),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ᵉʳ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(º),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ᵉʳ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(º),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→→),
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
				'en_GB@alt=short' => 'inglés (R. U.)',
 				'eu' => 'vasco',
 				'luo' => 'luo',
 				'ps@alt=variant' => 'pashtún',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili del Congo',
 				'ug@alt=variant' => 'uighur',
 				'vai' => 'vai',

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
			'035' => 'Asia sudoriental',
 			'GB@alt=short' => 'R. U.',
 			'IC' => 'islas Canarias',
 			'QO' => 'Islas Ultramarinas',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'ms' => 'sm',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'numbers' => {
 				'knda' => q{números en kannada},
 				'laoo' => q{números en lao},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'script' => 'Alfabeto: {0}',

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre-foot' => {
						'one' => q({0} acre pie),
						'other' => q({0} acres pies),
					},
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					'horsepower' => {
						'name' => q(caballos de fuerza),
						'one' => q({0} caballo de vapor),
						'other' => q({0} caballos de fuerza),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojule),
						'other' => q({0} kilojules),
					},
					'kilowatt-hour' => {
						'name' => q(kilovatios hora),
						'one' => q({0} kilovatio hora),
						'other' => q({0} kilovatios hora),
					},
					'milliampere' => {
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					'ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohmios),
					},
					'volt' => {
						'one' => q({0} volt),
						'other' => q({0} voltios),
					},
				},
				'narrow' => {
					'day' => {
						'name' => q(d.),
						'one' => q({0}d.),
						'other' => q({0}dd.),
					},
					'month' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}mm.),
					},
					'week' => {
						'name' => q(sem.),
						'one' => q({0}sem.),
						'other' => q({0}sems.),
					},
					'year' => {
						'name' => q(a.),
						'one' => q({0}a.),
						'other' => q({0}aa.),
					},
				},
				'short' => {
					'day' => {
						'name' => q(dd.),
						'one' => q({0} d.),
						'other' => q({0} dd.),
					},
					'light-year' => {
						'name' => q(aa. l.),
						'one' => q({0} a. l.),
						'other' => q({0} aa. l.),
					},
					'month' => {
						'name' => q(mm.),
						'one' => q({0} m.),
						'other' => q({0} mm.),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'parsec' => {
						'name' => q(parsecs),
					},
					'pint' => {
						'name' => q(pintas),
					},
					'tablespoon' => {
						'name' => q(cdas.),
						'one' => q({0} cda.),
						'other' => q({0} cdas.),
					},
					'teaspoon' => {
						'name' => q(cdtas.),
						'one' => q({0} cdta.),
						'other' => q({0} cdtas.),
					},
					'volt' => {
						'name' => q(volts),
					},
					'watt' => {
						'name' => q(watts),
					},
					'week' => {
						'name' => q(sems.),
						'one' => q({0} sem.),
						'other' => q({0} sems.),
					},
					'yard' => {
						'name' => q(yardas),
					},
					'year' => {
						'name' => q(aa.),
						'one' => q({0} a.),
						'other' => q({0} aa.),
					},
				},
			} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
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
			'short' => {
				'1000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '00k',
					'other' => '00k',
				},
				'100000' => {
					'one' => '000k',
					'other' => '000k',
				},
				'1000000000' => {
					'one' => '0k M',
					'other' => '0k M',
				},
				'10000000000' => {
					'one' => '00k M',
					'other' => '00k M',
				},
				'100000000000' => {
					'one' => '000k M',
					'other' => '000k M',
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
		'AMD' => {
			display_name => {
				'currency' => q(dram armenio),
			},
		},
		'BGN' => {
			display_name => {
				'one' => q(lev búlgaro),
				'other' => q(leva búlgaros),
			},
		},
		'CAD' => {
			symbol => 'CAD',
		},
		'EGP' => {
			symbol => 'E£',
		},
		'ERN' => {
			display_name => {
				'currency' => q(nafka),
			},
		},
		'EUR' => {
			symbol => 'EUR',
		},
		'THB' => {
			symbol => 'THB',
		},
		'USD' => {
			symbol => 'USD',
		},
		'VEF' => {
			symbol => 'BsF',
		},
		'VND' => {
			symbol => 'VND',
		},
		'XXX' => {
			display_name => {
				'one' => q(\(unidad de moneda desconocida\)),
				'other' => q(\(moneda desconocida\)),
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
							'ene.',
							'feb.',
							'mar.',
							'abr.',
							'may.',
							'jun.',
							'jul.',
							'ago.',
							'sep.',
							'oct.',
							'nov.',
							'dic.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'e',
							'f',
							'm',
							'a',
							'm',
							'j',
							'j',
							'a',
							's',
							'o',
							'n',
							'd'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'ene.',
							'feb.',
							'mar.',
							'abr.',
							'may.',
							'jun.',
							'jul.',
							'ago.',
							'sep.',
							'oct.',
							'nov.',
							'dic.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'e',
							'f',
							'm',
							'a',
							'm',
							'j',
							'j',
							'a',
							's',
							'o',
							'n',
							'd'
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
						mon => 'l',
						tue => 'm',
						wed => 'm',
						thu => 'j',
						fri => 'v',
						sat => 's',
						sun => 'd'
					},
				},
				'stand-alone' => {
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
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'night1' if $time >= 2000
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
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
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'night1' if $time >= 2000
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 600;
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
				'wide' => {
					'pm' => q{p.m.},
					'am' => q{a.m.},
				},
				'narrow' => {
					'morning2' => q{mañana},
					'noon' => q{m.},
					'night1' => q{noche},
					'morning1' => q{madrugada},
					'evening1' => q{tarde},
				},
				'abbreviated' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'wide' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
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
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
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
			GyMMM => q{MMM 'de' y G},
			GyMMMd => q{d 'de' MMM 'de' y G},
			MMMEd => q{E, d 'de' MMM},
			MMMd => q{d 'de' MMM},
			yMEd => q{E d/M/y G},
		},
		'gregorian' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			GyMMMd => q{d 'de' MMM 'de' y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			MMMdd => q{dd-MMM},
			yMEd => q{E d/M/y},
			yMMM => q{MMMM 'de' y},
			yMMMEd => q{E, d 'de' MMM 'de' y},
			yMMMd => q{d 'de' MMMM 'de' y},
			yQQQ => q{QQQ 'de' y},
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
			MEd => {
				M => q{E, d/M–E, d/M},
				d => q{E, d/M–E, d/M},
			},
			MMMEd => {
				M => q{E, d 'de' MMM–E, d 'de' MMM},
				d => q{E, d 'de' MMM–E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM–d 'de' MMM},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			MEd => {
				M => q{E, d/M–E, d/M},
				d => q{E, d/M–E, d/M},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d – d 'de' MMM},
			},
			h => {
				a => q{h a–h a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
			},
			hv => {
				a => q{h a–h a v},
			},
			yMEd => {
				M => q{E, d/M/y–E, d/M/y},
				d => q{E, d/M/y–E, d/M/y},
				y => q{E, d/M/y–E, d/M/y},
			},
			yMMM => {
				y => q{MMM 'de' y – MMM 'de' y},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y},
			},
			yMMMM => {
				y => q{MMMM 'de' y–MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y},
				d => q{d – d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(hora de verano de {0}),
		regionFormat => q(hora estándar de {0}),
		'America/St_Johns' => {
			exemplarCity => q#San Juan de Terranova#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Cristóbal#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Chamorro' => {
			long => {
				'standard' => q(hora de Chamorro),
			},
		},
		'Christmas' => {
			long => {
				'standard' => q(hora de la isla Christmas),
			},
		},
		'Cocos' => {
			long => {
				'standard' => q(hora de las islas Cocos),
			},
		},
		'Cook' => {
			long => {
				'daylight' => q(hora de verano media de las islas Cook),
				'generic' => q(hora de las islas Cook),
				'standard' => q(hora estándar de las islas Cook),
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ciudad desconocida#,
		},
		'Europe_Central' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'Europe_Eastern' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q(horario del lejano este de Europa),
			},
		},
		'Europe_Western' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'GMT' => {
			short => {
				'standard' => q(∅∅∅),
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q(hora de verano de Hawái-Aleutianas),
				'generic' => q(hora de Hawái-Aleutianas),
				'standard' => q(hora estándar de Hawái-Aleutianas),
			},
		},
		'India' => {
			long => {
				'standard' => q(hora de India),
			},
		},
		'Pacific/Wake' => {
			exemplarCity => q#Isla Wake#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
