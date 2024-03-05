=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tyv - Package for language Tuvinian

=cut

package Locale::CLDR::Locales::Tyv;
# This file auto generated from Data\common\main\tyv.xml
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
has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			index => ['А', 'Б', 'В', 'Г', 'Д', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'Ң', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'],
			main => qr{[а б в г д её ж з и й к л м н ң о ө п р с т у ү ф х ц ч ш щ ъ ы ь э ю я]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” « » ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'В', 'Г', 'Д', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'Ң', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'], };
},
);


no Moo;

1;

# vim: tabstop=4
