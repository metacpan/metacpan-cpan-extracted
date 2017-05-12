=head1

Locale::CLDR::Locales::Es::Any::Us - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Us;
# This file auto generated from Data\common\main\es_US.xml
#	on Fri 29 Apr  7:00:52 pm GMT

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
				'narrow' => {
					'fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'JPY' => {
			symbol => '¥',
		},
		'USD' => {
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

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'pm' => q{p},
					'am' => q{a},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
		'Alaska' => {
			short => {
				'daylight' => q(AKDT),
				'generic' => q(AKT),
				'standard' => q(AKST),
			},
		},
		'America_Central' => {
			short => {
				'daylight' => q(CDT),
				'generic' => q(CT),
				'standard' => q(CST),
			},
		},
		'America_Eastern' => {
			short => {
				'daylight' => q(EDT),
				'generic' => q(ET),
				'standard' => q(EST),
			},
		},
		'America_Mountain' => {
			short => {
				'daylight' => q(MDT),
				'generic' => q(MT),
				'standard' => q(MST),
			},
		},
		'America_Pacific' => {
			short => {
				'daylight' => q(PDT),
				'generic' => q(PT),
				'standard' => q(PST),
			},
		},
		'Atlantic' => {
			short => {
				'daylight' => q(ADT),
				'generic' => q(AT),
				'standard' => q(AST),
			},
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q(HADT),
				'generic' => q(HAT),
				'standard' => q(HAST),
			},
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q(HDT),
				'generic' => q(HST),
				'standard' => q(HST),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
