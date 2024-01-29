=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fo::Any::Dk - Package for language Faroese

=cut

package Locale::CLDR::Locales::Fo::Any::Dk;
# This file auto generated from Data\common\main\fo_DK.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Fo::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'DKK' => {
			symbol => 'kr.',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
