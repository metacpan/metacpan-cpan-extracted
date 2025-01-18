=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Smj - Package for language Lule Sami

=cut

package Locale::CLDR::Locales::Smj;
# This file auto generated from Data\common\main\smj.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
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
				'smj' => 'julevsámegiella',

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
			auxiliary => qr{[c ñ ö q w x y z]},
			index => ['AÁÅÄ', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'NŃ', 'O', 'P', 'R', 'S', 'T', 'U', 'V'],
			main => qr{[aáåä b d e f g h i j k l m nń o p r s t u v]},
		};
	},
EOT
: sub {
		return { index => ['AÁÅÄ', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'NŃ', 'O', 'P', 'R', 'S', 'T', 'U', 'V'], };
},
);


no Moo;

1;

# vim: tabstop=4
