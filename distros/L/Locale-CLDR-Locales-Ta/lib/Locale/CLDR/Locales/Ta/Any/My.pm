=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ta::Any::My - Package for language Tamil

=cut

package Locale::CLDR::Locales::Ta::Any::My;
# This file auto generated from Data\common\main\ta_MY.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ta::Any');
has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'MYR' => {
			symbol => 'RM',
		},
		'SGD' => {
			symbol => 'S$',
		},
	} },
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'India' => {
			short => {
				'standard' => q#∅∅∅#,
			},
		},
		'Malaysia' => {
			short => {
				'standard' => q#MYT#,
			},
		},
		'Singapore' => {
			short => {
				'standard' => q#SGT#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
