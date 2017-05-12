=head1

Locale::CLDR::Locales::Ru::Any::Md - Package for language Russian

=cut

package Locale::CLDR::Locales::Ru::Any::Md;
# This file auto generated from Data\common\main\ru_MD.xml
#	on Fri 29 Apr  7:23:49 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ru::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'MDL' => {
			symbol => 'L',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
