=head1

Locale::CLDR::Locales::Es::Any::Gt - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Gt;
# This file auto generated from Data\common\main\es_GT.xml
#	on Fri 29 Apr  7:00:43 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Es::Any::419');
has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'ampere' => {
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					'cubic-centimeter' => {
						'per' => q({0} por pie cúbico),
					},
					'day' => {
						'per' => q({0} al día),
					},
					'horsepower' => {
						'one' => q({0} caballos de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					'joule' => {
						'name' => q(julios),
						'one' => q({0} julio),
						'other' => q({0} julios),
					},
					'kilojoule' => {
						'name' => q(kilojulios),
						'one' => q({0} kilojulio),
						'other' => q({0} kilojulios),
					},
					'mile-scandinavian' => {
						'name' => q(milla escandinava),
					},
					'milliampere' => {
						'name' => q(miliamperios),
						'one' => q({0} miliamperio),
						'other' => q({0} miliamperios),
					},
					'month' => {
						'per' => q({0} al mes),
					},
					'ohm' => {
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					'volt' => {
						'one' => q({0} voltio),
						'other' => q({0} voltios),
					},
					'year' => {
						'per' => q({0} al año),
					},
				},
				'narrow' => {
					'hour' => {
						'name' => q(hora),
					},
				},
				'short' => {
					'acre-foot' => {
						'name' => q(acre pie),
					},
					'foot' => {
						'name' => q(pie),
					},
					'karat' => {
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'volt' => {
						'name' => q(voltios),
					},
					'watt' => {
						'name' => q(vatios),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'GTQ' => {
			symbol => 'Q',
			display_name => {
				'currency' => q(quetzal),
				'one' => q(quetzal),
				'other' => q(quetzales),
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
			MEd => {
				M => q{E d/MM – E d/MM},
				d => q{E d/MM – E d/MM},
			},
			MMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM},
				d => q{E d 'al' E d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM},
			},
			Md => {
				M => q{d/MM – d/MM},
				d => q{d/MM – d/MM},
			},
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			y => {
				y => q{y 'al' y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E d/MM/y – E d/MM/y},
				d => q{E d/MM/y – E d/MM/y},
				y => q{E d/MM/y – E d/MM/y},
			},
			yMMM => {
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM 'de' y},
				d => q{E d 'al' E d 'de' MMM 'de' y},
				y => q{E d 'de' MMM 'de' y 'al' E d 'de' MMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y 'al' d 'de' MMM 'de' y},
			},
			yMd => {
				M => q{d/MM/y – d/MM/y},
				d => q{d/MM/y – d/MM/y},
				y => q{d/MM/y – d/MM/y},
			},
		},
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
				M => q{E d/MM – E d/MM},
				d => q{E d/MM – E d/MM},
			},
			MMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM},
				d => q{E d 'al' E d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM},
			},
			Md => {
				M => q{d/MM – d/MM},
				d => q{d/MM – d/MM},
			},
			fallback => '{0} a el {1}',
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E d/MM/y – E d/MM/y},
				d => q{E d/MM/y – E d/MM/y},
				y => q{E d/MM/y – E d/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y},
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM 'de' y},
				d => q{E d 'al' E d 'de' MMM 'de' y},
				y => q{E d 'de' MMM 'de' y 'al' E d 'de' MMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM 'de' y},
				d => q{d–d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y 'al' d 'de' MMM 'de' y},
			},
			yMd => {
				M => q{d/MM/y – d/MM/y},
				d => q{d/MM/y – d/MM/y},
				y => q{d/MM/y – d/MM/y},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
