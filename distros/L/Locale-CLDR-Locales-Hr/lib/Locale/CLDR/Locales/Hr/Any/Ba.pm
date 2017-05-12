=head1

Locale::CLDR::Locales::Hr::Any::Ba - Package for language Croatian

=cut

package Locale::CLDR::Locales::Hr::Any::Ba;
# This file auto generated from Data\common\main\hr_BA.xml
#	on Fri 29 Apr  7:08:04 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Hr::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BAM' => {
			symbol => 'KM',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
