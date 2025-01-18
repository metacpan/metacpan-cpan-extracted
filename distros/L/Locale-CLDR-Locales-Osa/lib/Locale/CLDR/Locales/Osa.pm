=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Osa - Package for language Osage

=cut

package Locale::CLDR::Locales::Osa;
# This file auto generated from Data\common\main\osa.xml
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
				'osa' => '𐓏𐓘𐓻𐓘𐓻𐓟',

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
			'US' => 'United States',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'numbers' => {
 				'latn' => q{𐓷𐓘𐓵𐓘𐓷𐓘 𐓨𐓣𐓡𐓣𐓵𐓟 𐓣͘𐓤𐓯𐓟},
 			},

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
			index => ['𐒰{𐒰͘}', '𐒱', '𐒲', '𐒳', '𐒴', '𐒵', '𐒶', '𐒷', '𐒸', '𐒹', '𐒺', '𐒻{𐒻͘}', '𐒼', '𐒽', '𐒾', '𐒿', '𐓀', '𐓁', '𐓂{𐓂͘}', '𐓃', '𐓄', '𐓅', '𐓆', '𐓇', '𐓈', '𐓉', '𐓊', '𐓋', '𐓌', '𐓍', '𐓎', '𐓏', '𐓐', '𐓑', '𐓒', '𐓓'],
			main => qr{[𐓘{𐓘́}{𐓘́͘}{𐓘̋}{𐓘̋͘}{𐓘̄}{𐓘̄͘}{𐓘͘} 𐓙{𐓙́}{𐓙̋}{𐓙̄} 𐓚{𐓚́}{𐓚̋}{𐓚̄} 𐓛{𐓛͘} 𐓜 𐓝 𐓞 𐓟{𐓟́}{𐓟̋}{𐓟̄} 𐓠{𐓠́}{𐓠̋}{𐓠̄} 𐓡 𐓢 𐓣{𐓣́}{𐓣́͘}{𐓣̋}{𐓣̋͘}{𐓣̄}{𐓣̄͘}{𐓣͘} 𐓤 𐓥 𐓦 𐓧 𐓨 𐓩 𐓪{𐓪́}{𐓪́͘}{𐓪̋}{𐓪̋͘}{𐓪̄}{𐓪̄͘}{𐓪͘} 𐓫{𐓫́}{𐓫̋}{𐓫̄} 𐓬 𐓭 𐓮 𐓯 𐓰 𐓱 𐓲 𐓳 𐓴 𐓵 𐓶{𐓶́}{𐓶̋}{𐓶̄} 𐓷 𐓸 𐓹 𐓺 𐓻]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['𐒰{𐒰͘}', '𐒱', '𐒲', '𐒳', '𐒴', '𐒵', '𐒶', '𐒷', '𐒸', '𐒹', '𐒺', '𐒻{𐒻͘}', '𐒼', '𐒽', '𐒾', '𐒿', '𐓀', '𐓁', '𐓂{𐓂͘}', '𐓃', '𐓄', '𐓅', '𐓆', '𐓇', '𐓈', '𐓉', '𐓊', '𐓋', '𐓌', '𐓍', '𐓎', '𐓏', '𐓐', '𐓑', '𐓒', '𐓓'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(𐒹𐓘͘𐓬𐓘),
						'other' => q({0} 𐒹𐓘͘𐓬𐓘),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(𐒹𐓘͘𐓬𐓘),
						'other' => q({0} 𐒹𐓘͘𐓬𐓘),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(𐓨𐓣𐓪𐓵𐓘𐓤𐓟 𐓪𐓰𐓘𐓩𐓘͘),
						'other' => q({0} 𐓨𐓣𐓪𐓵𐓘𐓤𐓟 𐓪𐓰𐓘𐓩𐓘͘),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(𐓨𐓣𐓪𐓵𐓘𐓤𐓟 𐓪𐓰𐓘𐓩𐓘͘),
						'other' => q({0} 𐓨𐓣𐓪𐓵𐓘𐓤𐓟 𐓪𐓰𐓘𐓩𐓘͘),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(𐓰𐓘𐓲𐓟 𐓤𐓯𐓣𐓵𐓟),
						'other' => q({0} 𐓰𐓘𐓲𐓟 𐓤𐓯𐓣𐓵𐓟),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(𐓰𐓘𐓲𐓟 𐓤𐓯𐓣𐓵𐓟),
						'other' => q({0} 𐓰𐓘𐓲𐓟 𐓤𐓯𐓣𐓵𐓟),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(𐓀𐓣͘𐓪͘𐓬𐓘),
						'other' => q(𐓀𐓣͘𐓪͘𐓬𐓘 {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(𐓀𐓣͘𐓪͘𐓬𐓘),
						'other' => q(𐓀𐓣͘𐓪͘𐓬𐓘 {0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(𐓰𐓘𐓲𐓟 𐓤𐓯𐓣𐓵𐓟 𐓻𐓣͘),
						'other' => q({0} 𐓰𐓘𐓲𐓟 𐓤𐓯𐓣𐓵𐓟 𐓻𐓣͘),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(𐓰𐓘𐓲𐓟 𐓤𐓯𐓣𐓵𐓟 𐓻𐓣͘),
						'other' => q({0} 𐓰𐓘𐓲𐓟 𐓤𐓯𐓣𐓵𐓟 𐓻𐓣͘),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(𐒹𐓘͘𐓬𐓘𐓷𐓘𐓤𐓘͘𐓰𐓛𐓤𐓣),
						'other' => q(𐒹𐓘͘𐓬𐓘𐓷𐓘𐓤𐓘͘𐓰𐓛𐓤𐓣 {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(𐒹𐓘͘𐓬𐓘𐓷𐓘𐓤𐓘͘𐓰𐓛𐓤𐓣),
						'other' => q(𐒹𐓘͘𐓬𐓘𐓷𐓘𐓤𐓘͘𐓰𐓛𐓤𐓣 {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(𐓂𐓨𐓚𐓤𐓘),
						'other' => q(𐓂𐓨𐓚𐓤𐓘 {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(𐓂𐓨𐓚𐓤𐓘),
						'other' => q(𐓂𐓨𐓚𐓤𐓘 {0}),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'USD' => {
			symbol => '$',
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
					abbreviated => {
						nonleap => [
							'𐓄𐓘𐓡𐓛͘𐓧𐓟',
							'𐓵𐓪͘𐓬𐓘',
							'𐓵𐓘𐓜𐓣',
							'𐓰𐓪𐓬𐓘',
							'𐓮𐓘𐓰𐓘',
							'𐓯𐓘𐓬𐓟',
							'𐓄𐓟𐓵𐓪͘𐓬𐓘',
							'𐒼𐓣𐓟𐓰𐓪𐓬𐓘',
							'𐒿𐓟𐓜𐓛𐓲𐓟𐓷𐓣͘𐓤𐓟',
							'𐒿𐓟𐓜𐓛',
							'𐒰𐓧𐓣 𐓏𐓣͘𐓸𐓲𐓣',
							'𐒰𐓧𐓣 𐓍𐓪͘𐓬𐓘'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐓄𐓘𐓡𐓛͘𐓧𐓟',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐓏𐓟𐓵𐓪͘𐓬𐓘',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐓏𐓟𐓵𐓘𐓜𐓣',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐓏𐓟𐓰𐓪𐓬𐓘',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐓏𐓟𐓮𐓘𐓰𐓘',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐓏𐓟𐓯𐓘𐓬𐓟',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐓄𐓟𐓵𐓪͘𐓬𐓘',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐒼𐓣𐓟𐓰𐓪𐓬𐓘',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐒿𐓟𐓜𐓛𐓲𐓟𐓷𐓣͘𐓤𐓟',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐒿𐓟𐓜𐓛',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐒰𐓧𐓣 𐓏𐓣͘𐓸𐓲𐓣',
							'𐓀𐓣͘𐓪͘𐓬𐓘 𐒰𐓧𐓣 𐓍𐓪͘𐓬𐓘'
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
				'format' => {
					narrow => {
						mon => '𐓄',
						tue => '𐓍',
						wed => '𐒴',
						thu => '𐓈',
						fri => '𐓊',
						sat => '𐓸',
						sun => '𐓏'
					},
					wide => {
						mon => '𐒹𐓘͘𐓬𐓘 𐓄𐓘𐓡𐓛͘𐓧𐓣',
						tue => '𐒹𐓘͘𐓬𐓘 𐓏𐓟𐓵𐓪͘𐓬𐓘',
						wed => '𐒹𐓘͘𐓬𐓘 𐓏𐓟𐓵𐓘𐓜𐓣',
						thu => '𐒹𐓘͘𐓬𐓘 𐓏𐓟𐓰𐓪𐓬𐓘',
						fri => '𐒹𐓘͘𐓬𐓘 𐓈𐓘 𐓵𐓘𐓲𐓘 𐓻𐓣͘',
						sat => '𐒹𐓘͘𐓬𐓘 𐓂𐓤𐓘𐓸𐓟 𐓣͘𐓤𐓟',
						sun => '𐒹𐓘͘𐓬𐓘 𐓏𐓘𐓤𐓘͘𐓰𐓘𐓤𐓣'
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
		'generic' => {
		},
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
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
