=head1

Locale::CLDR::Locales::Ar::Any::Ss - Package for language Arabic

=cut

package Locale::CLDR::Locales::Ar::Any::Ss;
# This file auto generated from Data\common\main\ar_SS.xml
#	on Fri 29 Apr  6:51:00 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ar::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'GBP' => {
			symbol => 'GB£',
		},
		'SSP' => {
			symbol => '£',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
