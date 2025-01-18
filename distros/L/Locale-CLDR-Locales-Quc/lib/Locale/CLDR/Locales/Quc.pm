=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Quc - Package for language Kʼicheʼ

=cut

package Locale::CLDR::Locales::Quc;
# This file auto generated from Data\common\main\quc.xml
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
				'quc' => 'Kʼicheʼ',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'MK' => 'Macedonia del Norte',

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
			auxiliary => qr{[c d f g h ñ z]},
			index => ['AÄ', '{Bʼ}', '{CH}', '{CHʼ}', 'E', 'I', 'J', 'K', '{Kʼ}', 'L', 'M', 'N', 'O', 'P', 'Q', '{Qʼ}', 'R', 'S', 'T', '{TZ}', '{TZʼ}', '{Tʼ}', 'U', 'V', 'W', 'X', 'Y'],
			main => qr{[aä {aʼ} {bʼ} {ch} {chʼ} e {eʼ} i {iʼ} j k {kʼ} l m n o p q {qʼ} r s t {tz} {tzʼ} {tʼ} u {uʼ} v w x y]},
		};
	},
EOT
: sub {
		return { index => ['AÄ', '{Bʼ}', '{CH}', '{CHʼ}', 'E', 'I', 'J', 'K', '{Kʼ}', 'L', 'M', 'N', 'O', 'P', 'Q', '{Qʼ}', 'R', 'S', 'T', '{TZ}', '{TZʼ}', '{Tʼ}', 'U', 'V', 'W', 'X', 'Y'], };
},
);


has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'GTQ' => {
			symbol => 'Q',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
