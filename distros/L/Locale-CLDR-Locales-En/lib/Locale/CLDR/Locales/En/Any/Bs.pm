=head1

Locale::CLDR::Locales::En::Any::Bs - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Bs;
# This file auto generated from Data\common\main\en_BS.xml
#	on Fri 29 Apr  6:59:38 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Any::001');
has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'narrow' => {
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BSD' => {
			symbol => '$',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
