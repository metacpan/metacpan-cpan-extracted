=head1

Locale::CLDR::Locales::Fr::Any::Cd - Package for language French

=cut

package Locale::CLDR::Locales::Fr::Any::Cd;
# This file auto generated from Data\common\main\fr_CD.xml
#	on Fri 29 Apr  7:04:09 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
		'CDF' => {
			symbol => 'FC',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
