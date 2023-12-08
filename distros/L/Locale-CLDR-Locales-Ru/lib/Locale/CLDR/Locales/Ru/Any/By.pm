=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ru::Any::By - Package for language Russian

=cut

package Locale::CLDR::Locales::Ru::Any::By;
# This file auto generated from Data\common\main\ru_BY.xml
#	on Tue  5 Dec  1:29:56 pm GMT

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

extends('Locale::CLDR::Locales::Ru::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BYN' => {
			symbol => 'Br',
		},
		'RUR' => {
			symbol => 'RUR',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
