=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Shn - Package for language Shan

=cut

package Locale::CLDR::Locales::Shn;
# This file auto generated from Data\common\main\shn.xml
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
				'shn' => 'တႆး',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Mymr' => 'မျၢၼ်ႇမႃႇ',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'MM' => 'မျၢၼ်ႇမႃႇ (မိူင်းမၢၼ်ႈ)',
 			'TH' => 'မိူင်းထႆး',

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
			auxiliary => qr{[ꩡ ꩦ ꩧ ꩨ ꩩ ꩮ]},
			index => ['ၵ', 'ၶ', 'ၷ', 'ꧠ', 'င', 'ၸ', 'ꩡ', 'ꧡ', 'ꧢ', 'ၺ', 'ꩦ', 'ꩧ', 'ꩨ', 'ꩩ', 'တ', 'ထ', 'ၻ', 'ၼ', 'ပ', 'ၽ', 'ၾ', 'ၿ', 'ꧤ', 'မ', 'ယ', 'ရ', 'လ', 'ဝ', 'ႀ', 'သ', 'ႁ', 'ꩮ', 'ဢ'],
			main => qr{[​း ႞ ႟ ၵ ၶ ၷ င ၸ ၺ ꧣ တ ထ ၻ ၼ ပ ၽ ၾ ၿ ꧤ မ ယ ျ ရ ြ လ ဝ ွ ႂ ႀ သ ႁ ဢ ႃ ိ ီ ု ူ ေ ႄ ꧥ ် ႇ ႈ ႉ ႊ]},
			numbers => qr{[႐ ႑ ႒ ႓ ႔ ႕ ႖ ႗ ႘ ႙]},
			punctuation => qr{[၊ ။ ‘’ “”]},
		};
	},
EOT
: sub {
		return { index => ['ၵ', 'ၶ', 'ၷ', 'ꧠ', 'င', 'ၸ', 'ꩡ', 'ꧡ', 'ꧢ', 'ၺ', 'ꩦ', 'ꩧ', 'ꩨ', 'ꩩ', 'တ', 'ထ', 'ၻ', 'ၼ', 'ပ', 'ၽ', 'ၾ', 'ၿ', 'ꧤ', 'မ', 'ယ', 'ရ', 'လ', 'ဝ', 'ႀ', 'သ', 'ႁ', 'ꩮ', 'ဢ'], };
},
);


no Moo;

1;

# vim: tabstop=4
