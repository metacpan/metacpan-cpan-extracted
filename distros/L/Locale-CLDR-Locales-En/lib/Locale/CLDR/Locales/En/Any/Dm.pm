=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Any::Dm - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Dm;
# This file auto generated from Data\common\main\en_DM.xml
#	on Sat  4 Nov  5:59:50 pm GMT

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

extends('Locale::CLDR::Locales::En::Any::001');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'XCD' => {
			symbol => '$',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
