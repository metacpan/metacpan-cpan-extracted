=head1

Locale::CLDR::Locales::En::Any::Sb - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Sb;
# This file auto generated from Data\common\main\en_SB.xml
#	on Fri 29 Apr  6:59:57 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Any::001');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'SBD' => {
			symbol => '$',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
