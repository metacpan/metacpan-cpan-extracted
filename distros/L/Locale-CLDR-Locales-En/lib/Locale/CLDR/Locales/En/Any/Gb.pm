=head1

Locale::CLDR::Locales::En::Any::Gb - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Gb;
# This file auto generated from Data\common\main\en_GB.xml
#	on Fri 29 Apr  6:59:44 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Any::001');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'nds_NL' => 'West Low German',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'colnormalization' => 'Normalised Sorting',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'colnormalization' => {
 				'no' => q{Sort Without Normalisation},
 				'yes' => q{Sort Unicode Normalised},
 			},

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
				},
				'short' => {
					'hour' => {
						'per' => q({0}ph),
					},
					'second' => {
						'per' => q({0}ps),
					},
					'stone' => {
						'name' => q(stone),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} and {1}),
		} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ILR' => {
			display_name => {
				'currency' => q(Israeli Shekel \(1980–1985\)),
				'one' => q(Israeli shekel \(1980–1985\)),
				'other' => q(Israeli shekels \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Israeli New Shekel),
				'one' => q(Israeli new shekel),
				'other' => q(Israeli new shekels),
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

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'wide' => {
					'pm' => q{pm},
					'am' => q{am},
				},
				'abbreviated' => {
					'am' => q{am},
					'pm' => q{pm},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
				},
				'wide' => {
					'am' => q{am},
					'pm' => q{pm},
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
		'Europe/London' => {
			short => {
				'daylight' => q(BST),
			},
		},
		'Europe_Central' => {
			short => {
				'daylight' => q(CEST),
				'generic' => q(CET),
				'standard' => q(CET),
			},
		},
		'Europe_Eastern' => {
			short => {
				'daylight' => q(EEST),
				'generic' => q(EET),
				'standard' => q(EET),
			},
		},
		'Europe_Western' => {
			short => {
				'daylight' => q(WEST),
				'generic' => q(WET),
				'standard' => q(WET),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
