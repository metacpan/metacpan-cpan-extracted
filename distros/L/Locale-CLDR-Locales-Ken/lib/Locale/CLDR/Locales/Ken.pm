=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ken - Package for language Kenyang

=cut

package Locale::CLDR::Locales::Ken;
# This file auto generated from Data\common\main\ken.xml
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
				'ken' => 'Kɛnyaŋ',

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
			auxiliary => qr{[l q v x z]},
			index => ['A', 'bB', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'h', 'I', 'Ɨ', 'J', 'K', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'pP', 'R', 'S', 'T', 'U', 'Ʉ', 'W', 'yY'],
			main => qr{[aáàǎ b c d eéèě ɛ{ɛ́}{ɛ̀}{ɛ̌} f g {gb} {gh} h i ɨ{ɨ́}{ɨ̀}{ɨ̌} j k {kp} m n {ny} ŋ oóòǒ ɔ{ɔ́}{ɔ̀}{ɔ̌} p r s t uúùǔ ʉ{ʉ́}{ʉ̀}{ʉ̌} w y]},
			punctuation => qr{[\- ‑ , ; \: ! ? . ‘’ “”]},
		};
	},
EOT
: sub {
		return { index => ['A', 'bB', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'h', 'I', 'Ɨ', 'J', 'K', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'pP', 'R', 'S', 'T', 'U', 'Ʉ', 'W', 'yY'], };
},
);


no Moo;

1;

# vim: tabstop=4
