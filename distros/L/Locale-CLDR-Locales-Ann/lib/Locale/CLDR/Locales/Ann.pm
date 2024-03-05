=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ann - Package for language Obolo

=cut

package Locale::CLDR::Locales::Ann;
# This file auto generated from Data\common\main\ann.xml
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
				'ann' => 'Obolo',

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
			auxiliary => qr{[áǎ c éě h íǐ ḿ ń óǒ{ọ́}{ọ̌} q ṣ úǔ x]},
			index => ['a', 'b', '{ch}', 'd', 'e', 'f', 'g', 'i', 'j', 'k', 'l', 'm', 'n{n̄}', 'oọ', 'p', 'r', 's', 't', 'u', 'v', 'w', 'y', 'z'],
			main => qr{[aàâ b {ch} d eèê f g iìî j k l m{m̀} nǹ{n̄} oòôọ{ọ̀}ộ p r s {sh} t uùû v w y z]},
			punctuation => qr{[, ; ! ? .]},
		};
	},
EOT
: sub {
		return { index => ['a', 'b', '{ch}', 'd', 'e', 'f', 'g', 'i', 'j', 'k', 'l', 'm', 'n{n̄}', 'oọ', 'p', 'r', 's', 't', 'u', 'v', 'w', 'y', 'z'], };
},
);


has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'NGN' => {
			symbol => '₦',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
