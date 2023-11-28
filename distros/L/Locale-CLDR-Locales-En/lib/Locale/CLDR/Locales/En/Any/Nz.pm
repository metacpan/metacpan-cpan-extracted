=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Any::Nz - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Nz;
# This file auto generated from Data\common\main\en_NZ.xml
#	on Sat  4 Nov  6:00:00 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

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
				'mi' => 'Māori',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'NZD' => {
			symbol => '$',
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
			'short' => q{d/MM/y GGGGG},
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
		'generic' => {
			Md => q{d/M},
			yyyyMd => q{d/MM/y G},
		},
		'gregorian' => {
			Md => q{d/M},
			yMd => q{d/MM/y},
			yw => q{'week' w 'of' Y},
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
				M => q{E, d/MM – E, d/MM},
				d => q{E, d/MM – E, d/MM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			Md => {
				M => q{d/MM – d/MM},
				d => q{d/MM – d/MM},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E, d/MM/y – E, d/MM/y G},
				d => q{E, d/MM/y – E, d/MM/y G},
				y => q{E, d/MM/y – E, d/MM/y G},
			},
			yMd => {
				M => q{d/MM/y – d/MM/y G},
				d => q{d/MM/y – d/MM/y G},
				y => q{d/MM/y – d/MM/y G},
			},
		},
		'gregorian' => {
			MEd => {
				M => q{E, d/MM – E, d/MM},
				d => q{E, d/MM – E, d/MM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			Md => {
				M => q{d/MM – d/MM},
				d => q{d/MM – d/MM},
			},
			yMEd => {
				M => q{E, d/MM/y – E, d/MM/y},
				d => q{E, d/MM/y – E, d/MM/y},
				y => q{E, d/MM/y – E, d/MM/y},
			},
			yMd => {
				M => q{d/MM/y – d/MM/y},
				d => q{d/MM/y – d/MM/y},
				y => q{d/MM/y – d/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Australia_Central' => {
			short => {
				'daylight' => q#ACDT#,
				'generic' => q#ACT#,
				'standard' => q#ACST#,
			},
		},
		'Australia_CentralWestern' => {
			short => {
				'daylight' => q#ACWDT#,
				'generic' => q#ACWT#,
				'standard' => q#ACWST#,
			},
		},
		'Australia_Eastern' => {
			short => {
				'daylight' => q#AEDT#,
				'generic' => q#AET#,
				'standard' => q#AEST#,
			},
		},
		'Australia_Western' => {
			short => {
				'daylight' => q#AWDT#,
				'generic' => q#AWT#,
				'standard' => q#AWST#,
			},
		},
		'Chatham' => {
			short => {
				'daylight' => q#CHADT#,
				'generic' => q#CHAT#,
				'standard' => q#CHAST#,
			},
		},
		'Lord_Howe' => {
			short => {
				'daylight' => q#LHDT#,
				'generic' => q#LHT#,
				'standard' => q#LHST#,
			},
		},
		'New_Zealand' => {
			short => {
				'daylight' => q#NZDT#,
				'generic' => q#NZT#,
				'standard' => q#NZST#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
