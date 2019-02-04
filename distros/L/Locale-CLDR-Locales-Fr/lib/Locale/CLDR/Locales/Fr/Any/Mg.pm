=encoding utf8

=head1

Locale::CLDR::Locales::Fr::Any::Mg - Package for language French

=cut

package Locale::CLDR::Locales::Fr::Any::Mg;
# This file auto generated from Data\common\main\fr_MG.xml
#	on Sun  3 Feb  1:52:11 pm GMT

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

extends('Locale::CLDR::Locales::Fr::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'MGA' => {
			symbol => 'Ar',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
