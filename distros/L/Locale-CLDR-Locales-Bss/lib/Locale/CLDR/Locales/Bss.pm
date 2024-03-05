=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bss - Package for language Akoose

=cut

package Locale::CLDR::Locales::Bss;
# This file auto generated from Data\common\main\bss.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
				'bss' => 'Akoose',
 				'en' => 'Akáálé',
 				'fr' => 'Frɛnsé',

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
			'Latn' => 'Akoose',

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
			'CM' => 'Kamerûn',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'currency' => 'mɔné',

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
			auxiliary => qr{[f q r v x]},
			index => ['A', 'B', 'C', 'D', 'E', 'Ə', 'Ɛ', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'S', 'T', 'U', 'W', 'Y', 'Z'],
			main => qr{[aáâǎā b c d eéêěē ə{ə́}{ə̂}{ə̌}{ə̄} ɛ{ɛ́}{ɛ̂}{ɛ̌}{ɛ̄} g h iíîǐī j k l mḿ nń ŋ oóôǒō ɔ{ɔ́}{ɔ̂}{ɔ̌}{ɔ̄} p s t uúûǔū w y z ʼ]},
			punctuation => qr{[, ; \: ! ? . ' "]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ə', 'Ɛ', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'S', 'T', 'U', 'W', 'Y', 'Z'], };
},
);


has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} {1}),
		} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'XAF' => {
			display_name => {
				'currency' => q(Frânke CFA),
			},
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
