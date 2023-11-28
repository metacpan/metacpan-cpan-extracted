=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Any::Sd - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Sd;
# This file auto generated from Data\common\main\en_SD.xml
#	on Sat  4 Nov  6:00:02 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Any::001');
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
