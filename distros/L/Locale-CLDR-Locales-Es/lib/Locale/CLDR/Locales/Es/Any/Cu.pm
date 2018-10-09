=encoding utf8

=head1

Locale::CLDR::Locales::Es::Any::Cu - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Cu;
# This file auto generated from Data\common\main\es_CU.xml
#	on Sun  7 Oct 10:30:07 am GMT

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

extends('Locale::CLDR::Locales::Es::Any::419');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'CUP' => {
			symbol => '$',
		},
		'USD' => {
			symbol => 'US$',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
