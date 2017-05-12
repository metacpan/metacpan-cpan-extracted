=head1

Locale::CLDR::Locales::Es::Any::Hn - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Hn;
# This file auto generated from Data\common\main\es_HN.xml
#	on Fri 29 Apr  7:00:44 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Es::Any::419');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'HNL' => {
			symbol => 'L',
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
			if ($_ eq 'generic') {
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
			'full' => q{EEEE dd 'de' MMMM 'de' y G},
			'long' => q{dd 'de' MMMM 'de' y G},
		},
		'gregorian' => {
			'full' => q{EEEE dd 'de' MMMM 'de' y},
			'long' => q{dd 'de' MMMM 'de' y},
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
		'gregorian' => {
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
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E dd 'de' MMM 'al' E dd 'de' MMM},
				d => q{E dd 'al' E dd 'de' MMM},
			},
			MMMd => {
				M => q{dd 'de' MMM 'al' dd 'de' MMM},
				d => q{dd–dd 'de' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			fallback => '{0} a el {1}',
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E dd 'de' MMM 'al' E dd 'de' MMM 'de' y},
				d => q{E dd 'al' E dd 'de' MMM 'de' y},
				y => q{E dd 'de' MMM 'de' y 'al' E dd 'de' MMM 'de' y},
			},
			yMMMd => {
				M => q{dd 'de' MMM 'al' dd 'de' MMM 'de' y},
				d => q{dd–dd 'de' MMM 'de' y},
				y => q{dd 'de' MMM 'de' y 'al' dd 'de' MMM 'de' y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'generic' => {
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E dd 'de' MMM 'al' E dd 'de' MMM},
				d => q{E dd 'al' E dd 'de' MMM},
			},
			MMMd => {
				M => q{dd 'de' MMM 'al' dd 'de' MMM},
				d => q{dd–dd 'de' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			fallback => '{0} a el {1}',
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y},
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E dd 'de' MMM 'al' E dd 'de' MMM 'de' y},
				d => q{E dd 'al' E dd 'de' MMM 'de' y},
				y => q{E dd 'de' MMM 'de' y 'al' E dd 'de' MMM 'de' y},
			},
			yMMMd => {
				M => q{dd 'de' MMM 'al' dd 'de' MMM 'de' y},
				d => q{dd–dd 'de' MMM 'de' y},
				y => q{dd 'de' MMM 'de' y 'al' dd 'de' MMM 'de' y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
