=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ha::Any::Ne - Package for language Hausa

=cut

package Locale::CLDR::Locales::Ha::Any::Ne;
# This file auto generated from Data\common\main\ha_NE.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
				'ar_001' => 'Larabci Asali Na Zamani',
 				'de_AT' => 'Jamusanci Ostiriya',
 				'de_CH' => 'Jamusanci Suwizalan',
 				'en_AU' => 'Turanci Ostareliya',
 				'en_CA' => 'Turanci Kanada',
 				'en_GB' => 'Turanci Biritaniya',
 				'en_GB@alt=short' => 'Turancin Ingila',
 				'en_US' => 'Turanci Amirka',
 				'en_US@alt=short' => 'Turancin Amurka',
 				'es_419' => 'Sifaniyancin Latin Amirka',
 				'es_ES' => 'Sifaniyanci Turai',
 				'es_MX' => 'Sifaniyanci Mesiko',
 				'fa_AF' => 'Vote Farisanci na Afaganistan',
 				'fr_CA' => 'Farasanci Kanada',
 				'fr_CH' => 'Farasanci Suwizalan',
 				'pt_BR' => 'Harshen Potugis na Birazil',
 				'pt_PT' => 'Potugis Ƙasashen Turai',
 				'zh_Hans' => 'Sauƙaƙaƙƙen Sinanci',
 				'zh_Hant' => 'Sinanci na gargajiya',

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
