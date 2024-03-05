=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sma - Package for language Southern Sami

=cut

package Locale::CLDR::Locales::Sma;
# This file auto generated from Data\common\main\sma.xml
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
				'sma' => 'Åarjelsaemien gïele',

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
			auxiliary => qr{[c ï q w x z]},
			index => ['AÅÄ', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'OÖ', 'P', 'R', 'S', 'T', 'U', 'V', 'Y'],
			main => qr{[aåä b d e f g h i j k l m n oö p r s t u v y]},
		};
	},
EOT
: sub {
		return { index => ['AÅÄ', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'OÖ', 'P', 'R', 'S', 'T', 'U', 'V', 'Y'], };
},
);


no Moo;

1;

# vim: tabstop=4
