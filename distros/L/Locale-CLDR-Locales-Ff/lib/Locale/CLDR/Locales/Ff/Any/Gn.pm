=encoding utf8

=head1

Locale::CLDR::Locales::Ff::Any::Gn - Package for language Fulah

=cut

package Locale::CLDR::Locales::Ff::Any::Gn;
# This file auto generated from Data\common\main\ff_GN.xml
#	on Sun  7 Oct 10:31:30 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ff::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'GNF' => {
			symbol => 'FG',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
