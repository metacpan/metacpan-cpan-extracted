=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Cho - Package for language Choctaw

=cut

package Locale::CLDR::Locales::Cho;
# This file auto generated from Data\common\main\cho.xml
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
				'cho' => 'Chahta',
 				'en' => 'English',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Latn' => 'Latin',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'US' => 'United States',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Anumpa: {0}',

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
			auxiliary => qr{[cč d g j q r š x z]},
			index => ['A{A̱}', 'B', '{CH}', 'E', 'F', 'H', '{HL}', 'I{I̱}', 'K', 'L', 'M', 'N', 'O{O̱}', 'P', 'S', '{SH}', 'T', 'U', 'V', 'Ʋ', 'W', 'Z'],
			main => qr{[a{a̱} b {ch} e f h {hl} i{i̱} k l m n o{o̱} p s {sh} t u v ʋ w y]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A{A̱}', 'B', '{CH}', 'E', 'F', 'H', '{HL}', 'I{I̱}', 'K', 'L', 'M', 'N', 'O{O̱}', 'P', 'S', '{SH}', 'T', 'U', 'V', 'Ʋ', 'W', 'Z'], };
},
);


no Moo;

1;

# vim: tabstop=4
