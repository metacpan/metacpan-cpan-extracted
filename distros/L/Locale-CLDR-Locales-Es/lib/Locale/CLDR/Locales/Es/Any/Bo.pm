=head1

Locale::CLDR::Locales::Es::Any::Bo - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Bo;
# This file auto generated from Data\common\main\es_BO.xml
#	on Fri 29 Apr  7:00:39 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Es::Any::419');
has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BOB' => {
			symbol => 'Bs',
		},
	} },
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Bolivia' => {
			short => {
				'standard' => q(BOT),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
