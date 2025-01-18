=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sma::Latn::No - Package for language Southern Sami

=cut

package Locale::CLDR::Locales::Sma::Latn::No;
# This file auto generated from Data\common\main\sma_NO.xml
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

extends('Locale::CLDR::Locales::Sma::Latn');
has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			index => ['AÅ', 'Æ', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'OØ', 'P', 'R', 'S', 'T', 'U', 'V', 'Y'],
			main => qr{[aå æ b d e f g h i j k l m n oø p r s t u v y]},
		};
	},
EOT
: sub {
		return { index => ['AÅ', 'Æ', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'OØ', 'P', 'R', 'S', 'T', 'U', 'V', 'Y'], };
},
);


no Moo;

1;

# vim: tabstop=4
