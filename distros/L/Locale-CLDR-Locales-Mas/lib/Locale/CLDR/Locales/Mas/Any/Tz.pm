=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mas::Any::Tz - Package for language Masai

=cut

package Locale::CLDR::Locales::Mas::Any::Tz;
# This file auto generated from Data\common\main\mas_TZ.xml
#	on Fri 13 Oct  9:26:37 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Mas::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'TZS' => {
			symbol => 'TSh',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
