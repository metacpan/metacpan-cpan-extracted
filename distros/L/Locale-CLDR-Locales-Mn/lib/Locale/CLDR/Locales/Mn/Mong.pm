=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mn::Mong - Package for language Mongolian

=cut

package Locale::CLDR::Locales::Mn::Mong;
# This file auto generated from Data\common\main\mn_Mong.xml
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
has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{СИ систем},
 			'UK' => q{Их Британи},
 			'US' => q{АНУ},

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'left-to-right',
			characters => 'top-to-bottom',
		}}
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
			index => ['ᠠ', 'ᠡ', 'ᠢ', 'ᠣ', 'ᠤ', 'ᠥ', 'ᠦ', 'ᠧ', 'ᠨ', 'ᠩ', 'ᠪ', 'ᠫ', 'ᠬ', 'ᠭ', 'ᠮ', 'ᠯ', 'ᠰ', 'ᠱ', 'ᠲ', 'ᠳ', 'ᠴ', 'ᠵ', 'ᠶ', 'ᠷ', 'ᠸ', 'ᠹ', 'ᠺ', 'ᠻ', 'ᠼ', 'ᠽ', 'ᠾ', 'ᠿ', 'ᡀ', 'ᡁ', 'ᡂ'],
			main => qr{[᠐ ᠑ ᠒ ᠓ ᠔ ᠕ ᠖ ᠗ ᠘ ᠙ ᠠ ᠡ ᠢ ᠣ ᠤ ᠥ ᠦ ᠧ ᠨ ᠩ ᠪ ᠫ ᠬ ᠭ ᠮ ᠯ ᠰ ᠱ ᠲ ᠳ ᠴ ᠵ ᠶ ᠷ ᠸ ᠹ ᠺ ᠻ ᠼ ᠽ ᠾ ᠿ ᡀ ᡁ ᡂ]},
		};
	},
EOT
: sub {
		return { index => ['ᠠ', 'ᠡ', 'ᠢ', 'ᠣ', 'ᠤ', 'ᠥ', 'ᠦ', 'ᠧ', 'ᠨ', 'ᠩ', 'ᠪ', 'ᠫ', 'ᠬ', 'ᠭ', 'ᠮ', 'ᠯ', 'ᠰ', 'ᠱ', 'ᠲ', 'ᠳ', 'ᠴ', 'ᠵ', 'ᠶ', 'ᠷ', 'ᠸ', 'ᠹ', 'ᠺ', 'ᠻ', 'ᠼ', 'ᠽ', 'ᠾ', 'ᠿ', 'ᡀ', 'ᡁ', 'ᡂ'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:тийм|т|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:үгүй|ү|no|n)$' }
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'mong',
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(бразил реал),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(юань),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(евро),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(фунт стерлинг),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(рупи),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(иен),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(төгрөг),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(рубль),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(ам. доллар),
			},
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
