=encoding utf8

=head1 NAME

Locale::CLDR::Locales::De::Any::It - Package for language German

=cut

package Locale::CLDR::Locales::De::Any::It;
# This file auto generated from Data\common\main\de_IT.xml
#	on Fri 13 Oct  9:11:53 am GMT

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

extends('Locale::CLDR::Locales::De::Any');
has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Jän.',
							'Feb.',
							'März',
							'Apr.',
							'Mai',
							'Juni',
							'Juli',
							'Aug.',
							'Sep.',
							'Okt.',
							'Nov.',
							'Dez.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jänner',
							'Februar',
							'März',
							'April',
							'Mai',
							'Juni',
							'Juli',
							'August',
							'September',
							'Oktober',
							'November',
							'Dezember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jän',
							'Feb',
							'Mär',
							'Apr',
							'Mai',
							'Jun',
							'Jul',
							'Aug',
							'Sep',
							'Okt',
							'Nov',
							'Dez'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jänner',
							'Februar',
							'März',
							'April',
							'Mai',
							'Juni',
							'Juli',
							'August',
							'September',
							'Oktober',
							'November',
							'Dezember'
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
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
