=head1

Locale::CLDR::Locales::Ko::Any::Kp - Package for language Korean

=cut

package Locale::CLDR::Locales::Ko::Any::Kp;
# This file auto generated from Data\common\main\ko_KP.xml
#	on Sun  5 Aug  6:09:00 pm GMT

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

extends('Locale::CLDR::Locales::Ko::Any');
has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'KP' => '조선민주주의인민공화국',

		}
	},
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Korea' => {
			long => {
				'daylight' => q#조선 하계 표준시#,
				'generic' => q#조선 시간#,
				'standard' => q#조선 표준시#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
