=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Os::Any::Ru - Package for language Ossetic

=cut

package Locale::CLDR::Locales::Os::Any::Ru;
# This file auto generated from Data\common\main\os_RU.xml
#	on Tue  5 Dec  1:27:03 pm GMT

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

extends('Locale::CLDR::Locales::Os::Any');
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
