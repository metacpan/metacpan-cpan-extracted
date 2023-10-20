=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Any::Bo - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Bo;
# This file auto generated from Data\common\main\es_BO.xml
#	on Fri 13 Oct  9:14:03 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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

		}
	},
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

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BOB' => {
			symbol => 'Bs',
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
					'pm' => q{p. m.},
				},
				'narrow' => {
					'am' => q{a. m.},
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
			'medium' => q{d MMM 'de' y},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Bolivia' => {
			short => {
				'standard' => q#BOT#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
