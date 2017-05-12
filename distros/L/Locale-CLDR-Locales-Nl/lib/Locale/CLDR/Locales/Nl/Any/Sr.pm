=head1

Locale::CLDR::Locales::Nl::Any::Sr - Package for language Dutch

=cut

package Locale::CLDR::Locales::Nl::Any::Sr;
# This file auto generated from Data\common\main\nl_SR.xml
#	on Fri 29 Apr  7:20:11 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Nl::Any');
has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'SRD' => {
			symbol => '$',
		},
	} },
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Suriname' => {
			short => {
				'standard' => q(SRT),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
