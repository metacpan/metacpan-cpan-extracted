=encoding utf8

=head1

Locale::CLDR::Locales::En::Any::Gh - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Gh;
# This file auto generated from Data\common\main\en_GH.xml
#	on Sun  7 Oct 10:29:15 am GMT

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

extends('Locale::CLDR::Locales::En::Any::001');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'GHS' => {
			symbol => 'GH₵',
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
