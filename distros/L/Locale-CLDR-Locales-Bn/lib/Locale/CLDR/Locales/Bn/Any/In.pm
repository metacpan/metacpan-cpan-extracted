=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bn::Any::In - Package for language Bangla

=cut

package Locale::CLDR::Locales::Bn::Any::In;
# This file auto generated from Data\common\main\bn_IN.xml
#	on Sat  4 Nov  5:54:29 pm GMT

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

extends('Locale::CLDR::Locales::Bn::Any');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ksh' => 'কোলোনিয়ান',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'CD@alt=variant' => 'কঙ্গো (DRC)',
 			'UM' => 'মার্কিন যুক্তরাষ্ট্রের পার্শ্ববর্তী দ্বীপপুঞ্জ',

		}
	},
);

no Moo;

1;

# vim: tabstop=4
