=head1

Locale::CLDR::Locales::En::Any::Ch - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Ch;
# This file auto generated from Data\common\main\en_CH.xml
#	on Fri 29 Apr  6:59:41 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Any::150');
has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'superscriptingExponent' => q(·),
		},
	} }
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '¤-#,##0.00',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤-#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
} },
);

no Moo;

1;

# vim: tabstop=4
