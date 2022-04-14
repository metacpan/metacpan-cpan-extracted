=encoding utf8

=head1

Locale::CLDR::Locales::Pt::Any::Mz - Package for language Portuguese

=cut

package Locale::CLDR::Locales::Pt::Any::Mz;
# This file auto generated from Data/common/main/pt_MZ.xml
#	on Mon 11 Apr  5:36:40 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Pt::Any::Pt');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'MZN' => {
			symbol => 'MTn',
		},
	} },
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Azores' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Europe_Central' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Europe_Eastern' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Europe_Western' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
