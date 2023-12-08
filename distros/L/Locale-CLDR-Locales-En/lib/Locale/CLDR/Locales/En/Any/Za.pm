=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Any::Za - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Za;
# This file auto generated from Data\common\main\en_ZA.xml
#	on Tue  5 Dec  1:08:10 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Any::001');
has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[á à ă â å ä ā æ ç ḓ é è ĕ ê ë ē í ì ĭ î ï ī ḽ ñ ṅ ṋ ó ò ŏ ô ö ø ō œ š ṱ ú ù ŭ û ü ū ÿ]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ZAR' => {
			symbol => 'R',
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
			'full' => q{EEEE, dd MMMM y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{GGGGG y/MM/dd},
		},
		'gregorian' => {
			'full' => q{EEEE, dd MMMM y},
			'long' => q{dd MMMM y},
			'medium' => q{dd MMM y},
			'short' => q{y/MM/dd},
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
			MEd => q{E, MM/dd},
			MMMEd => q{E, dd MMM},
			MMMd => q{dd MMM},
			Md => q{MM/dd},
			yyyyMEd => q{E, G y/MM/dd},
			yyyyMMMEd => q{E, dd MMM y G},
			yyyyMMMd => q{dd MMM y G},
			yyyyMd => q{G y/MM/dd},
		},
		'gregorian' => {
			MEd => q{E, MM/dd},
			MMMEd => q{E, dd MMM},
			MMMd => q{dd MMM},
			Md => q{MM/dd},
			yMEd => q{E, y/MM/dd},
			yMMMEd => q{E, dd MMM y},
			yMMMd => q{dd MMM y},
			yMd => q{y/MM/dd},
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
				M => q{E MM/dd – E MM/dd},
				d => q{E MM/dd – E MM/dd},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd – dd MMM},
			},
			Md => {
				M => q{MM/dd – MM/dd},
				d => q{MM/dd – MM/dd},
			},
			y => {
				y => q{G y – y},
			},
			yM => {
				M => q{G y/MM – y/MM},
				y => q{G y/MM – y/MM},
			},
			yMEd => {
				M => q{E y/MM/dd – E y/MM/dd},
				d => q{E y/MM/dd – E y/MM/dd},
				y => q{E y/MM/dd – E y/MM/dd},
			},
			yMMMEd => {
				M => q{E, dd MMM – E, dd MMM y G},
				d => q{E, dd – E, dd MMM y G},
				y => q{E, dd MMM y – E, dd MMM y G},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y G},
				d => q{dd – dd MMM y G},
				y => q{dd MMM y – dd MMM y G},
			},
			yMd => {
				M => q{G y/MM/dd – y/MM/dd},
				d => q{G y/MM/dd – y/MM/dd},
				y => q{G y/MM/dd – y/MM/dd},
			},
		},
		'gregorian' => {
			MEd => {
				M => q{E MM/dd – E MM/dd},
				d => q{E MM/dd – E MM/dd},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd – dd MMM},
			},
			Md => {
				M => q{MM/dd – MM/dd},
				d => q{MM/dd – MM/dd},
			},
			yM => {
				M => q{y/MM – y/MM},
				y => q{y/MM – y/MM},
			},
			yMEd => {
				M => q{E y/MM/dd – E y/MM/dd},
				d => q{E y/MM/dd – E y/MM/dd},
				y => q{E y/MM/dd – E y/MM/dd},
			},
			yMMMEd => {
				M => q{E, dd MMM – E, dd MMM y},
				d => q{E, dd – E, dd MMM y},
				y => q{E, dd MMM y – E, dd MMM y},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd – dd MMM y},
				y => q{dd MMM y – dd MMM y},
			},
			yMd => {
				M => q{y/MM/dd – y/MM/dd},
				d => q{y/MM/dd – y/MM/dd},
				y => q{y/MM/dd – y/MM/dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Africa_Central' => {
			short => {
				'standard' => q#CAT#,
			},
		},
		'Africa_Eastern' => {
			short => {
				'standard' => q#EAT#,
			},
		},
		'Africa_Southern' => {
			short => {
				'standard' => q#SAST#,
			},
		},
		'Africa_Western' => {
			short => {
				'daylight' => q#WAST#,
				'generic' => q#WAT#,
				'standard' => q#WAT#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
