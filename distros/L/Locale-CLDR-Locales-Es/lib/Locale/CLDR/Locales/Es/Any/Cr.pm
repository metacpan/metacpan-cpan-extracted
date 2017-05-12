=head1

Locale::CLDR::Locales::Es::Any::Cr - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Cr;
# This file auto generated from Data\common\main\es_CR.xml
#	on Fri 29 Apr  7:00:41 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Es::Any::419');
has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'CRC' => {
			symbol => '₡',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
