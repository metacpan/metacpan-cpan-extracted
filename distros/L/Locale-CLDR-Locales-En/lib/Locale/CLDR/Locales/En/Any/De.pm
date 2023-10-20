=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Any::De - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::De;
# This file auto generated from Data\common\main\en_DE.xml
#	on Fri 13 Oct  9:13:16 am GMT

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

extends('Locale::CLDR::Locales::En::Any::150');
has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'superscriptingExponent' => q(·),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
				},
			},
		},
} },
);

no Moo;

1;

# vim: tabstop=4
