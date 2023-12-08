=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sr::Cyrl::Xk - Package for language Serbian

=cut

package Locale::CLDR::Locales::Sr::Cyrl::Xk;
# This file auto generated from Data\common\main\sr_Cyrl_XK.xml
#	on Tue  5 Dec  1:32:22 pm GMT

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

extends('Locale::CLDR::Locales::Sr::Cyrl');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'bm' => 'бамананкан',
 				'bn' => 'бангла',
 				'ff' => 'фулах',
 				'gsw' => 'швајцарски немачки',
 				'ht' => 'хаићански креолски',
 				'lo' => 'лаошки',
 				'moh' => 'мохок',
 				'nqo' => 'н’ко',
 				'shi' => 'јужни шилха',
 				'si' => 'синхалски',
 				'tzm' => 'централноатласки тамашек',
 				'xh' => 'исикоса',
 				'zgh' => 'стандардни марокански тамашек',
 				'zu' => 'исизулу',

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
			'CG' => 'Конго',
 			'CV' => 'Кабо Верде',
 			'CZ' => 'Чешка Република',
 			'HK' => 'САР Хонгконг',
 			'KN' => 'Свети Китс и Невис',
 			'MK@alt=variant' => 'БЈР Македонија',
 			'MO' => 'САР Макао',
 			'PM' => 'Свети Пјер и Микелон',
 			'RE' => 'Реунион',
 			'UM' => 'Мања удаљена острва САД',
 			'VC' => 'Свети Винсент и Гренадини',

		}
	},
);

has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'јан.',
							'феб.',
							'март',
							'апр.',
							'мај',
							'јун',
							'јул',
							'авг.',
							'септ.',
							'окт.',
							'нов.',
							'дец.'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'јан.',
							'феб.',
							'март',
							'апр.',
							'мај',
							'јун',
							'јул',
							'авг.',
							'септ.',
							'окт.',
							'нов.',
							'дец.'
						],
						leap => [
							
						],
					},
				},
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
						mon => 'пон.',
						tue => 'ут.',
						wed => 'ср.',
						thu => 'чет.',
						fri => 'пет.',
						sat => 'суб.',
						sun => 'нед.'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'пон.',
						tue => 'ут.',
						wed => 'ср.',
						thu => 'чет.',
						fri => 'пет.',
						sat => 'суб.',
						sun => 'нед.'
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

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'afternoon1' => q{по под.},
					'evening1' => q{увече},
					'midnight' => q{поноћ},
					'morning1' => q{јутро},
					'night1' => q{ноћу},
					'noon' => q{подне},
				},
				'narrow' => {
					'afternoon1' => q{по под.},
					'evening1' => q{вече},
					'midnight' => q{поноћ},
					'morning1' => q{јутро},
					'night1' => q{ноћ},
					'noon' => q{подне},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
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
		},
		'gregorian' => {
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
		'generic' => {
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d – E, d. MMM},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
