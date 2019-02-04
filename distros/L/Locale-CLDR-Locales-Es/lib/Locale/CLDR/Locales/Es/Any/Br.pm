=encoding utf8

=head1

Locale::CLDR::Locales::Es::Any::Br - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Br;
# This file auto generated from Data\common\main\es_BR.xml
#	on Sun  3 Feb  1:48:58 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
		'BRL' => {
			symbol => 'R$',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
