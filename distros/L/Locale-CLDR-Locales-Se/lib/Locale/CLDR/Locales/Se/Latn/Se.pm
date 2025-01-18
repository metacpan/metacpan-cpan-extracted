=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Se::Latn::Se - Package for language Northern Sami

=cut

package Locale::CLDR::Locales::Se::Latn::Se;
# This file auto generated from Data\common\main\se_SE.xml
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

extends('Locale::CLDR::Locales::Se::Latn');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'NOK' => {
			symbol => 'Nkr',
		},
		'SEK' => {
			symbol => 'kr',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
