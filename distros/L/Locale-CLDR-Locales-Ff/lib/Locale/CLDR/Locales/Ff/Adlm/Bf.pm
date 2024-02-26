=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ff::Adlm::Bf - Package for language Fula

=cut

package Locale::CLDR::Locales::Ff::Adlm::Bf;
# This file auto generated from Data\common\main\ff_Adlm_BF.xml
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

extends('Locale::CLDR::Locales::Ff::Adlm');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'GNF' => {
			symbol => 'GNF',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
