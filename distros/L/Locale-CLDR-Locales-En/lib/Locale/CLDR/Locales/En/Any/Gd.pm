=head1

Locale::CLDR::Locales::En::Any::Gd - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Gd;
# This file auto generated from Data\common\main\en_GD.xml
#	on Fri 29 Apr  6:59:45 pm GMT

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
		'XCD' => {
			symbol => '$',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
