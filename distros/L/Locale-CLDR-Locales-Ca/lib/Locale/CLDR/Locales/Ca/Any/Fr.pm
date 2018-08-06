=head1

Locale::CLDR::Locales::Ca::Any::Fr - Package for language Catalan

=cut

package Locale::CLDR::Locales::Ca::Any::Fr;
# This file auto generated from Data\common\main\ca_FR.xml
#	on Sun  5 Aug  5:54:36 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ca::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'FRF' => {
			symbol => 'F',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
