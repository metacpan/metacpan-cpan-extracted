=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sat - Package for language Santali

=cut

package Locale::CLDR::Locales::Sat;
# This file auto generated from Data\common\main\sat.xml
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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'de' => 'ᱡᱟᱨᱢᱟᱱ',
 				'de_AT' => 'ᱚᱥᱴᱨᱤᱭᱟ ᱡᱟᱨᱢᱟᱱ',
 				'de_CH' => 'ᱥᱩᱣᱤᱥ ᱦᱟᱤ ᱡᱟᱨᱢᱟᱱ',
 				'en' => 'ᱟᱝᱜᱽᱨᱮᱡᱤ',
 				'en_AU' => 'ᱚᱥᱴᱨᱮᱞᱤᱭᱟᱱ ᱟᱝᱜᱽᱨᱮᱡᱤ',
 				'en_CA' => 'ᱠᱟᱱᱟᱰᱤᱭᱟᱱ ᱟᱝᱜᱽᱨᱮᱡᱤ',
 				'en_GB' => 'ᱵᱨᱤᱴᱤᱥ ᱟᱝᱜᱽᱨᱮᱡᱤ',
 				'en_GB@alt=short' => 'ᱭᱩᱠᱮ ᱟᱝᱜᱽᱨᱮᱡᱤ',
 				'en_US' => 'ᱟᱢᱮᱨᱤᱠᱟᱱ ᱟᱝᱜᱽᱨᱮᱡᱤ',
 				'en_US@alt=short' => 'ᱭᱩᱮᱥ ᱟᱝᱜᱽᱨᱮᱡᱤ',
 				'es' => 'ᱮᱥᱯᱮᱱᱤᱥ',
 				'es_419' => 'ᱞᱮᱴᱤᱱ ᱟᱢᱮᱨᱤᱠᱟᱱ ᱮᱥᱯᱮᱱᱤᱥ',
 				'es_ES' => 'ᱨᱩᱥᱤᱭᱟᱱ ᱮᱥᱯᱮᱱᱤᱥ',
 				'es_MX' => 'ᱢᱮᱠᱥᱤᱠᱟᱱ ᱮᱥᱯᱮᱱᱤᱥ',
 				'fr' => 'ᱯᱷᱨᱮᱧᱪ',
 				'fr_CA' => 'ᱠᱟᱱᱟᱰᱤᱭᱟᱱ ᱯᱷᱨᱮᱧᱪ',
 				'fr_CH' => 'ᱥᱩᱣᱤᱥ ᱯᱷᱨᱮᱧᱪ',
 				'it' => 'ᱤᱴᱟᱞᱤᱟᱱ',
 				'ja' => 'ᱡᱟᱯᱟᱱᱤ',
 				'pt' => 'ᱯᱩᱨᱛᱜᱟᱞᱤ',
 				'pt_BR' => 'ᱵᱨᱟᱡᱤᱞᱤᱭᱟᱱ ᱯᱩᱨᱛᱜᱟᱞᱤ',
 				'pt_PT' => 'ᱭᱩᱨᱚᱯᱤᱭᱟᱱ ᱯᱩᱨᱛᱜᱟᱞᱤ',
 				'ru' => 'ᱨᱩᱥᱤᱭᱟᱱ',
 				'sat' => 'ᱥᱟᱱᱛᱟᱲᱤ',
 				'und' => 'ᱵᱟᱝ ᱩᱨᱩᱢ ᱯᱟᱹᱨᱥᱤ',
 				'zh' => 'ᱪᱟᱭᱱᱤᱡᱽ',
 				'zh@alt=menu' => 'ᱪᱟᱭᱱᱤᱡᱽ, ᱢᱟᱱᱰᱟᱨᱤᱱ',
 				'zh_Hans' => 'ᱟᱞᱜᱟᱣᱟᱠᱟᱱ ᱪᱟᱭᱱᱤᱡᱽ',
 				'zh_Hans@alt=long' => 'ᱟᱞᱜᱟᱣᱟᱠᱟᱱ ᱢᱟᱫᱟᱨᱤᱱ ᱪᱟᱭᱱᱤᱡᱽ',
 				'zh_Hant' => 'ᱴᱨᱮᱰᱤᱥᱱᱟᱞ ᱪᱟᱭᱱᱤᱡᱽ',
 				'zh_Hant@alt=long' => 'ᱴᱨᱮᱰᱤᱥᱱᱟᱞ ᱢᱟᱫᱟᱨᱤᱱ ᱪᱟᱭᱱᱤᱡᱽ',

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
			'Arab' => 'ᱟᱨᱵᱤᱠ',
 			'Cyrl' => 'ᱥᱤᱨᱤᱞᱤᱠ',
 			'Deva' => 'ᱫᱮᱣᱟᱱᱟᱜᱟᱨᱤ',
 			'Hans' => 'ᱥᱤᱢᱯᱞᱤᱯᱟᱭᱤᱰ',
 			'Hans@alt=stand-alone' => 'ᱥᱤᱢᱯᱞᱤᱯᱟᱭᱤᱰ ᱦᱟᱱ',
 			'Hant' => 'ᱴᱨᱮᱰᱤᱥᱚᱱ',
 			'Hant@alt=stand-alone' => 'ᱴᱨᱮᱰᱤᱥᱚᱱ ᱦᱟᱱ',
 			'Latn' => 'ᱞᱮᱴᱤᱱ',
 			'Olck' => 'ᱚᱞ ᱪᱤᱠᱤ',
 			'Zxxx' => 'ᱵᱟᱝ ᱚᱞ ᱟᱠᱟᱱ',
 			'Zzzz' => 'ᱵᱟᱝ ᱩᱨᱩᱢ ᱪᱤᱠᱤ',

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
			'BR' => 'ᱵᱨᱟᱡᱤᱞ',
 			'CN' => 'ᱪᱤᱱ',
 			'DE' => 'ᱡᱟᱨᱢᱟᱱᱤ',
 			'FR' => 'ᱯᱷᱨᱟᱱᱥ',
 			'GB' => 'ᱭᱩᱱᱤᱭᱴᱮᱰ ᱠᱤᱝᱰᱚᱢ',
 			'IN' => 'ᱤᱱᱰᱤᱭᱟ',
 			'IT' => 'ᱤᱴᱞᱤ',
 			'JP' => 'ᱡᱟᱯᱟᱱ',
 			'RU' => 'ᱨᱩᱥ',
 			'US' => 'ᱭᱩᱱᱟᱭᱴᱮᱰ ᱮᱥᱴᱮᱴ',
 			'ZZ' => 'ᱵᱟᱝᱩᱨᱩᱢ ᱴᱚᱴᱷᱟ',

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
 				'gregorian' => q{ᱜᱨᱮᱜᱚᱨᱤᱭᱟᱱ ᱠᱟᱞᱮᱱᱰᱟᱨ},
 			},
 			'collation' => {
 				'standard' => q{ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱛᱷᱟᱨ ᱟᱸᱫᱮ},
 			},
 			'numbers' => {
 				'latn' => q{ᱣᱮᱥᱴᱟᱨᱱ ᱮᱞ},
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
			'metric' => q{ᱢᱮᱴᱨᱤᱠ},
 			'UK' => q{ᱭᱩᱠᱮ},
 			'US' => q{ᱭᱩᱮᱥ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ᱯᱟᱹᱨᱥᱤ: {0}',
 			'script' => 'ᱪᱤᱠᱤ/ᱦᱟᱨᱚᱯᱺ {0}',
 			'region' => 'ᱴᱚᱴᱷᱟᱺ {0}',

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
			main => qr{[ᱚ ᱛ ᱜ ᱝ ᱞ ᱟ ᱠ ᱡ ᱢ ᱣ ᱤ ᱥ ᱦ ᱧ ᱨ ᱩ ᱪ ᱫ ᱬ ᱭ ᱮ ᱯ ᱰ ᱱ ᱲ ᱳ ᱴ ᱵ ᱶ ᱷ ᱸ ᱹ ᱺ ᱻ ᱼ ᱽ]},
			numbers => qr{[\- ‑ , . % + 0᱐ 1᱑ 2᱒ 3᱓ 4᱔ 5᱕ 6᱖ 7᱗ 8᱘ 9᱙]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'narrow' => {
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0} dstspn Imp),
						'two' => q({0} dstspn Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0} dstspn Imp),
						'two' => q({0} dstspn Imp),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᱦᱚᱸᱺᱦ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᱵᱟᱝᱺᱵ|no|n)$' }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'olck',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
			'minusSign' => q(-),
			'percentSign' => q(%),
			'plusSign' => q(+),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(ᱵᱨᱟᱡᱤᱞᱤᱭᱟᱱ ᱨᱤᱭᱟᱹᱞ),
				'one' => q(ᱵᱨᱟᱡᱤᱞᱤᱭᱟᱱ ᱨᱤᱭᱟᱹᱞ),
				'other' => q(ᱵᱨᱟᱡᱤᱞᱤᱭᱟᱱ ᱨᱤᱭᱟᱹᱞᱥ),
				'two' => q(ᱵᱨᱟᱡᱤᱞᱤᱭᱟᱱ ᱨᱤᱭᱟᱹᱞᱥ),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(ᱪᱤᱱᱤ ᱭᱩᱣᱟᱱ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ᱭᱩᱨᱚ),
				'one' => q(ᱭᱩᱨᱚ),
				'other' => q(ᱭᱩᱨᱚ),
				'two' => q(ᱭᱩᱨᱚ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ᱵᱨᱤᱴᱤᱥ ᱯᱟᱣᱩᱸᱰ),
				'one' => q(ᱵᱨᱤᱴᱤᱥ ᱯᱟᱣᱩᱸᱰ),
				'other' => q(ᱵᱨᱤᱴᱤᱥ ᱯᱟᱣᱩᱸᱰᱥ),
				'two' => q(ᱵᱨᱤᱴᱤᱥ ᱯᱟᱣᱩᱸᱰᱥ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ᱥᱤᱧᱚᱛ ᱨᱮᱱᱟᱜ ᱴᱟᱠᱟ),
				'one' => q(ᱥᱤᱧᱚᱛ ᱨᱮᱱᱟᱜ ᱴᱟᱠᱟ),
				'other' => q(ᱥᱤᱧᱚᱛ ᱨᱮᱱᱟᱜ ᱴᱟᱠᱟ),
				'two' => q(ᱥᱤᱧᱚᱛ ᱨᱮᱱᱟᱜ ᱴᱟᱠᱟ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ᱡᱟᱯᱟᱱᱤ ᱭᱮᱱ),
				'one' => q(ᱡᱟᱯᱟᱱᱤ ᱭᱮᱱ),
				'other' => q(ᱡᱟᱯᱟᱱᱤ ᱭᱮᱱ),
				'two' => q(ᱡᱟᱯᱟᱱᱤ ᱭᱮᱱ),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ᱨᱩᱥᱤ ᱨᱩᱵᱟᱹᱞ),
				'one' => q(ᱨᱩᱥᱤ ᱨᱩᱵᱟᱹᱞ),
				'other' => q(ᱨᱩᱥᱤ ᱨᱩᱵᱟᱹᱞᱥ),
				'two' => q(ᱨᱩᱥᱤ ᱨᱩᱵᱟᱹᱞᱥ),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ᱭᱩᱮᱥ ᱰᱚᱞᱟᱨ),
				'one' => q(ᱭᱩᱮᱥ ᱰᱚᱞᱟᱨ),
				'other' => q(ᱭᱩᱮᱥ ᱰᱚᱞᱟᱨ),
				'two' => q(ᱭᱩᱮᱥ ᱰᱚᱞᱟᱨ),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ᱵᱟᱝᱩᱨᱩᱢ ᱠᱟᱨᱮᱱᱥᱤ),
				'one' => q(ᱵᱟᱝᱩᱨᱩᱢ ᱠᱟᱨᱮᱱᱥᱤ),
				'other' => q(ᱵᱟᱝᱩᱨᱩᱢ ᱠᱟᱨᱮᱱᱥᱤ),
				'two' => q(ᱵᱟᱝᱩᱨᱩᱢ ᱠᱟᱨᱮᱱᱥᱤ),
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
							'ᱡᱟᱱ',
							'ᱯᱷᱟ',
							'ᱢᱟᱨ',
							'ᱟᱯᱨ',
							'ᱢᱮ',
							'ᱡᱩᱱ',
							'ᱡᱩᱞ',
							'ᱟᱜᱟ',
							'ᱥᱮᱯ',
							'ᱚᱠᱴ',
							'ᱱᱟᱣ',
							'ᱫᱤᱥ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ᱡ',
							'ᱯ',
							'ᱢ',
							'ᱟ',
							'ᱢ',
							'ᱡ',
							'ᱡ',
							'ᱟ',
							'ᱥ',
							'ᱚ',
							'ᱱ',
							'ᱫ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ᱡᱟᱱᱣᱟᱨᱤ',
							'ᱯᱷᱟᱨᱣᱟᱨᱤ',
							'ᱢᱟᱨᱪ',
							'ᱟᱯᱨᱮᱞ',
							'ᱢᱮ',
							'ᱡᱩᱱ',
							'ᱡᱩᱞᱟᱭ',
							'ᱟᱜᱟᱥᱛ',
							'ᱥᱮᱯᱴᱮᱢᱵᱟᱨ',
							'ᱚᱠᱴᱚᱵᱟᱨ',
							'ᱱᱟᱣᱟᱢᱵᱟᱨ',
							'ᱫᱤᱥᱟᱢᱵᱟᱨ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'ᱡᱟᱱ',
							'ᱯᱷᱟ',
							'ᱢᱟᱨ',
							'ᱟᱯᱨ',
							'ᱢᱮ',
							'ᱡᱩᱱ',
							'ᱡᱩᱞ',
							'ᱟᱜᱟ',
							'ᱥᱮᱯ',
							'ᱚᱠᱴ',
							'ᱱᱟᱣ',
							'ᱫᱤᱥ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ᱡ',
							'ᱯ',
							'ᱢ',
							'ᱟ',
							'ᱢ',
							'ᱡ',
							'ᱡ',
							'ᱟ',
							'ᱥ',
							'ᱚ',
							'ᱱ',
							'ᱫ'
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
						mon => 'ᱚᱛ',
						tue => 'ᱵᱟ',
						wed => 'ᱥᱟᱹ',
						thu => 'ᱥᱟᱹᱨ',
						fri => 'ᱡᱟᱹ',
						sat => 'ᱧᱩ',
						sun => 'ᱥᱤᱸ'
					},
					narrow => {
						mon => 'ᱚ',
						tue => 'ᱵ',
						wed => 'ᱥ',
						thu => 'ᱥ',
						fri => 'ᱡ',
						sat => 'ᱧ',
						sun => 'ᱥ'
					},
					wide => {
						mon => 'ᱚᱛᱮ',
						tue => 'ᱵᱟᱞᱮ',
						wed => 'ᱥᱟᱹᱜᱩᱱ',
						thu => 'ᱥᱟᱹᱨᱫᱤ',
						fri => 'ᱡᱟᱹᱨᱩᱢ',
						sat => 'ᱧᱩᱦᱩᱢ',
						sun => 'ᱥᱤᱸᱜᱮ'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'ᱚᱛ',
						tue => 'ᱵᱟ',
						wed => 'ᱥᱟᱹ',
						thu => 'ᱥᱟᱹᱨ',
						fri => 'ᱡᱟᱹ',
						sat => 'ᱧᱩ',
						sun => 'ᱥᱤᱸ'
					},
					narrow => {
						mon => 'ᱚ',
						tue => 'ᱵ',
						wed => 'ᱥ',
						thu => 'ᱥ',
						fri => 'ᱡ',
						sat => 'ᱧ',
						sun => 'ᱥ'
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
					abbreviated => {0 => '᱑ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						1 => '᱒ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						2 => '᱓ᱭᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						3 => '᱔ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ'
					},
					narrow => {0 => '᱑',
						1 => '᱒',
						2 => '᱓',
						3 => '᱔'
					},
					wide => {0 => '᱑ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						1 => '᱒ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						2 => '᱓ᱭᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						3 => '᱔ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ'
					},
				},
				'stand-alone' => {
					narrow => {0 => '᱑',
						1 => '᱒',
						2 => '᱓',
						3 => '᱔'
					},
					wide => {0 => '᱑ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						1 => '᱒ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						2 => '᱓ᱭᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ',
						3 => '᱔ᱟᱜ ᱯᱮ ᱪᱟᱸᱫᱚᱠᱤᱭᱟᱹ'
					},
				},
			},
	} },
);

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'wide' => {
					'am' => q{ᱥᱮᱛᱟᱜ},
					'pm' => q{ᱧᱤᱫᱟᱹ},
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
				'0' => 'ᱥᱮᱨᱢᱟ ᱞᱟᱦᱟ',
				'1' => 'ᱤᱥᱣᱤ'
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
			'full' => q{G y MMMM d, EEEE},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(ᱡᱤᱮᱢᱴᱤ{0}),
		gmtZeroFormat => q(ᱡᱤᱮᱢᱴᱤ),
		regionFormat => q({0} ᱚᱠᱛᱚ),
		regionFormat => q({0} ᱫᱤᱱᱵᱮᱲᱟ ᱚᱠᱛᱚ),
		regionFormat => q({0} ᱮᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ),
		'America_Central' => {
			long => {
				'daylight' => q#ᱛᱟᱱᱟᱞᱟ ᱥᱤᱧᱟᱜ ᱚᱠᱛᱚ#,
				'generic' => q#ᱛᱟᱱᱟᱞᱟ ᱚᱠᱛᱚ#,
				'standard' => q#ᱛᱟᱱᱟᱞᱟ ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ᱤᱥᱴᱟᱨᱱ ᱥᱤᱧᱟᱜ ᱵᱚᱠᱛᱚ#,
				'generic' => q#ᱤᱥᱴᱟᱨᱱ ᱚᱠᱛᱚ#,
				'standard' => q#ᱤᱥᱴᱟᱨᱱ ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ᱢᱟᱩᱱᱴᱮᱱ ᱥᱤᱧᱟᱜ ᱚᱠᱛᱚ#,
				'generic' => q#ᱢᱟᱩᱱᱴᱮᱱ ᱚᱠᱛᱚ#,
				'standard' => q#ᱢᱟᱩᱱᱴᱮᱱ ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#ᱯᱮᱥᱤᱯᱷᱤᱠ ᱥᱤᱧᱟᱜ ᱚᱠᱛᱚ#,
				'generic' => q#ᱯᱮᱥᱤᱯᱷᱤᱠ ᱚᱠᱛᱚ#,
				'standard' => q#ᱯᱮᱥᱤᱯᱷᱤᱠ ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ᱮᱴᱞᱟᱱᱴᱤᱠ ᱥᱤᱧᱟᱜ ᱚᱠᱛᱚ#,
				'generic' => q#ᱮᱴᱞᱟᱱᱴᱤᱠ ᱚᱠᱛᱚ#,
				'standard' => q#ᱮᱴᱞᱟᱱᱴᱤᱠ ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ᱠᱚᱨᱰᱤᱱᱮᱴᱮᱰ ᱭᱩᱱᱤᱣᱟᱨᱥᱟᱞ ᱚᱠᱛᱚ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ᱵᱟᱝ ᱪᱤᱱᱦᱟᱹᱣ ᱵᱟᱡᱟᱨ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ᱥᱮᱱᱴᱨᱟᱞ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱥᱟᱢᱟᱨ ᱚᱠᱛᱚ#,
				'generic' => q#ᱥᱮᱱᱴᱨᱟᱞ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱚᱠᱛᱚ#,
				'standard' => q#ᱥᱮᱱᱴᱨᱟᱞ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ᱤᱥᱴᱟᱨᱱ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱥᱟᱢᱟᱨ ᱚᱠᱛᱚ#,
				'generic' => q#ᱤᱥᱴᱟᱨᱱ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱚᱠᱛᱚ#,
				'standard' => q#ᱤᱥᱴᱟᱨᱱ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ᱣᱮᱥᱴᱟᱨᱱ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱥᱟᱢᱟᱨ ᱚᱠᱛᱚ#,
				'generic' => q#ᱣᱮᱥᱴᱟᱨᱱ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱚᱠᱛᱚ#,
				'standard' => q#ᱣᱮᱥᱴᱟᱨᱱ ᱩᱨᱚᱯᱤᱭᱟᱱ ᱮᱥᱴᱮᱱᱰᱟᱨᱰ ᱚᱠᱛᱚ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ᱜᱨᱤᱱᱣᱤᱪ ᱢᱤᱱ ᱚᱠᱛᱚ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
