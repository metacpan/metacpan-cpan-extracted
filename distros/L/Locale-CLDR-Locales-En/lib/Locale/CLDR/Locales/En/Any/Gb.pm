=head1

Locale::CLDR::Locales::En::Any::Gb - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Gb;
# This file auto generated from Data\common\main\en_GB.xml
#	on Fri 13 Apr  7:07:54 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Thai' => 'Thai',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'BL' => 'St Barthélemy',
 			'KN' => 'St Kitts & Nevis',
 			'LC' => 'St Lucia',
 			'MF' => 'St Martin',
 			'PM' => 'St Pierre & Miquelon',
 			'SH' => 'St Helena',
 			'UM' => 'US Outlying Islands',
 			'US@alt=short' => 'US',
 			'VC' => 'St Vincent & Grenadines',
 			'VI' => 'US Virgin Islands',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'colcaselevel' => 'Case-Sensitive Sorting',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'hc' => {
 				'h11' => q{12-Hour System (0–11)},
 				'h12' => q{12-Hour System (1–12)},
 				'h23' => q{24-Hour System (0–23)},
 				'h24' => q{24-Hour System (1–24)},
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
					'kilometer-per-hour' => {
						'one' => q({0} kilometre per hour),
					},
				},
				'narrow' => {
					'hour' => {
						'per' => q({0}/h),
					},
					'second' => {
						'per' => q({0}/s),
					},
				},
				'short' => {
					'megaliter' => {
						'other' => q({0} Ml),
					},
					'stone' => {
						'other' => q({0} st),
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
		'MKD' => {
			display_name => {
				'other' => q(Macedonian denari),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St Helena Pound),
				'one' => q(St Helena pound),
				'other' => q(St Helena pounds),
			},
		},
		'XOF' => {
			display_name => {
				'other' => q(West African CFA francs),
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
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					'noon' => q{noon},
					'pm' => q{pm},
					'am' => q{am},
				},
				'narrow' => {
					'noon' => q{n},
				},
				'abbreviated' => {
					'noon' => q{noon},
					'pm' => q{pm},
					'am' => q{am},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'pm' => q{pm},
				},
				'wide' => {
					'pm' => q{pm},
					'am' => q{am},
				},
				'abbreviated' => {
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
		'islamic' => {
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
		},
		'generic' => {
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E, h.mm B},
			EBhms => q{E, h.mm.ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ehm => q{E, h.mm a},
			Ehms => q{E, h.mm.ss a},
			MEd => q{E, d/M},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
		},
		'gregorian' => {
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E, h.mm B},
			EBhms => q{E, h.mm.ss B},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
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
			M => {
				M => q{M–M},
			},
			MMMd => {
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM–dd/MM},
				d => q{dd/MM–dd/MM},
			},
			d => {
				d => q{d–d},
			},
			y => {
				y => q{y–y G},
			},
			yMMMd => {
				d => q{d–d MMM y G},
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
			M => {
				M => q{M–M},
			},
			MMMd => {
				d => q{d–d MMM},
			},
			d => {
				d => q{d–d},
			},
			h => {
				h => q{h–h a},
			},
			hv => {
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yMMMd => {
				d => q{d–d MMM y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'America/St_Barthelemy' => {
			exemplarCity => q#St Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St Vincent#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St Helena#,
		},
		'Australia_Central' => {
			long => {
				'generic' => q#Central Australia Time#,
				'standard' => q#Australian Central Standard Time#,
			},
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
		'Kyrgystan' => {
			long => {
				'standard' => q#Kyrgystan Time#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Bator Summer Time#,
				'generic' => q#Ulan Bator Time#,
				'standard' => q#Ulan Bator Standard Time#,
			},
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St Pierre & Miquelon Daylight Time#,
				'generic' => q#St Pierre & Miquelon Time#,
				'standard' => q#St Pierre & Miquelon Standard Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
