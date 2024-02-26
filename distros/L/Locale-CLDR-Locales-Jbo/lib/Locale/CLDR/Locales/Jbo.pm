=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Jbo - Package for language Lojban

=cut

package Locale::CLDR::Locales::Jbo;
# This file auto generated from Data\common\main\jbo.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'jbo' => 'la .lojban.',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[q w]},
			index => ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'x', 'y', 'z'],
			main => qr{[a b c d e f g h i j k l m n o p r s t u v x y z]},
			punctuation => qr{[, . ']},
		};
	},
EOT
: sub {
		return { index => ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'x', 'y', 'z'], };
},
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Colombia' => {
			long => {
				'daylight' => q#cistcika fo la kolombiias#,
				'generic' => q#tcika fo la kolombiias#,
				'standard' => q#nalcistcika fo la kolombiias#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#tcika fo la galapagos#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
