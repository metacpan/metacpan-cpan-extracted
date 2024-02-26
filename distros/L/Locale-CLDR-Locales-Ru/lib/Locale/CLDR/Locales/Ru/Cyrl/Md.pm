=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ru::Cyrl::Md - Package for language Russian

=cut

package Locale::CLDR::Locales::Ru::Cyrl::Md;
# This file auto generated from Data\common\main\ru_MD.xml
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

extends('Locale::CLDR::Locales::Ru::Cyrl');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'MDL' => {
			symbol => 'L',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
