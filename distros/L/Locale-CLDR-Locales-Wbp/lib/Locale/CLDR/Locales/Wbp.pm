=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Wbp - Package for language Warlpiri

=cut

package Locale::CLDR::Locales::Wbp;
# This file auto generated from Data\common\main\wbp.xml
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
				'en' => 'Yinkirliji',
 				'wbp' => 'Warlpiri',

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
			auxiliary => qr{[b c e f h o q s v x z]},
			index => ['J', 'K', 'L', '{LY}', 'M', 'N', '{NG}', '{NY}', 'P', 'R', '{RD}', '{RL}', '{RN}', '{RR}', '{RT}', 'T', 'W', 'Y'],
			main => qr{[a d g i j k l m n p r t u w y]},
		};
	},
EOT
: sub {
		return { index => ['J', 'K', 'L', '{LY}', 'M', 'N', '{NG}', '{NY}', 'P', 'R', '{RD}', '{RL}', '{RN}', '{RR}', '{RT}', 'T', 'W', 'Y'], };
},
);


no Moo;

1;

# vim: tabstop=4
