=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Arn - Package for language Mapuche

=cut

package Locale::CLDR::Locales::Arn;
# This file auto generated from Data\common\main\arn.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
				'arn' => 'Mapudungun',

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
			auxiliary => qr{[b c h j q x z]},
			index => ['A', '{CH}', 'D', 'E', 'F', 'G', 'I', 'K', 'LḺ', '{LL}', 'M', 'NÑṈ', '{NG}', 'O', 'P', 'R', 'S', '{SH}', 'TṮ', '{TR}', 'UÜ', 'W', 'Y'],
			main => qr{[a {ch} d e f g i k lḻ {ll} m nñṉ {ng} o p r s {sh} tṯ {tr} uü w y]},
		};
	},
EOT
: sub {
		return { index => ['A', '{CH}', 'D', 'E', 'F', 'G', 'I', 'K', 'LḺ', '{LL}', 'M', 'NÑṈ', '{NG}', 'O', 'P', 'R', 'S', '{SH}', 'TṮ', '{TR}', 'UÜ', 'W', 'Y'], };
},
);


no Moo;

1;

# vim: tabstop=4
