=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Os::Cyrl::Ru - Package for language Ossetic

=cut

package Locale::CLDR::Locales::Os::Cyrl::Ru;
# This file auto generated from Data\common\main\os_RU.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Os::Cyrl');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'GEL' => {
			symbol => 'GEL',
		},
		'RUB' => {
			symbol => '₽',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
