=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ar::Any::Tn - Package for language Arabic

=cut

package Locale::CLDR::Locales::Ar::Any::Tn;
# This file auto generated from Data\common\main\ar_TN.xml
#	on Fri 13 Oct  9:05:31 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ar::Any');
has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			numbers => qr{[‎ \- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
		},
	} }
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
							'جانفي',
							'فيفري',
							'مارس',
							'أفريل',
							'ماي',
							'جوان',
							'جويلية',
							'أوت',
							'سبتمبر',
							'أكتوبر',
							'نوفمبر',
							'ديسمبر'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ج',
							'ف',
							'م',
							'أ',
							'م',
							'ج',
							'ج',
							'أ',
							'س',
							'أ',
							'ن',
							'د'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جانفي',
							'فيفري',
							'مارس',
							'أفريل',
							'ماي',
							'جوان',
							'جويلية',
							'أوت',
							'سبتمبر',
							'أكتوبر',
							'نوفمبر',
							'ديسمبر'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'جانفي',
							'فيفري',
							'مارس',
							'أفريل',
							'ماي',
							'جوان',
							'جويلية',
							'أوت',
							'سبتمبر',
							'أكتوبر',
							'نوفمبر',
							'ديسمبر'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ج',
							'ف',
							'م',
							'أ',
							'م',
							'ج',
							'ج',
							'أ',
							'س',
							'أ',
							'ن',
							'د'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جانفي',
							'فيفري',
							'مارس',
							'أفريل',
							'ماي',
							'جوان',
							'جويلية',
							'أوت',
							'سبتمبر',
							'أكتوبر',
							'نوفمبر',
							'ديسمبر'
						],
						leap => [
							
						],
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
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
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

no Moo;

1;

# vim: tabstop=4
