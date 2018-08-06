=head1

Locale::CLDR::Locales::Fr::Any::Gn - Package for language French

=cut

package Locale::CLDR::Locales::Fr::Any::Gn;
# This file auto generated from Data\common\main\fr_GN.xml
#	on Sun  5 Aug  6:01:49 pm GMT

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

extends('Locale::CLDR::Locales::Fr::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'GNF' => {
			symbol => 'FG',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
