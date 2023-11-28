=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ar::Any::Td - Package for language Arabic

=cut

package Locale::CLDR::Locales::Ar::Any::Td;
# This file auto generated from Data\common\main\ar_TD.xml
#	on Sat  4 Nov  5:52:29 pm GMT

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

extends('Locale::CLDR::Locales::Ar::Any');
has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arab',
);

no Moo;

1;

# vim: tabstop=4
