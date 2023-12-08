=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sr::Latn::Me - Package for language Serbian

=cut

package Locale::CLDR::Locales::Sr::Latn::Me;
# This file auto generated from Data\common\main\sr_Latn_ME.xml
#	on Tue  5 Dec  1:32:44 pm GMT

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

extends('Locale::CLDR::Locales::Sr::Latn');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'arn' => 'mapudungun',
 				'be' => 'bjeloruski',
 				'bm' => 'bamanankan',
 				'bn' => 'bangla',
 				'ff' => 'fulah',
 				'ht' => 'haićanski kreolski',
 				'lo' => 'laoški',
 				'moh' => 'mohok',
 				'nqo' => 'n’ko',
 				'shi' => 'južni šilha',
 				'tzm' => 'centralnoatlaski tamašek',
 				'xh' => 'isikosa',
 				'zgh' => 'standardni marokanski tamašek',
 				'zu' => 'isizulu',

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
			'BY' => 'Bjelorusija',
 			'CG' => 'Kongo',
 			'CZ' => 'Češka Republika',
 			'DE' => 'Njemačka',
 			'KN' => 'Sveti Kits i Nevis',
 			'MK@alt=variant' => 'BJR Makedonija',
 			'PM' => 'Sveti Pjer i Mikelon',
 			'RE' => 'Reunion',
 			'UM' => 'Manja udaljena ostrva SAD',
 			'VC' => 'Sveti Vinsent i Grenadini',
 			'VG' => 'Britanska Djevičanska Ostrva',
 			'VI' => 'Američka Djevičanska Ostrva',

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
							'jan.',
							'feb.',
							'mart',
							'apr.',
							'maj',
							'jun',
							'jul',
							'avg.',
							'sept.',
							'okt.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan.',
							'feb.',
							'mart',
							'apr.',
							'maj',
							'jun',
							'jul',
							'avg.',
							'sept.',
							'okt.',
							'nov.',
							'dec.'
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
						mon => 'pon.',
						tue => 'ut.',
						wed => 'sr.',
						thu => 'čet.',
						fri => 'pet.',
						sat => 'sub.',
						sun => 'ned.'
					},
					wide => {
						mon => 'ponedeljak',
						tue => 'utorak',
						wed => 'srijeda',
						thu => 'četvrtak',
						fri => 'petak',
						sat => 'subota',
						sun => 'nedjelja'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'pon.',
						tue => 'ut.',
						wed => 'sr.',
						thu => 'čet.',
						fri => 'pet.',
						sat => 'sub.',
						sun => 'ned.'
					},
					wide => {
						mon => 'ponedeljak',
						tue => 'utorak',
						wed => 'srijeda',
						thu => 'četvrtak',
						fri => 'petak',
						sat => 'subota',
						sun => 'nedjelja'
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
					'afternoon1' => q{po pod.},
					'am' => q{prije podne},
					'evening1' => q{veče},
					'midnight' => q{ponoć},
					'morning1' => q{jutro},
					'night1' => q{noću},
					'noon' => q{podne},
					'pm' => q{po podne},
				},
				'narrow' => {
					'afternoon1' => q{po pod.},
					'evening1' => q{veče},
					'midnight' => q{ponoć},
					'morning1' => q{jutro},
					'night1' => q{noć},
					'noon' => q{podne},
				},
				'wide' => {
					'am' => q{prije podne},
					'pm' => q{po podne},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{prije podne},
					'pm' => q{po podne},
				},
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
				},
				'wide' => {
					'am' => q{prije podne},
					'pm' => q{po podne},
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
				'0' => 'prije nove ere'
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
			MMMMW => q{W. 'sjedmica' 'u' MMM},
			yw => q{w. 'sjedmica' 'u' Y.},
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
