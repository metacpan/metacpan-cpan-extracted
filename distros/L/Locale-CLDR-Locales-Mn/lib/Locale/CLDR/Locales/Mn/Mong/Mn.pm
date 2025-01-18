=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mn::Mong::Mn - Package for language Mongolian

=cut

package Locale::CLDR::Locales::Mn::Mong::Mn;
# This file auto generated from Data\common\main\mn_Mong_MN.xml
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

extends('Locale::CLDR::Locales::Mn::Mong');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'de' => 'ᠭᠧᠷᠮᠠᠨ',
 				'de_AT' => 'ᠠᠦᠰᠲᠷᠢ ᠭᠧᠷᠮᠠᠨ',
 				'de_CH' => 'ᠰᠸᠢᠼᠸᠵᠯᠡᠨᠳᠠ ᠭᠧᠷᠮᠠᠨ',
 				'en' => 'ᠠᠨᠭᠭᠯᠢ',
 				'en_AU' => 'ᠠᠥ᠋ᠰᠲ᠋ᠠᠷᠠᠯᠢᠢ᠎ᠠ ᠠᠨᠭᠭᠯᠢ',
 				'en_CA' => 'ᠻᠠᠨᠠᠳᠠ ᠠᠨᠭᠭᠯᠢ',
 				'en_GB' => 'ᠪᠷᠢᠲ᠋ᠠᠨᠢ ᠠᠨᠭᠭᠯᠢ',
 				'en_US' => 'ᠠᠮᠧᠷᠢᠺᠠ ᠠᠨᠭᠭᠯᠢ',
 				'es' => 'ᠢᠰᠫᠠᠨᠢ',
 				'es_419' => 'ᠢᠰᠫᠠᠨᠢ (ᠯᠠᠠᠲ᠋ᠢᠨ ᠡᠠᠮᠸᠷᠢᠺᠠ)',
 				'es_ES' => 'ᠢᠰᠫᠠᠨᠢ (ᠢᠰᠫᠠᠨᠢ)',
 				'es_MX' => 'ᠢᠰᠫᠠᠨᠢ (ᠮᠸᠺᠰᠢᠺᠦ)',
 				'fr' => 'ᠹᠷᠠᠨᠼᠠ',
 				'fr_CA' => 'ᠹᠷᠠᠨᠼᠠ ᠹᠷᠠᠨᠼᠠ',
 				'fr_CH' => 'ᠰᠸᠢᠼᠸᠵᠯᠡᠨ᠋ᠳ᠋ ᠹᠷᠠᠨᠼᠠ',
 				'it' => 'ᠢᠲ᠋ᠠᠯᠢ',
 				'ja' => 'ᠶᠡᠫᠥᠠ',
 				'mn' => 'ᠮᠣᠩᠭᠣᠯ',
 				'pt' => 'ᠫᠣᠷᠲ᠋ᠦ᠋ᠭᠠᠯᠢ',
 				'pt_PT' => 'ᠫᠣᠷᠲ᠋ᠦ᠋ᠭᠠᠯᠢ (ᠫᠣᠷᠲ᠋ᠦ᠋ᠭᠠᠯᠢ)',
 				'ru' => 'ᠣᠷᠣᠰ',
 				'und' => 'ᠲᠣᠳᠣᠷᠬᠠᠢ ᠥᠭᠡᠢ ᠬᠡᠯᠡ',
 				'zh' => 'ᠬᠢᠳᠠᠳ',
 				'zh_Hans' => 'ᠬᠢᠯᠪᠠᠷᠰᠢᠭᠣᠯᠣᠭᠰᠠᠨ ᠬᠢᠳᠠᠳ',
 				'zh_Hant' => 'ᠣᠯᠠᠮᠵᠢᠯᠠᠯᠳᠥ ᠬᠢᠳᠠᠳ',

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
			'Arab' => 'ᠡᠡᠷᠡᠪ',
 			'Cyrl' => 'ᠻᠢᠷᠢᠯᠯ',
 			'Hans' => 'ᠺᠢᠯᠪᠡᠷᠰᠢᠭᠣᠯᠥᠡᠡᠰᠡᠠ',
 			'Hans@alt=stand-alone' => 'ᠺᠢᠯᠪᠡᠷᠰᠢᠭᠣᠯᠥᠡᠡᠰᠡᠠ ᠬᠠᠠᠵᠢ',
 			'Hant' => 'ᠣᠯᠠᠮᠵᠥᠯᠠᠯᠳᠥ',
 			'Hant@alt=stand-alone' => 'ᠣᠯᠡᠮᠵᠢᠯᠡᠯᠳᠥ ᠬᠠᠨᠵᠢ',
 			'Latn' => 'ᠯᠠᠲ᠋ᠢᠨ',
 			'Mong' => 'ᠮᠣᠩᠭᠣᠯ ᠪᠢᠴᠢᠭ᠌',
 			'Zxxx' => 'ᠪᠢᠴᠢᠭᠳᠡᠭᠡ ᠥᠭᠡᠢ',
 			'Zzzz' => 'ᠳᠥᠳᠥᠷᠬᠠᠢ ᠥᠬᠡᠢ ᠪᠢᠴᠢᠭ᠌',

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
			'BR' => 'ᠪᠷᠠᠽᠢᠯ',
 			'CN' => 'ᠬᠢᠳᠠᠳ',
 			'DE' => 'ᠭᠧᠷᠮᠠᠨ',
 			'FR' => 'ᠫᠷᠠᠨ᠋᠋ᠼᠠ',
 			'GB' => 'ᠶᠡᠺᠡ ᠪᠷᠢᠲ᠋ᠠᠨᠢ',
 			'IN' => 'ᠡᠨᠡᠳᠬᠡᠭ᠌',
 			'IT' => 'ᠢᠲ᠋ᠠᠯᠢ',
 			'JP' => 'ᠶᠠᠫᠣᠨ',
 			'MN' => 'ᠮᠣᠩᠭᠣᠯ',
 			'RU' => 'ᠣᠷᠣᠰ',
 			'US' => 'ᠠᠮᠸᠷᠢᠻᠠ ᠎ᠢᠢᠨ ᠨᠢᠭᠡᠳᠥᠭᠰᠡᠠ ᠡᠣᠯᠣᠰ',
 			'ZZ' => 'ᠳᠣᠳᠣᠷᠬᠠᠢ ᠥᠭᠡᠢ ᠪᠥᠰᠠ',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'gregorian' => q{ᠭᠸᠷᠸᠭᠣᠷᠢ ᠢᠨ ᠬᠣᠸᠠᠩᠯᠢ},
 			},
 			'collation' => {
 				'standard' => q{ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠡᠷᠡᠮᠪᠡᠯᠡᠬᠥ ᠳᠠᠷᠠᠭᠠᠯᠠᠯ},
 			},
 			'numbers' => {
 				'latn' => q{ᠠᠷᠠᠪ ᠲᠣᠭ᠎ᠠ},
 				'mong' => q{ᠮᠣᠩᠭᠣᠯ ᠲᠣᠭ᠎ᠠ},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{ᠮᠧᠲ᠋ᠷ ᠦᠨ},
 			'UK' => q{ᠢ᠂ ᠪ},
 			'US' => q{ᠠ᠂ ᠨ᠂ ᠣ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ᠺᠡᠯᠠ᠄ {0}',
 			'script' => 'ᠪᠢᠴᠢᠭ᠌: {0}',
 			'region' => 'ᠮᠣᠵᠢ᠄ {0}',

		}
	},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'hh:mm',
				hms => 'hh:mm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᠲᠡᠢᠢᠮᠣ᠄ ᠲ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᠥᠬᠡᠢ᠄ ᠥ|no|n)$' }
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤#,##0.00',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(ᠪᠷᠠᠽᠢᠯ ᠤᠨ ᠷᠧᠠᠯ),
				'one' => q(ᠪᠷᠠᠽᠢᠯ ᠤᠨ ᠷᠧᠠᠯ),
				'other' => q(ᠪᠷᠠᠽᠢᠯ ᠤᠨ ᠷᠧᠠᠯ),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(ᠬᠢᠲᠠᠳ ᠶᠤᠸᠠᠨ),
				'one' => q(ᠬᠢᠲᠠᠳ ᠶᠤᠸᠠᠨ),
				'other' => q(ᠬᠢᠲᠠᠳ ᠶᠤᠸᠠᠨ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ᠶᠧᠸᠷᠣ),
				'one' => q(ᠶᠧᠸᠷᠣ),
				'other' => q(ᠶᠧᠸᠷᠣ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ᠪᠷᠢᠲ᠋ᠠᠨᠢ ᠢᠢᠨ ᠫᠤᠢᠨᠳ᠋),
				'one' => q(ᠪᠷᠢᠲ᠋ᠠᠨᠢ ᠢᠢᠨ ᠫᠤᠢᠨᠳ᠋),
				'other' => q(ᠪᠷᠢᠲ᠋ᠠᠨᠢ ᠢᠢᠨ ᠫᠤᠢᠨᠳ᠋),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ᠡᠨᠡᠳᠬᠡᠭ᠌ ᠷᠦᠫᠢ),
				'one' => q(ᠡᠨᠡᠳᠬᠡᠭ᠌ ᠷᠦᠫᠢ),
				'other' => q(ᠡᠨᠡᠳᠬᠡᠭ᠌ ᠷᠦᠫᠢ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ᠶᠠᠫᠣᠨ ᠧᠨ),
				'one' => q(ᠶᠠᠫᠣᠨ ᠧᠨ),
				'other' => q(ᠶᠠᠫᠣᠨ ᠧᠨ),
			},
		},
		'MNT' => {
			symbol => '₮',
			display_name => {
				'currency' => q(ᠳᠥᠬᠥᠷᠢᠭ᠌),
				'one' => q(ᠳᠥᠬᠥᠷᠢᠭ᠌),
				'other' => q(ᠳᠥᠬᠥᠷᠢᠭ᠌),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ᠣᠷᠥᠰ ᠷᠥᠪᠯᠢ),
				'one' => q(ᠣᠷᠥᠰ ᠷᠥᠪᠯᠢ),
				'other' => q(ᠣᠷᠥᠰ ᠷᠥᠪᠯᠢ),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ᠠᠮᠸᠷᠢᠻᠠ ᠳ᠋ᠣᠯᠯᠠᠷ),
				'one' => q(ᠠᠮᠸᠷᠢᠻᠠ ᠳ᠋ᠣᠯᠯᠠᠷ),
				'other' => q(ᠠᠮᠸᠷᠢᠻᠠ ᠳ᠋ᠣᠯᠯᠠᠷ),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ᠲᠣᠳᠣᠷᠬᠠᠢ ᠥᠭᠡᠢ ᠮᠥᠩᠭᠥᠨ ᠲᠡᠮᠳᠡᠭᠳᠥ),
				'one' => q(ᠲᠣᠳᠣᠷᠬᠠᠢ ᠥᠭᠡᠢ ᠮᠥᠩᠭᠥᠨ ᠲᠡᠮᠳᠡᠭᠳᠥ ᠢᠢᠨ ᠨᠢᠭᠡᠴᠡ),
				'other' => q(\(ᠲᠣᠳᠣᠷᠬᠠᠢ ᠥᠭᠡᠢ ᠮᠥᠩᠭᠥᠨ ᠲᠡᠮᠳᠡᠭᠳᠥ\)),
			},
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
							'1 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'2 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'3᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'4 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'5 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'6 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'7 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'8᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'9 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'10 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'11 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'12 ᠊ᠷ ᠰᠠᠷ᠎ᠠ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ᠨᠢᠭᠡᠳᠥᠭᠡᠷ ᠰᠠᠷ᠎ᠠ',
							'ᠬᠣᠶᠠᠳᠣᠭᠠᠷ ᠰᠠᠷ ᠠ',
							'ᠭᠣᠷᠪᠡᠳᠣᠭᠠᠷ ᠰᠠᠷ ᠠ',
							'ᠳᠥᠷᠪᠡᠳᠥᠭᠡᠷ ᠰᠠᠷ᠎ᠠ',
							'ᠲᠠᠪᠣᠳᠣᠭᠠᠷ ᠰᠠᠷ ᠠ',
							'ᠵᠢᠷᠭᠣᠭᠠᠳᠣᠭᠠᠷ ᠰᠠᠷ᠎ᠠ',
							'ᠲᠣᠯᠣᠭᠠᠳᠣᠭᠠᠷ ᠰᠠᠷ᠎ᠠ',
							'ᠨᠠᠢᠮᠠᠳᠥᠭᠠᠷ ᠰᠠᠷ᠎ᠠ',
							'ᠶᠢᠰᠥᠳᠥᠭᠡᠷ ᠰᠠᠷ᠎ᠠ',
							'ᠠᠷᠪᠠᠳᠣᠭᠠᠷ ᠰᠠᠷ᠎ᠠ',
							'ᠠᠷᠪᠠᠨ ᠨᠢᠭᠡᠳᠥᠭᠡᠷ ᠰᠠᠷ᠎ᠠ',
							'ᠠᠷᠪᠠᠨ ᠬᠣᠶᠠᠳᠣᠭᠠᠷ ᠰᠠᠷ᠎ᠠ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'1 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'2 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'3᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'4 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'5 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'6 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'7 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'8 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'9 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'10 ᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'11᠊ᠷ ᠰᠠᠷ᠎ᠠ',
							'12᠊ᠷ ᠰᠠᠷ᠎ᠠ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'I',
							'II',
							'III',
							'IV',
							'V',
							'VI',
							'VII',
							'VIII',
							'IX',
							'X',
							'XI',
							'XII'
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
					abbreviated => {
						mon => 'ᠲᠠ',
						tue => 'ᠮᠢᠭ',
						wed => 'ᡀᠠ',
						thu => 'ᠫᠥᠷ',
						fri => 'ᠪᠠ',
						sat => 'ᠪᠢᠮ',
						sun => 'ᠨᠢ'
					},
					narrow => {
						mon => 'ᠳᠠ',
						tue => 'ᠮᠢᠭ',
						wed => 'ᡀᠠ',
						thu => 'ᠫᠥᠷ',
						fri => 'ᠪᠠ',
						sat => 'ᠪᠢ',
						sun => 'ᠨᠢ'
					},
					wide => {
						mon => 'ᠳᠠᠸᠠ',
						tue => 'ᠮᠢᠠᠠᠮᠠᠷ',
						wed => 'ᡀᠠᠭᠪᠠ',
						thu => 'ᠫᠦᠷᠪᠦ',
						fri => 'ᠪᠠᠰᠠᠩ',
						sat => 'ᠪᠢᠮᠪᠠ',
						sun => 'ᠨᠢᠮ᠎ᠠ'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'ᠳᠠ',
						tue => 'ᠮᠢᠭ',
						wed => 'ᡀᠠ',
						thu => 'ᠫᠦᠷ',
						fri => 'ᠪᠠ',
						sat => 'ᠪᠢᠮ',
						sun => 'ᠨᠢ'
					},
					narrow => {
						mon => 'ᠳᠠ',
						tue => 'ᠮᠢᠭ',
						wed => 'ᡀᠠ',
						thu => 'ᠫᠥᠷ',
						fri => 'ᠪᠠ',
						sat => 'ᠪᠢᠮ',
						sun => 'ᠨᠢ'
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
				'format' => {
					abbreviated => {0 => '1 ᠣᠯᠠᠷᠢᠯ',
						1 => '2 ᠣᠯᠠᠷᠢᠯ',
						2 => '3 ᠣᠯᠠᠷᠢᠯ',
						3 => '4 ᠣᠯᠠᠷᠢᠯ'
					},
					wide => {0 => '1 ᠊ᠷ ᠣᠯᠠᠷᠢᠯ',
						1 => '2 ᠊ᠷ ᠣᠯᠠᠷᠢᠯ',
						2 => '3 ᠊ᠷ ᠣᠯᠠᠷᠢᠯ',
						3 => '4 ᠊ᠷ ᠣᠯᠠᠷᠢᠯ'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'I',
						1 => 'II',
						2 => 'III',
						3 => 'IV'
					},
					narrow => {0 => 'I',
						1 => 'II',
						2 => 'III',
						3 => 'IV'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'wide' => {
					'am' => q{ᠦ᠂ ᠥ},
					'pm' => q{ᠦ᠂ ᠬᠣ},
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
			abbreviated => {
				'0' => 'ᠮ᠂ ᠡᠡ᠂ ᠦ',
				'1' => 'ᠮ᠂ ᠡ'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{y ᠤᠨ ᠣ MM ᠰᠠᠷ ᠠ ᠢᠢᠨ dd},
			'long' => q{y ᠣᠨ ᠎ᠤ MM ᠰᠠᠷ᠎ᠠ ᠎ᠢᠢᠨ dd},
			'medium' => q{y MM d},
			'short' => q{y-MM-dd},
		},
		'gregorian' => {
			'full' => q{y ᠣᠨ ᠎᠎᠎ᠤ MMMM᠎᠎ᠢᠢᠨd. EEEE ᠋ᠭᠠᠷᠠᠭ},
			'long' => q{y ᠋ᠣᠨ ᠤMMMM᠎᠎ ᠤᠩ d},
			'medium' => q{y.MM.dd},
			'short' => q{y.MM.dd},
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
			'full' => q{HH:mm:ss (zzzz)},
			'long' => q{HH:mm:ss (z)},
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
		'generic' => {
			fallback => '{0} - {1}',
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(GMT {0}),
		regionFormat => q({0} ᠴᠠᠭ),
		regionFormat => q({0} ᠵᠣᠨ ᠎᠎᠎ᠤ ᠴᠠᠭ),
		regionFormat => q({0} ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ),
		'America_Central' => {
			long => {
				'daylight' => q#ᠲᠥᠪ ᠵᠣᠨ ᠎᠎᠎ᠤ ᠴᠠᠭ#,
				'generic' => q#ᠲᠥᠪ ᠴᠠᠭ#,
				'standard' => q#ᠳᠥᠪ ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ᠵᠡᠭᠥᠨ ᠡᠷᠭᠡ ᠎ᠢᠢᠨ ᠵᠣᠨ ᠎᠎᠎ᠤ ᠴᠠᠭ#,
				'generic' => q#ᠵᠡᠭᠥᠨ ᠡᠷᠭᠡ ᠎ᠢᠢᠨ ᠴᠠᠭ#,
				'standard' => q#ᠵᠡᠭᠥᠨ ᠡᠷᠭᠡ ᠎ᠢᠢᠨ ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ᠠᠭᠣᠯᠠ ᠎ᠢᠢᠨ ᠵᠣᠨ ᠎᠎ᠤ ᠴᠠᠭ#,
				'generic' => q#ᠠᠭᠣᠯᠠ ᠎᠎᠎᠎ᠢᠢᠨ ᠴᠠᠭ#,
				'standard' => q#ᠠᠭᠣᠯᠠ ᠎᠎᠎᠎ᠢᠢᠨ ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#ᠨᠣᠮᠣᠬᠠᠨ ᠳᠠᠯᠠᠢ ᠎ᠢᠢᠨ ᠵᠣᠨ ᠎᠎᠎ᠪ ᠴᠠᠭ#,
				'generic' => q#ᠨᠣᠮᠣᠬᠠᠨ ᠳᠠᠯᠠᠢ ᠎ᠢᠢᠨ ᠴᠠᠭ#,
				'standard' => q#ᠨᠣᠮᠣᠬᠠᠨ ᠳᠠᠯᠠᠢ ᠎᠎ᠢᠢᠨ ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ#,
			},
		},
		'Asia/Hovd' => {
			exemplarCity => q#ᠬᠣᠪᠳᠣ#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#ᠣᠯᠠᠭᠠᠨᠪᠠᠭᠠᠳᠣᠷ#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ᠠᠲ᠋ᠯᠠᠨ᠋ᠲ ᠎ᠤᠨ ᠵᠣᠨ ᠎ᠪ ᠴᠠᠭ#,
				'generic' => q#ᠠᠲ᠋ᠯᠠᠨ᠋ᠲ᠋ ᠎ᠤᠨ ᠴᠠᠭ#,
				'standard' => q#ᠠᠲ᠋ᠯᠠᠨ᠋ᠲ ᠎ᠤᠨ ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ᠣᠯᠠᠨ ᠣᠯᠣᠰ ᠤᠨ ᠵᠣᠬᠢᠴᠡᠭᠣᠯᠣᠯᠳᠠᠳᠠᠢ ᠴᠠᠭ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ᠥᠯᠥ ᠮᠡᠳᠡᠭᠳᠡᠬᠥ ᠬᠣᠳᠠ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ᠲᠥᠪ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠵᠣᠨ ᠎᠎ᠤ ᠴᠠᠭ#,
				'generic' => q#ᠲᠥᠪ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠴᠠᠭ#,
				'standard' => q#ᠲᠥᠪ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ᠵᠡᠭᠦᠨ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠵᠣᠨ ᠎᠎ᠤ ᠴᠠᠭ#,
				'generic' => q#ᠵᠡᠭᠦᠨ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠴᠠᠭ#,
				'standard' => q#ᠵᠡᠭᠦᠨ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ᠪᠠᠷᠠᠭᠣᠨ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠵᠣᠨ ᠎᠎ᠤ ᠴᠠᠭ#,
				'generic' => q#ᠪᠠᠷᠠᠭᠣᠨ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠴᠠᠭ#,
				'standard' => q#ᠪᠠᠷᠠᠭᠣᠨ ᠡᠸᠣᠢᠷᠤᠫᠠ ᠢᠢᠨ ᠰᠲ᠋ᠠᠨ᠋ᠳᠠᠷᠳ᠋ ᠴᠠᠭ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ᠭᠷᠢᠨ᠋ᠸᠢᠴᠢ ᠢᠢᠨ ᠴᠠᠭ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
