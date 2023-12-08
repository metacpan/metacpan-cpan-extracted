=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Any::Co - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Co;
# This file auto generated from Data\common\main\es_CO.xml
#	on Tue  5 Dec  1:08:38 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

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
 				'bho' => 'bhojpuri',
 				'eu' => 'euskera',
 				'grc' => 'griego antiguo',
 				'lo' => 'lao',
 				'nso' => 'sotho septentrional',
 				'pa' => 'punyabí',
 				'ss' => 'siswati',
 				'sw' => 'suajili',
 				'sw_CD' => 'suajili del Congo',
 				'tn' => 'setswana',
 				'wo' => 'wolof',
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
			'BA' => 'Bosnia y Herzegovina',
 			'GB@alt=short' => 'RU',
 			'TA' => 'Tristán de Acuña',
 			'TL' => 'Timor-Leste',
 			'UM' => 'Islas menores alejadas de EE. UU.',
 			'VI' => 'Islas Vírgenes de EE. UU.',

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'month' => {
						'per' => q({0}/mes),
					},
					'week' => {
						'per' => q({0}/sem.),
					},
				},
				'narrow' => {
					'day' => {
						'name' => q(día),
						'one' => q({0} día),
						'other' => q({0} días),
					},
					'hour' => {
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'millisecond' => {
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'name' => q(mes),
						'one' => q({0} mes),
						'other' => q({0} meses),
					},
					'second' => {
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'week' => {
						'one' => q({0} sem.),
						'other' => q({0} sems.),
					},
					'year' => {
						'one' => q({0} a.),
						'other' => q({0} a.),
					},
				},
				'short' => {
					'day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0}/día),
					},
					'month' => {
						'name' => q(mes),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0}/mes),
					},
					'year' => {
						'name' => q(a.),
						'one' => q({0} a.),
						'other' => q({0} a.),
						'per' => q({0}/año),
					},
				},
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
						'positive' => '¤ #,##0.00',
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
		'COP' => {
			symbol => '$',
		},
		'USD' => {
			symbol => 'US$',
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
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
							'sept.',
							'oct.',
							'nov.',
							'dic.'
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
				},
				'stand-alone' => {
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
				'abbreviated' => {
					'am' => q{a. m.},
					'evening1' => q{de la tarde},
					'morning2' => q{de la mañana},
					'night1' => q{de la noche},
					'noon' => q{m.},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a. m.},
					'noon' => q{m.},
					'pm' => q{p. m.},
				},
				'narrow' => {
					'am' => q{a. m.},
					'noon' => q{m.},
					'pm' => q{p. m.},
				},
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
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'medium' => q{d/MM/y G},
			'short' => q{d/MM/yy GGGGG},
		},
		'gregorian' => {
			'medium' => q{d/MM/y},
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
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
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
			GyMMMEd => q{E, d MMM 'de' y G},
		},
		'gregorian' => {
			GyMMM => q{MMM 'de' y G},
			GyMMMEd => q{E, d MMM 'de' y G},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MMMEd => q{E, d 'de' MMM},
			MMMd => q{d 'de' MMM},
			MMMdd => q{d 'de' MMM},
			yMEd => q{EEE, d/M/y},
			yMMM => q{MMM 'de' y},
			yMMMd => q{d 'de' MMM 'de' y},
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
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H:mm–H:mm},
				m => q{H:mm–H:mm},
			},
			Hmv => {
				H => q{H:mm–H:mm v},
				m => q{H:mm–H:mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M 'a' M},
			},
			MEd => {
				M => q{E d/MM 'al' E d/MM},
				d => q{E d/MM 'a' E d/MM},
			},
			MMM => {
				M => q{MMM 'a' MMM},
			},
			MMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM},
				d => q{E d 'al' E d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM},
				d => q{d 'a' d 'de' MMM},
			},
			Md => {
				M => q{d/MM 'al' d/MM},
				d => q{d/MM 'a' d/MM},
			},
			d => {
				d => q{d 'a' d},
			},
			fallback => '{0} ‘al’ {1}',
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			y => {
				y => q{y 'a' y G},
			},
			yM => {
				M => q{M/y 'a' M/y GGGGG},
				y => q{M/y 'al' M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y 'al' E, d/M/y GGGGG},
				d => q{E, d/M/y 'a' E, d/M/y GGGGG},
				y => q{E, d/M/y 'al' E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM 'a' MMM 'de' y G},
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM 'de' y G},
				d => q{E d 'de' MMM 'al' E d 'de' MMM 'de' y G},
				y => q{E d 'de' MMM 'de' y 'al' E d 'de' MMM 'de' y G},
			},
			yMMMM => {
				M => q{MMMM 'a' MMMM 'de' y G},
				y => q{MMMM 'de' y 'a' MMMM 'de' y G},
			},
			yMMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM y G},
				d => q{d 'a' d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y 'al' d 'de' MMM 'de' y G},
			},
			yMd => {
				M => q{d/M/y 'al' d/M/y GGGGG},
				d => q{d/M/y 'a' d/M/y GGGGG},
				y => q{d/M/y 'al' d/M/y GGGGG},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH 'a' HH},
			},
			Hm => {
				H => q{HH:mm 'a' HH:mm},
				m => q{HH:mm 'a' HH:mm},
			},
			Hmv => {
				H => q{HH:mm 'a' HH:mm v},
				m => q{HH:mm 'a' HH:mm v},
			},
			Hv => {
				H => q{HH 'a' HH v},
			},
			M => {
				M => q{M 'a' M},
			},
			MEd => {
				M => q{E d/MM 'al' E d/MM},
				d => q{E d/MM 'a' E d/MM},
			},
			MMM => {
				M => q{MMM 'a' MMM},
			},
			MMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM},
				d => q{E d 'al' E d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM},
				d => q{d 'a' d 'de' MMM},
			},
			Md => {
				M => q{d/MM 'al' d/MM},
				d => q{d/MM 'a' d/MM},
			},
			d => {
				d => q{d 'a' d},
			},
			fallback => '{0} ‘al’ {1}',
			h => {
				a => q{h a 'a' h a},
				h => q{h 'a' h a},
			},
			hm => {
				a => q{h:mm a 'a' h:mm a},
				h => q{h:mm 'a' h:mm a},
				m => q{h:mm 'a' h:mm a},
			},
			hmv => {
				a => q{h:mm a 'a' h:mm a v},
				h => q{h:mm 'a' h:mm a v},
				m => q{h:mm 'a' h:mm a v},
			},
			hv => {
				a => q{h a 'a' h a v},
				h => q{h 'a' h a v},
			},
			y => {
				y => q{y 'a' y},
			},
			yM => {
				M => q{MM/y 'a' MM/y},
				y => q{MM/y 'al' MM/y},
			},
			yMEd => {
				M => q{E d/MM/y 'al' E d/MM/y},
				d => q{E d/MM/y 'a' E d/MM/y},
				y => q{E d/MM/y 'al' E d/MM/y},
			},
			yMMM => {
				M => q{MMM 'a' MMM 'de' y},
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM 'de' y},
				d => q{E d 'al' E d 'de' MMM 'de' y},
				y => q{E d 'de' MMM 'de' y 'al' E d 'de' MMM 'de' y},
			},
			yMMMM => {
				M => q{MMMM 'a' MMMM 'de' y},
				y => q{MMMM 'de' y 'a' MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM 'de' y},
				d => q{d 'a' d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y 'al' d 'de' MMM 'de' y},
			},
			yMd => {
				M => q{d/MM/y 'al' d/MM/y},
				d => q{d/MM/y 'a' d/MM/y},
				y => q{d/MM/y 'al' d/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Colombia' => {
			short => {
				'daylight' => q#COST#,
				'generic' => q#COT#,
				'standard' => q#COT#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
