=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Zh::Hant::Mo - Package for language Chinese

=cut

package Locale::CLDR::Locales::Zh::Hant::Mo;
# This file auto generated from Data\common\main\zh_Hant_MO.xml
#	on Sat  4 Nov  6:34:10 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Zh::Hant::Hk');
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


no Moo;

1;

# vim: tabstop=4
