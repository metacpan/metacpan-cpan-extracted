=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ro::Latn::Md - Package for language Romanian

=cut

package Locale::CLDR::Locales::Ro::Latn::Md;
# This file auto generated from Data\common\main\ro_MD.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ro::Latn');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'sw_CD' => 'swahili (R. D. Congo)',
 				'wal' => 'wolaytta',

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
			'MM' => 'Myanmar',

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} zile),
						'one' => q({0} zi),
						'other' => q({0} zile),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} zile),
						'one' => q({0} zi),
						'other' => q({0} zile),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msec),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msec),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} min.),
						'name' => q(min),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} min.),
						'name' => q(min),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} luni),
						'name' => q(lună),
						'one' => q({0} lună),
						'other' => q({0} luni),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} luni),
						'name' => q(lună),
						'one' => q({0} lună),
						'other' => q({0} luni),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} ani),
						'one' => q({0} an),
						'other' => q({0} ani),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} ani),
						'one' => q({0} an),
						'other' => q({0} ani),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisec.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisec.),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'MDL' => {
			symbol => 'L',
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
					abbreviated => {
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Mie',
						thu => 'Joi',
						fri => 'Vin',
						sat => 'Sâm',
						sun => 'Dum'
					},
					short => {
						mon => 'Lu',
						tue => 'Ma',
						wed => 'Mi',
						thu => 'Jo',
						fri => 'Vi',
						sat => 'Sâ',
						sun => 'Du'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'Ma',
						wed => 'Mi',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					abbreviated => {0 => 'trim. 1',
						1 => 'trim. 2',
						2 => 'trim. 3',
						3 => 'trim. 4'
					},
					wide => {0 => 'trimestrul 1',
						1 => 'trimestrul 2',
						2 => 'trimestrul 3',
						3 => 'trimestrul 4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Trim. 1',
						1 => 'Trim. 2',
						2 => 'Trim. 3',
						3 => 'Trim. 4'
					},
					wide => {0 => 'Trimestrul 1',
						1 => 'Trimestrul 2',
						2 => 'Trimestrul 3',
						3 => 'Trimestrul 4'
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
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
					'afternoon1' => q{după-amiază},
					'evening1' => q{seară},
					'midnight' => q{miezul nopții},
					'morning1' => q{dimineață},
					'night1' => q{noapte},
					'noon' => q{amiază},
				},
				'wide' => {
					'afternoon1' => q{după-amiaza},
					'evening1' => q{seara},
					'midnight' => q{miezul nopții},
					'morning1' => q{dimineața},
					'night1' => q{noaptea},
					'noon' => q{amiază},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'afternoon1' => q{după-amiază},
					'evening1' => q{seară},
					'morning1' => q{dimineață},
					'night1' => q{noapte},
				},
				'wide' => {
					'midnight' => q{miezul nopții},
					'noon' => q{amiază},
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
