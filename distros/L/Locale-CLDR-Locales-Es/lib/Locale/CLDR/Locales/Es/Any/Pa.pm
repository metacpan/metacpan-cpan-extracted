=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Any::Pa - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Pa;
# This file auto generated from Data\common\main\es_PA.xml
#	on Tue  5 Dec  1:08:43 pm GMT

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

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'PAB' => {
			symbol => 'B/.',
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
					wide => {0 => '1er. trimestre',
						1 => '2do. trimestre',
						2 => '3er. trimestre',
						3 => '4.º trimestre'
					},
				},
				'stand-alone' => {
					wide => {0 => '1er. trimestre',
						1 => '2do. trimestre',
						2 => '3er. trimestre',
						3 => '4.º trimestre'
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
			if ($_ eq 'generic') {
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
					'evening1' => q{de la tarde},
					'morning1' => q{de la madrugada},
					'morning2' => q{de la mañana},
					'night1' => q{de la noche},
					'noon' => q{mediodía},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'evening1' => q{de la tarde},
					'morning1' => q{de la madrugada},
					'morning2' => q{de la mañana},
					'night1' => q{de la noche},
					'noon' => q{mediodía},
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
			'medium' => q{MM/dd/y G},
			'short' => q{MM/dd/yy GGGGG},
		},
		'gregorian' => {
			'medium' => q{MM/dd/y},
			'short' => q{MM/dd/yy},
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
			Md => q{MM/dd},
			yM => q{MM/y},
			yMEd => q{E MM/dd/y},
			yMd => q{MM/dd/y},
		},
		'gregorian' => {
			MEd => q{E, MM/dd},
			Md => q{MM/dd},
			yM => q{MM/y},
			yMEd => q{E MM/dd/y},
			yMMM => q{MMM y},
			yMMMd => q{d MMM y},
			yMd => q{MM/dd/y},
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
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			MMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM},
				d => q{E d 'al' E d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM},
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
			yMMM => {
				M => q{MMM–MMM 'de' y},
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM 'de' y},
				d => q{E d 'al' E d 'de' MMM 'de' y},
				y => q{E d 'de' MMM 'de' y 'al' E d 'de' MMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM 'de' y},
				d => q{d–d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y 'al' d 'de' MMM 'de' y},
			},
		},
		'gregorian' => {
			MMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM},
				d => q{E d 'al' E d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMMM => {
				y => q{MMM 'de' y 'a' MMM 'de' y},
			},
			yMMMEd => {
				M => q{E d 'de' MMM 'al' E d 'de' MMM 'de' y},
				d => q{E d 'al' E d 'de' MMM 'de' y},
				y => q{E d 'de' MMM 'de' y 'al' E d 'de' MMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM 'al' d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y 'al' d 'de' MMM 'de' y},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
