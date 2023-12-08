=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Any::Mo - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Mo;
# This file auto generated from Data\common\main\en_MO.xml
#	on Tue  5 Dec  1:08:02 pm GMT

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

extends('Locale::CLDR::Locales::En::Any::001');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'MOP' => {
			symbol => 'MOP$',
		},
	} },
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Hong_Kong' => {
			short => {
				'daylight' => q#HKST#,
				'generic' => q#HKT#,
				'standard' => q#HKT#,
			},
		},
		'Macau' => {
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MST#,
				'standard' => q#MST#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
