=encoding utf8

=head1

Locale::CLDR::Locales::Sr::Cyrl::Me - Package for language Serbian

=cut

package Locale::CLDR::Locales::Sr::Cyrl::Me;
# This file auto generated from Data\common\main\sr_Cyrl_ME.xml
#	on Sun  7 Oct 10:59:37 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
				'arn' => 'мапудунгун',
 				'be' => 'бјелоруски',
 				'bm' => 'бамананкан',
 				'bn' => 'бангла',
 				'ff' => 'фулах',
 				'ht' => 'хаићански креолски',
 				'lo' => 'лаошки',
 				'moh' => 'мохок',
 				'nqo' => 'н’ко',
 				'shi' => 'јужни шилха',
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
			'BY' => 'Бјелорусија',
 			'CG' => 'Конго',
 			'CZ' => 'Чешка Република',
 			'DE' => 'Њемачка',
 			'KN' => 'Свети Китс и Невис',
 			'MK@alt=variant' => 'БЈР Македонија',
 			'PM' => 'Свети Пјер и Микелон',
 			'RE' => 'Реунион',
 			'UM' => 'Мања удаљена острва САД',
 			'VC' => 'Свети Винсент и Гренадини',
 			'VG' => 'Британска Дјевичанска Острва',
 			'VI' => 'Америчка Дјевичанска Острва',

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
					wide => {
						mon => 'понедељак',
						tue => 'уторак',
						wed => 'сриједа',
						thu => 'четвртак',
						fri => 'петак',
						sat => 'субота',
						sun => 'недјеља'
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
					wide => {
						mon => 'понедељак',
						tue => 'уторак',
						wed => 'сриједа',
						thu => 'четвртак',
						fri => 'петак',
						sat => 'субота',
						sun => 'недјеља'
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
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
				'narrow' => {
					'afternoon1' => q{по под.},
					'evening1' => q{вече},
					'midnight' => q{поноћ},
					'night1' => q{ноћ},
					'morning1' => q{јутро},
					'noon' => q{подне},
				},
				'wide' => {
					'pm' => q{по подне},
					'am' => q{прије подне},
				},
				'abbreviated' => {
					'am' => q{прије подне},
					'evening1' => q{вече},
					'night1' => q{ноћу},
					'morning1' => q{јутро},
					'afternoon1' => q{по под.},
					'midnight' => q{поноћ},
					'pm' => q{по подне},
					'noon' => q{подне},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'pm' => q{по подне},
					'am' => q{прије подне},
				},
				'wide' => {
					'am' => q{прије подне},
					'pm' => q{по подне},
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
		'generic' => {
		},
		'gregorian' => {
			wide => {
				'0' => 'прије нове ере'
			},
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
		'gregorian' => {
			MMMMW => q{W. 'сједмица' 'у' MMM},
			yw => q{w. 'сједмица' 'у' y.},
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
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
