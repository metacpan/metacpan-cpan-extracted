=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ha::Any::Ne - Package for language Hausa

=cut

package Locale::CLDR::Locales::Ha::Any::Ne;
# This file auto generated from Data\common\main\ha_NE.xml
#	on Fri 13 Oct  9:18:57 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Ha::Any');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'eo' => 'Dʼan/Ƴar Kabilar Andalus',
 				'eu' => 'Dan/Ƴar Kabilar Bas',
 				'kn' => 'Dan/Ƴar Kabilar Kannada',
 				'sq' => 'Dʼan/Ƴar Kabilar Albaniya',
 				'te' => 'Dʼan/Ƴar Kabilar Telug',

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
			auxiliary => qr{[á à â é è ê í ì î ó ò ô p q {r̃} ú ù û v x {ʼy}]},
			index => ['A', 'B', 'Ɓ', 'C', 'D', 'Ɗ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'Ƙ', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Ƴ', 'Z'],
			main => qr{[a b ɓ c d ɗ e f g h i j k ƙ l m n o r s {sh} t {ts} u w y ƴ z ʼ]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ɓ', 'C', 'D', 'Ɗ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'Ƙ', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Ƴ', 'Z'], };
},
);


no Moo;

1;

# vim: tabstop=4
