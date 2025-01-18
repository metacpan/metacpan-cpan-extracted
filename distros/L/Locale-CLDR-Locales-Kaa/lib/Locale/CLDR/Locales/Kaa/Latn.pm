=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kaa::Latn - Package for language Kara-Kalpak

=cut

package Locale::CLDR::Locales::Kaa::Latn;
# This file auto generated from Data\common\main\kaa_Latn.xml
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
has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[àăâåäãā æ ç éèĕêëē íìĭîïī ñ òŏôöøō œ ùŭûüū ÿ]},
			index => ['AÁ', 'B', 'C', '{Ch}', 'D', 'E', 'F', 'GǴ', 'H', 'IÍ', 'J', 'K', 'L', 'M', 'NŃ', 'OÓ', 'P', 'Q', 'R', 'S', '{Sh}', 'T', 'UÚ', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aá b c {ch} d e f gǵ h i ı j k l m nń oó p q r s {sh} t uú v w x y z]},
			numbers => qr{[\- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['AÁ', 'B', 'C', '{Ch}', 'D', 'E', 'F', 'GǴ', 'H', 'IÍ', 'J', 'K', 'L', 'M', 'NŃ', 'OÓ', 'P', 'Q', 'R', 'S', '{Sh}', 'T', 'UÚ', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


no Moo;

1;

# vim: tabstop=4
