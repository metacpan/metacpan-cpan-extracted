=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ms::Latn::Sg - Package for language Malay

=cut

package Locale::CLDR::Locales::Ms::Latn::Sg;
# This file auto generated from Data\common\main\ms_SG.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ms::Latn');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'SGD' => {
			symbol => '$',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
