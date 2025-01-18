=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Hnj - Package for language Hmong Njua

=cut

package Locale::CLDR::Locales::Hnj;
# This file auto generated from Data\common\main\hnj.xml
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
				'ar' => '𞄤𞄣',
 				'bn' => '𞄜𞄤',
 				'en' => '𞄥𞄴𞄅𞄇𞄉𞄦𞄱𞄊',
 				'fr' => '𞄕𞄤𞄰𞄎𞄦𞄴',
 				'hmn' => '𞄀𞄄𞄰𞄩',
 				'hnj' => '𞄀𞄄𞄰𞄩𞄍𞄜𞄰',
 				'zh' => '𞄋𞄄',

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
			'Hmnp' => '𞄐𞄦𞄲𞄤𞄎𞄫𞄰 𞄚𞄜𞄲𞄔𞄬𞄱 𞄀𞄄𞄰𞄩',

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
			'US' => '𞄒𞄫𞄱𞄔𞄩𞄴',

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
			index => ['𞄀', '𞄁', '𞄂', '𞄃', '𞄄', '𞄅', '𞄆', '𞄇', '𞄈', '𞄉', '𞄊', '𞄋', '𞄌', '𞄍', '𞄎', '𞄏', '𞄐', '𞄑', '𞄒', '𞄓', '𞄔', '𞄕', '𞄖', '𞄗', '𞄘', '𞄙', '𞄚', '𞄛', '𞄜', '𞄝', '𞄞', '𞄟', '𞄠', '𞄡', '𞄢', '𞄣', '𞄤', '𞄥', '𞄦', '𞄧', '𞄨', '𞄩', '𞄪', '𞄫', '𞄬'],
			main => qr{[𞄱 𞄶 𞄲 𞄳 𞄰 𞄴 𞄵 𞅏 𞄼 𞄽 𞄀 𞄁 𞄂 𞄃 𞄄 𞄅 𞄆 𞄇 𞄈 𞄉 𞄊 𞄋 𞄌 𞄍 𞄎 𞄏 𞄐 𞄑 𞄒 𞄓 𞄔 𞄕 𞄖 𞄗 𞄘 𞄙 𞄚 𞄛 𞄜 𞄝 𞄞 𞄟 𞄠 𞄡 𞄢 𞄣 𞄤 𞄥 𞄦 𞄧 𞄨 𞄩 𞄪 𞄫 𞄬 𞅎]},
			numbers => qr{[\- ‑ , . % + 𞅀 𞅁 𞅂 𞅃 𞅄 𞅅 𞅆 𞅇 𞅈 𞅉]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['𞄀', '𞄁', '𞄂', '𞄃', '𞄄', '𞄅', '𞄆', '𞄇', '𞄈', '𞄉', '𞄊', '𞄋', '𞄌', '𞄍', '𞄎', '𞄏', '𞄐', '𞄑', '𞄒', '𞄓', '𞄔', '𞄕', '𞄖', '𞄗', '𞄘', '𞄙', '𞄚', '𞄛', '𞄜', '𞄝', '𞄞', '𞄟', '𞄠', '𞄡', '𞄢', '𞄣', '𞄤', '𞄥', '𞄦', '𞄧', '𞄨', '𞄩', '𞄪', '𞄫', '𞄬'], };
},
);


has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'hmnp',
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'USD' => {
			symbol => '𞅎',
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					wide => {
						nonleap => [
							'𞄆𞄬',
							'𞄛𞄨𞄱𞄄𞄤𞄲𞄨',
							'𞄒𞄫𞄰𞄒𞄪𞄱',
							'𞄤𞄨𞄱',
							'𞄀𞄪𞄴',
							'𞄛𞄤𞄱𞄞𞄤𞄦',
							'𞄔𞄩𞄴𞄆𞄨𞄰',
							'𞄕𞄩𞄲𞄔𞄄𞄰𞄤',
							'𞄛𞄤𞄱𞄒𞄤𞄰',
							'𞄪𞄱𞄀𞄤𞄴',
							'𞄚𞄦𞄲𞄤𞄚𞄄𞄰𞄫',
							'𞄒𞄩𞄱𞄔𞄬𞄴'
						],
						leap => [
							
						],
					},
				},
			},
	} },
);

has 'calendar_days' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'stand-alone' => {
					wide => {
						mon => '𞄈𞄦',
						tue => '𞄆𞄨𞄰',
						wed => '𞄗𞄄𞄤𞄰𞄦',
						thu => '𞄙𞄤𞄱𞄨',
						fri => '𞄑𞄤𞄱𞄨',
						sat => '𞄊𞄧𞄳',
						sun => '𞄎𞄤𞄲'
					},
				},
			},
	} },
);

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'stand-alone' => {
					narrow => {0 => '𞅁',
						1 => '𞅂',
						2 => '𞅃',
						3 => '𞅄'
					},
				},
			},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			abbreviated => {
				'0' => '𞄜𞄆𞄪'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

no Moo;

1;

# vim: tabstop=4
