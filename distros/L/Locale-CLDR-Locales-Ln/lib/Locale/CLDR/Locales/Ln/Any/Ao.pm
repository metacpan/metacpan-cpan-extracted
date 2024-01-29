=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ln::Any::Ao - Package for language Lingala

=cut

package Locale::CLDR::Locales::Ln::Any::Ao;
# This file auto generated from Data\common\main\ln_AO.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ln::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AOA' => {
			symbol => 'Kz',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
