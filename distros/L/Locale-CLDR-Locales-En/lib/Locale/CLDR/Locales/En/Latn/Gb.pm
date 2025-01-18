=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Latn::Gb - Package for language English

=cut

package Locale::CLDR::Locales::En::Latn::Gb;
# This file auto generated from Data\common\main\en_GB.xml
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

extends('Locale::CLDR::Locales::En::Latn::001');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ff' => 'Fulah',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
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
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
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
		'islamic' => {
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
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
		},
		'islamic' => {
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
		'islamic' => {
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			GyMMMEEEEd => q{EEEE, d MMM y G},
			MEd => q{E dd/MM},
			MMMEEEEd => q{EEEE d MMM},
			MMMEd => q{E d MMM},
			MMMMEEEEd => q{EEEE d MMMM},
			yyyyMMMEEEEd => q{EEEE, d MMM y G},
			yyyyMMMMEEEEd => q{EEEE, d MMMM y G},
		},
		'gregorian' => {
			GyMMMEEEEd => q{EEEE, d MMM y G},
			GyMd => q{dd/MM/y G},
			MEd => q{E dd/MM},
			MMMEEEEd => q{EEEE d MMM},
			MMMEd => q{E d MMM},
			MMMMEEEEd => q{EEEE d MMMM},
			yMMMEEEEd => q{EEEE, d MMM y},
			yMMMMEEEEd => q{EEEE, d MMMM y},
		},
		'islamic' => {
			Ed => q{E d},
			GyMMMEEEEd => q{EEEE, d MMM y G},
			M => q{LL},
			yyyyM => q{MM/y GGGGG},
			yyyyMMMEEEEd => q{EEEE, d MMM y G},
			yyyyMMMMEEEEd => q{EEEE, d MMMM y G},
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
			GyMMMEEEEd => {
				G => q{EEEE d MMM y G – EEEE d MMM y G},
				M => q{EEEE d MMM – EEEE d MMM y G},
				d => q{EEEE d MMM – EEEE d MMM y G},
				y => q{EEEE d MMM y – EEEE d MMM y G},
			},
			MMMEd => {
				d => q{E d MMM – E d MMM},
			},
			yMMMEEEEd => {
				M => q{EEEE d MMM – EEEE d MMM y G},
				d => q{EEEE d MMM – EEEE d MMM y G},
				y => q{EEEE d MMM y – EEEE d MMM y G},
			},
			yMMMEd => {
				d => q{E, d MMM – E, d MMM y G},
			},
			yMMMMEEEEd => {
				M => q{EEEE d MMMM – EEEE d MMMM y G},
				d => q{EEEE d MMMM – EEEE d MMMM y G},
				y => q{EEEE d MMMM y – EEEE d MMMM y G},
			},
		},
		'gregorian' => {
			GyMMMEEEEd => {
				G => q{EEEE d MMM y G – EEEE d MMM y G},
				M => q{EEEE d MMM – EEEE d MMM y G},
				d => q{EEEE d MMM – EEEE d MMM y G},
				y => q{EEEE d MMM y – EEEE d MMM y G},
			},
			MMMEd => {
				d => q{E d MMM – E d MMM},
			},
			yMMMEEEEd => {
				M => q{EEEE d MMM – EEEE d MMM y},
				d => q{EEEE d MMM – EEEE d MMM y},
				y => q{EEEE d MMM y – EEEE d MMM y},
			},
			yMMMEd => {
				d => q{E, d MMM – E, d MMM y},
			},
			yMMMMEEEEd => {
				M => q{EEEE d MMMM – EEEE d MMMM y},
				d => q{EEEE d MMMM – EEEE d MMMM y},
				y => q{EEEE d MMMM y – EEEE d MMMM y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'Europe/London' => {
			short => {
				'daylight' => q#BST#,
			},
		},
		'Europe_Central' => {
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Western' => {
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Gulf' => {
			short => {
				'standard' => q#GST#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
