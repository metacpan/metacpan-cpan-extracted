=head1

Locale::CLDR::Locales::Qu::Any::Ec - Package for language Quechua

=cut

package Locale::CLDR::Locales::Qu::Any::Ec;
# This file auto generated from Data\common\main\qu_EC.xml
#	on Fri 13 Apr  7:26:08 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Qu::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'PEN' => {
			symbol => 'PEN',
		},
		'USD' => {
			symbol => '$',
		},
	} },
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Ecuador' => {
			short => {
				'standard' => q#ECT#,
			},
		},
		'Peru' => {
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
