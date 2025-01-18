=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ar::Arab::Dj - Package for language Arabic

=cut

package Locale::CLDR::Locales::Ar::Arab::Dj;
# This file auto generated from Data\common\main\ar_DJ.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ar::Arab');
has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arab',
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'DJF' => {
			symbol => 'Fdj',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
