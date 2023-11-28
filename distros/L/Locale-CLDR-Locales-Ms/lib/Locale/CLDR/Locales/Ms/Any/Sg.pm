=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ms::Any::Sg - Package for language Malay

=cut

package Locale::CLDR::Locales::Ms::Any::Sg;
# This file auto generated from Data\common\main\ms_SG.xml
#	on Sat  4 Nov  6:14:32 pm GMT

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

extends('Locale::CLDR::Locales::Ms::Any');
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
