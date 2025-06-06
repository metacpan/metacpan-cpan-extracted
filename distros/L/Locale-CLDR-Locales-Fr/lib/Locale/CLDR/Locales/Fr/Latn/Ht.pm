=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fr::Latn::Ht - Package for language French

=cut

package Locale::CLDR::Locales::Fr::Latn::Ht;
# This file auto generated from Data\common\main\fr_HT.xml
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

extends('Locale::CLDR::Locales::Fr::Latn');
has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(carreau),
						'one' => q({0}carreau),
						'other' => q({0}carreaux),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(carreau),
						'one' => q({0}carreau),
						'other' => q({0}carreaux),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'per' => q({0} pour chaque centimetre cube),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'per' => q({0} pour chaque centimetre cube),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'per' => q({0} pour chaque metre cube),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'per' => q({0} pour chaque metre cube),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gr.),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gr.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sec),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sec),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kr),
						'one' => q({0}kr),
						'other' => q({0}kr),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kr),
						'one' => q({0}kr),
						'other' => q({0}kr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'HTG' => {
			symbol => 'G',
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
					'afternoon1' => q{de l’après-midi},
					'evening1' => q{du soir},
					'midnight' => q{minuit},
					'morning1' => q{du matin},
					'night1' => q{de la nuit},
					'noon' => q{midi},
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
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
	} },
);

no Moo;

1;

# vim: tabstop=4
