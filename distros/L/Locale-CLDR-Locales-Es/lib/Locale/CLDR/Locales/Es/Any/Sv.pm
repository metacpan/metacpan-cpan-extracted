=head1

Locale::CLDR::Locales::Es::Any::Sv - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Sv;
# This file auto generated from Data\common\main\es_SV.xml
#	on Fri 29 Apr  7:00:52 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Es::Any::419');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'USD' => {
			symbol => '$',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
