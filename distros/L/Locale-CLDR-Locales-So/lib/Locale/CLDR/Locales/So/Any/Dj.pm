=encoding utf8

=head1

Locale::CLDR::Locales::So::Any::Dj - Package for language Somali

=cut

package Locale::CLDR::Locales::So::Any::Dj;
# This file auto generated from Data\common\main\so_DJ.xml
#	on Sun  3 Feb  2:18:28 pm GMT

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

extends('Locale::CLDR::Locales::So::Any');
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
