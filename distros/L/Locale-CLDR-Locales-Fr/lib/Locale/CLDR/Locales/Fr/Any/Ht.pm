=head1

Locale::CLDR::Locales::Fr::Any::Ht - Package for language French

=cut

package Locale::CLDR::Locales::Fr::Any::Ht;
# This file auto generated from Data\common\main\fr_HT.xml
#	on Fri 29 Apr  7:04:13 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Fr::Any');
has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'cubic-centimeter' => {
						'per' => q({0} pour chaque centimetre cube),
					},
					'cubic-meter' => {
						'per' => q({0} pour chaque metre cube),
					},
					'hectare' => {
						'name' => q(carreau),
						'one' => q({0}carreau),
						'other' => q({0}carreaux),
					},
				},
				'narrow' => {
					'gram' => {
						'name' => q(gr.),
					},
				},
				'short' => {
					'carat' => {
						'name' => q(kr),
						'one' => q({0}kr),
						'other' => q({0}kr),
					},
					'century' => {
						'name' => q(sec),
					},
					'gram' => {
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'HTG' => {
			symbol => 'G',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
