=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Latn::Ar - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Latn::Ar;
# This file auto generated from Data\common\main\es_AR.xml
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

extends('Locale::CLDR::Locales::Es::Latn::419');
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
 			'TL' => 'Timor-Leste',
 			'UM' => 'Islas menores alejadas de EE. UU.',

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0}/año),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0}/año),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamperios),
						'one' => q({0} miliamperio),
						'other' => q({0} miliamperios),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamperios),
						'one' => q({0} miliamperio),
						'other' => q({0} miliamperios),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(julios),
						'one' => q({0} julio),
						'other' => q({0} julios),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(julios),
						'one' => q({0} julio),
						'other' => q({0} julios),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojulios),
						'one' => q({0} kilojulio),
						'other' => q({0} kilojulios),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojulios),
						'one' => q({0} kilojulio),
						'other' => q({0} kilojulios),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}seg.),
						'other' => q({0}seg.),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}seg.),
						'other' => q({0}seg.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}a.),
						'other' => q({0}a.),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}a.),
						'other' => q({0}a.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hs.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hs.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(seg.),
						'one' => q({0} seg.),
						'other' => q({0} seg.),
						'per' => q({0}/seg.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(seg.),
						'one' => q({0} seg.),
						'other' => q({0} seg.),
						'per' => q({0}/seg.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(años),
						'one' => q({0} año),
						'other' => q({0} años),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(años),
						'one' => q({0} año),
						'other' => q({0} años),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(voltios),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(voltios),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vatios),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vatios),
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
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
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
		'ARS' => {
			symbol => '$',
		},
		'USD' => {
			symbol => 'US$',
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
					'am' => q{a. m.},
					'evening1' => q{tarde},
					'morning1' => q{madrugada},
					'morning2' => q{mañana},
					'night1' => q{noche},
					'noon' => q{mediodía},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'narrow' => {
					'am' => q{a. m.},
					'noon' => q{m.},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
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
			MEd => q{E d-M},
			yyyyM => q{M-y G},
		},
		'gregorian' => {
			GyMMMEd => q{E, d 'de' MMM 'de' y G},
			GyMMMd => q{d MMM y G},
			Hmsvvvv => q{HH:mm:ss (vvvv)},
			MEd => q{E d-M},
			hms => q{hh:mm:ss},
			yM => q{M-y},
			yMEd => q{E, d/M/y},
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
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM},
				d => q{E d 'al' E d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			fallback => '{0} a el {1}',
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y G},
				d => q{E dd/MM/y – E dd/MM/y G},
				y => q{E dd/MM/y – E dd/MM/y G},
			},
			yMMM => {
				y => q{MMM 'de' y 'a' MMM 'de' y G},
			},
			yMMMEd => {
				d => q{E d 'al' E d 'de' MMM 'de' y G},
				y => q{E d 'de' MMM 'de' y 'al' E d 'de' MMM 'de' y G},
			},
			yMMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y 'al' d 'de' MMM 'de' y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
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
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM},
				d => q{E d 'al' E d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM},
				d => q{dd – dd 'de' MM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			fallback => '{0} a el {1}',
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
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM 'al' E, d 'de' MMM 'de' y},
				d => q{E, d 'al' E, d 'de' MMM 'de' y},
				y => q{E, d 'de' MMM 'de' y 'al' E, d 'de' MMM 'de' y},
			},
			yMMMM => {
				M => q{MMMM 'al' MMMM 'de' y},
				y => q{MMMM 'de' y 'al' MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y 'al' d 'de' MMM 'de' y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Argentina' => {
			short => {
				'daylight' => q#ARST#,
				'generic' => q#ART#,
				'standard' => q#ART#,
			},
		},
		'Argentina_Western' => {
			short => {
				'daylight' => q#WARST#,
				'generic' => q#WART#,
				'standard' => q#WART#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
