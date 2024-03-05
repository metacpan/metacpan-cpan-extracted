=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Latn::Do - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Latn::Do;
# This file auto generated from Data\common\main\es_DO.xml
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
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}d.),
						'other' => q({0}d.),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}d.),
						'other' => q({0}d.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(seg.),
						'one' => q({0} seg.),
						'other' => q({0} seg.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(seg.),
						'one' => q({0} seg.),
						'other' => q({0} seg.),
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

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤#,##0.00)',
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
		'DOP' => {
			symbol => 'RD$',
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
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
					'pm' => q{p. m.},
				},
				'narrow' => {
					'evening1' => q{tarde},
					'morning1' => q{día},
					'morning2' => q{mañana},
					'night1' => q{noche},
					'noon' => q{mediodía},
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
			'medium' => q{dd/MM/y G},
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
		'gregorian' => {
			yMMMd => q{d MMM 'de' y},
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

no Moo;

1;

# vim: tabstop=4
