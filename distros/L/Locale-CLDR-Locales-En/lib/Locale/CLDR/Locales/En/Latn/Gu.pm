=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Latn::Gu - Package for language English

=cut

package Locale::CLDR::Locales::En::Latn::Gu;
# This file auto generated from Data\common\main\en_GU.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Latn');
has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Chamorro' => {
			short => {
				'standard' => q#ChST#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
