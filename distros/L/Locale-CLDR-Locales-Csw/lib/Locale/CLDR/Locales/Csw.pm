=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Csw - Package for language Swampy Cree

=cut

package Locale::CLDR::Locales::Csw;
# This file auto generated from Data\common\main\csw.xml
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
				'csw' => 'ᓀᐦᐃᓇᐍᐏᐣ',
 				'en' => 'ᐊᑲᓇᓯᒧᐏᐣ',
 				'en_CA' => 'ᒧᓀᐅ ᐏᓂᓀᐤ ᐋᑲᓇᓯᓄᒯᐣ',

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
			'Cans' => 'ᓀᐦᐃᔭᐊᐧᓯᓇᐦᐃᑳᑌᐤ',

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
			'CA' => 'ᑲᓇᑕ',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ᐊᔭᒥᐏᐣ: {0}',
 			'script' => 'ᒪᓯᓇᐦᐃᑫᐃᐧᐣ: {0}',
 			'region' => 'ᓀᐦᐃᔭᐊᐧᐢᑭᕀ: {0}',

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
			main => qr{[ᐁ ᐃ ᐄ ᐅ ᐆ ᐊ ᐋ ᐍ ᐏ ᐑ ᐓ ᐕ ᐘ ᐚ ᐟ ᐠ ᐢ ᐣ ᐤ ᐦ ᐨ ᐩ ᐯ ᐱ ᐲ ᐳ ᐴ ᐸ ᐹ ᐻ ᐽ ᐿ ᑁ ᑃ ᑅ ᑇ ᑊ ᑌ ᑎ ᑏ ᑐ ᑑ ᑕ ᑖ ᑘ ᑚ ᑜ ᑞ ᑠ ᑢ ᑤ ᑫ ᑭ ᑮ ᑯ ᑰ ᑲ ᑳ ᑵ ᑷ ᑹ ᑻ ᑽ ᑿ ᒁ ᒉ ᒋ ᒌ ᒍ ᒎ ᒐ ᒑ ᒓ ᒕ ᒗ ᒙ ᒛ ᒝ ᒟ ᒣ ᒥ ᒦ ᒧ ᒨ ᒪ ᒫ ᒭ ᒯ ᒱ ᒳ ᒵ ᒷ ᒹ ᒼ ᓀ ᓂ ᓃ ᓄ ᓅ ᓇ ᓈ ᓊ ᓌ ᓎ ᓭ ᓯ ᓰ ᓱ ᓲ ᓴ ᓵ ᓷ ᓹ ᓻ ᓽ ᓿ ᔁ ᔃ ᔦ ᔨ ᔩ ᔪ ᔫ ᔭ ᔮ ᔰ ᔲ ᔴ ᔶ ᔸ ᔺ ᔼ]},
		};
	},
EOT
: sub {
		return {};
},
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
							'ᑭᓴᐱᓯᒼ',
							'ᒥᑭᓯᐏᐱᓯᒼ',
							'ᓂᐢᑭᐱᓯᒼ',
							'ᐊᓂᑭᐱᓯᒼ',
							'ᓴᑭᐸᑲᐏᐱᓯᒼ',
							'ᐸᐢᑲᐍᐦᐅᐱᓯᒼ',
							'ᐸᐢᑯᐏᐱᓯᒼ',
							'ᐅᐸᐦᐅᐏᐱᓯᒼ',
							'ᑕᐦᑿᑭᐱᓯᒼ',
							'ᐱᒪᐦᐊᒧᐏᐱᓯᒼ',
							'ᐊᑿᑎᓄᐏᐱᓯᒼ',
							'ᐸᐘᐢᒐᑲᓂᓹᐱᓯᒼ'
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
					wide => {
						mon => 'ᐯᔭᐠᑭᓯᑲᐤ',
						tue => 'ᓂᓱᑭᓯᑲᐤ',
						wed => 'ᐊᐱᐦᑕᐘᐣ',
						thu => 'ᓀᐓᑭᓯᑲᐤ',
						fri => 'ᓂᔭᓇᓄᑭᓯᑲᐤ',
						sat => 'ᒪᑎᓄᐏᑭᓯᑲᐤ',
						sun => 'ᐊᔭᒥᐦᐁᐃ ᑭᓯᑲᐤ'
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} ᐁᐃᐢᐸᓂᐟ),
		regionFormat => q({0} ᑮᓯᑳᐤ ᐁᐃᐢᐸᓂᐟ),
		regionFormat => q({0} ᐯᔭᑯᐦᑕᐃᐧᐣ ᐁᐃᐢᐸᓂᐟ),
		'GMT' => {
			long => {
				'standard' => q#ᕒᐁᐁᐣᐤᐏᐨ ᒣᐊᐣ ᐁᐃᐢᐸᓂᐟ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
