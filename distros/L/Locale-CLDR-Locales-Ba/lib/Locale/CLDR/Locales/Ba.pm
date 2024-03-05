=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ba - Package for language Bashkir

=cut

package Locale::CLDR::Locales::Ba;
# This file auto generated from Data\common\main\ba.xml
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
				'ba' => 'башҡорт теле',

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
			index => ['А', 'Ә', 'Б', 'В', 'Г', 'Ғ', 'Д', 'Ҙ', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Ҡ', 'Л', 'М', 'Н', 'Ң', 'О', 'Ө', 'П', 'Р', 'С', 'Ҫ', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Һ', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'],
			main => qr{[а ә б в г ғ д ҙ её ж з и й к ҡ л м н ң о ө п р с ҫ т у ү ф х һ ц ч ш щ ъ ы ь э ю я]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Ә', 'Б', 'В', 'Г', 'Ғ', 'Д', 'Ҙ', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Ҡ', 'Л', 'М', 'Н', 'Ң', 'О', 'Ө', 'П', 'Р', 'С', 'Ҫ', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Һ', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'], };
},
);


no Moo;

1;

# vim: tabstop=4
