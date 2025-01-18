=encoding utf8

=head1 NAME

Locale::CLDR::Locales::So::Latn::Et - Package for language Somali

=cut

package Locale::CLDR::Locales::So::Latn::Et;
# This file auto generated from Data\common\main\so_ET.xml
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

extends('Locale::CLDR::Locales::So::Latn');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ETB' => {
			symbol => 'Br',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
