=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Csw - Package for language Swampy Cree

=cut

package Locale::CLDR::Locales::Csw;
# This file auto generated from Data\common\main\csw.xml
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
				'chr' => 'ᒉᕑᐅᑫᕀ',
 				'csw' => 'ᓀᐦᐃᓇᐍᐏᐣ',
 				'en' => 'ᐊᑲᓈᓰᒧᐏᐣ',
 				'en_AU' => 'ᐊᑲᓈᓰᒧᐏᐣ (AU)',
 				'en_CA' => 'ᐊᑲᓈᓰᒧᐏᐣ (ᑳᓇᑕ)',
 				'en_GB' => 'ᐊᑲᓈᓰᒧᐏᐣ (GB)',
 				'en_US' => 'ᐊᑲᓈᓰᒧᐏᐣ (US)',
 				'fr' => 'ᐹᕽᐘᔦᓰᒧᐏᐣ',
 				'fr_CA' => 'ᐹᕽᐘᔦᓰᒧᐏᐣ (ᑳᓇᑕ)',
 				'fr_CH' => 'ᐹᕽᐘᔦᓰᒧᐏᐣ (CH)',
 				'he' => 'ᐦᐄᑊᕑᐅᐤ',
 				'mul' => 'ᒥᐦᒉᐟ ᐊᔭᒧᐏᓇ',
 				'und' => 'ᓇᒨᓇ ᐃᐦᑕᐟᐘᐣ ᐊᔭᒧᐏᐣ',

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
			'Cans' => 'ᓀᐦᐃᔭᐘᓯᓇᐦᐃᑳᑌᐤ',
 			'Cher' => 'ᒉᕑᐅᑫᕀ',
 			'Latn' => 'ᐋᑲᓈᓰᒨᐏᐣ',

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
			'001' => 'ᐊᐢᑭᕀ',
 			'003' => 'ᒥᐦᑭᓇᕽ ᒥᓂᐢᑎᐠ',
 			'005' => 'ᓵᐘᓄᕽ ᒥᐦᑭᓇᕽ ᒥᓂᐢᑎᐠ',
 			'013' => 'ᐋᐱᐦᑕᐤ ᒥᐦᑭᓇᕽ ᒥᓂᐢᑎᐠ',
 			'021' => 'ᑮᐍᑎᓄᕽ ᒥᐦᑭᓇᕽ ᒥᓂᐢᑎᐠ',
 			'CA' => 'ᑳᓇᑕ',
 			'EU' => 'ᐊᑳᒪᐢᑮᔭ',
 			'EZ' => 'ᐊᑳᒪᐢᑮᕽ',
 			'UN' => 'ᒫᒫᐏ ᐊᐢᑮᔭ',
 			'US' => 'ᑭᐦᒋ ᒨᑯᒫᓂᕽ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'ᐲᓯᒧᐊᓯᓇᐦᐃᑲᐣ',

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
 			'script' => 'ᒪᓯᓇᐦᐃᑫᐏᐣ: {0}',
 			'region' => 'ᓀᐦᐃᔭᐘᐣᑭᕀ: {0}',

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
			auxiliary => qr{[ᔐ ᔑ ᔒ ᔓ ᔔ ᔕ ᔖ]},
			main => qr{[ᐁ ᐃ ᐄ ᐅ ᐆ ᐊ ᐋ ᐍ ᐏ ᐑ ᐓ ᐕ ᐘ ᐚ ᐟ ᐠ ᐢ ᐣ ᐤ ᐦ ᐨ ᐯ ᐱ ᐲ ᐳ ᐴ ᐸ ᐹ ᑊ ᑌ ᑎ ᑏ ᑐ ᑑ ᑕ ᑖ ᑫ ᑭ ᑮ ᑯ ᑰ ᑲ ᑳ ᒉ ᒋ ᒌ ᒍ ᒎ ᒐ ᒑ ᒣ ᒥ ᒦ ᒧ ᒨ ᒪ ᒫ ᒼ ᓀ ᓂ ᓃ ᓄ ᓅ ᓇ ᓈ ᓓ ᓕ ᓖ ᓗ ᓘ ᓚ ᓛ ᓫ ᓭ ᓯ ᓰ ᓱ ᓲ ᓴ ᓵ ᔦ ᔨ ᔩ ᔪ ᔫ ᔭ ᔮ ᕀ ᕃ ᕆ ᕇ ᕈ ᕉ ᕋ ᕌ ᕑ ᕽ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … ᙮ '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᐁᐦᐁ|ᐁ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᓇᒨᓇ|ᓇ|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				2 => q({0} ᐊᐠᐘ {1}),
		} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'CAD' => {
			display_name => {
				'currency' => q(ᑲᓀᑎᔭᐣ ᐯᔭᐠᐚᐱᐢᐠ),
				'one' => q(ᑲᓀᑎᔭᐣ ᐯᔭᐠᐚᐱᐢᐠ),
				'other' => q(ᑲᓀᑎᔭᐣ ᐯᔭᐠᐚᐱᐢᐠᐘᐠ),
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
							'ᐅᒉᒥᑮᓯᑳᐏᐲᓯᒼ',
							'ᐸᐚᐦᒐᑭᓇᓰᐢ',
							'ᒥᑭᓯᐏᐲᓯᒼ',
							'ᓂᐢᑭᐲᓯᒼ',
							'ᐊᓃᑭᐲᓯᒼ',
							'ᐚᐏᐲᓯᒼ',
							'ᐹᐢᑲᐦᐋᐏᐲᓯᒼ',
							'ᐅᐸᐦᐅᐏᐲᓯᒼ',
							'ᓄᒌᑐᐏᐲᓯᒼ',
							'ᐱᓈᐢᑯᐏᐲᓯᒼ',
							'ᐋᕽᐘᑎᓄᐏᐲᓯᒼ',
							'ᒪᑯᓭᑮᓭᑳᐏᐲᓯᒼ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ᐅᒉᒥᑮᓯᑳᐏᐲᓯᒼ',
							'ᐸᐚᐦᒐᑭᓇᓰᐢ',
							'ᒥᑭᓯᐏᐲᓯᒼ',
							'ᓂᐢᑭᐲᓯᒼ',
							'ᐊᓃᑭᐲᓯᒼ',
							'ᐚᐏᐲᓯᒼ',
							'ᐹᐢᑲᐦᐋᐏᐲᓯᒼ',
							'ᐅᐸᐦᐅᐏᐲᓯᒼ',
							'ᓄᒌᑐᐏᐲᓯᒼ',
							'ᐱᓈᐢᑯᐏᐲᓯᒼ',
							'ᐋᕽᐘᑎᓄᐏᐲᓯᒼ',
							'ᒪᑯᓭᑮᓭᑳᐏᐲᓯᒼ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'ᐅᒉᒥᑮᓯᑳᐏᐲᓯᒼ',
							'ᐸᐚᐦᒐᑭᓇᓰᐢ',
							'ᒥᑭᓯᐏᐲᓯᒼ',
							'ᓂᐢᑭᐲᓯᒼ',
							'ᐊᓃᑭᐲᓯᒼ',
							'ᐚᐏᐲᓯᒼ',
							'ᐹᐢᑲᐦᐋᐏᐲᓯᒼ',
							'ᐅᐸᐦᐅᐏᐲᓯᒼ',
							'ᓄᒌᑐᐏᐲᓯᒼ',
							'ᐱᓈᐢᑯᐏᐲᓯᒼ',
							'ᐋᕽᐘᑎᓄᐏᐲᓯᒼ',
							'ᒪᑯᓭᑮᓭᑳᐏᐲᓯᒼ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ᐅᒉᒥᑮᓯᑳᐏᐲᓯᒼ',
							'ᐸᐚᐦᒐᑭᓇᓰᐢ',
							'ᒥᑭᓯᐏᐲᓯᒼ',
							'ᓂᐢᑭᐲᓯᒼ',
							'ᐊᓃᑭᐲᓯᒼ',
							'ᐚᐏᐲᓯᒼ',
							'ᐹᐢᑲᐦᐋᐏᐲᓯᒼ',
							'ᐅᐸᐦᐅᐏᐲᓯᒼ',
							'ᓄᒌᑐᐏᐲᓯᒼ',
							'ᐱᓈᐢᑯᐏᐲᓯᒼ',
							'ᐋᕽᐘᑎᓄᐏᐲᓯᒼ',
							'ᒪᑯᓭᑮᓭᑳᐏᐲᓯᒼ'
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
						mon => 'ᐴᓂ ᐊᔭᒥᐦᐁᑮᓯᑳᐤ',
						tue => 'ᓃᓱᑮᓯᑳᐤ',
						wed => 'ᐋᐱᐦᑕᐘᐣ',
						thu => 'ᐴᓂᐋᐱᐦᑕᐘᐣ',
						fri => 'ᑫᑳᐨ ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sat => 'ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sun => 'ᐊᔭᒥᐦᐁᑮᓯᑳᐤ'
					},
					narrow => {
						mon => 'ᐴ',
						tue => 'ᓃ',
						wed => 'ᐋ',
						thu => 'ᐴ',
						fri => 'ᑫ',
						sat => 'ᒫ',
						sun => 'ᐊ'
					},
					short => {
						mon => 'ᐴᓂ ᐊᔭᒥᐦᐁᑮᓯᑳᐤ',
						tue => 'ᓃᓱᑮᓯᑳᐤ',
						wed => 'ᐋᐱᐦᑕᐘᐣ',
						thu => 'ᐴᓂᐋᐱᐦᑕᐘᐣ',
						fri => 'ᑫᑳᐨ ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sat => 'ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sun => 'ᐊᔭᒥᐦᐁᑮᓯᑳᐤ'
					},
					wide => {
						mon => 'ᐴᓂ ᐊᔭᒥᐦᐁᑮᓯᑳᐤ',
						tue => 'ᓃᓱᑮᓯᑳᐤ',
						wed => 'ᐋᐱᐦᑕᐘᐣ',
						thu => 'ᐴᓂᐋᐱᐦᑕᐘᐣ',
						fri => 'ᑫᑳᐨ ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sat => 'ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sun => 'ᐊᔭᒥᐦᐁᑮᓯᑳᐤ'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'ᐴᓂ ᐊᔭᒥᐦᐁᑮᓯᑳᐤ',
						tue => 'ᓃᓱᑮᓯᑳᐤ',
						wed => 'ᐋᐱᐦᑕᐘᐣ',
						thu => 'ᐴᓂᐋᐱᐦᑕᐘᐣ',
						fri => 'ᑫᑳᐨ ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sat => 'ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sun => 'ᐊᔭᒥᐦᐁᑮᓯᑳᐤ'
					},
					narrow => {
						mon => 'ᐴ',
						tue => 'ᓃ',
						wed => 'ᐋ',
						thu => 'ᐴ',
						fri => 'ᑫ',
						sat => 'ᒫ',
						sun => 'ᐊ'
					},
					short => {
						mon => 'ᐴᓂ ᐊᔭᒥᐦᐁᑮᓯᑳᐤ',
						tue => 'ᓃᓱᑮᓯᑳᐤ',
						wed => 'ᐋᐱᐦᑕᐘᐣ',
						thu => 'ᐴᓂᐋᐱᐦᑕᐘᐣ',
						fri => 'ᑫᑳᐨ ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sat => 'ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sun => 'ᐊᔭᒥᐦᐁᑮᓯᑳᐤ'
					},
					wide => {
						mon => 'ᐴᓂ ᐊᔭᒥᐦᐁᑮᓯᑳᐤ',
						tue => 'ᓃᓱᑮᓯᑳᐤ',
						wed => 'ᐋᐱᐦᑕᐘᐣ',
						thu => 'ᐴᓂᐋᐱᐦᑕᐘᐣ',
						fri => 'ᑫᑳᐨ ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sat => 'ᒫᑎᓇᐍᑮᓯᑳᐤ',
						sun => 'ᐊᔭᒥᐦᐁᑮᓯᑳᐤ'
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
				'abbreviated' => {
					'am' => q{ᐊᒼ},
					'pm' => q{ᐲᒼ},
				},
				'narrow' => {
					'am' => q{ᐊᒼ},
					'pm' => q{ᐲᒼ},
				},
				'wide' => {
					'am' => q{ᐁᒼ},
					'pm' => q{ᐲᒼ},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ᐊᒼ},
					'pm' => q{ᐲᒼ},
				},
				'narrow' => {
					'am' => q{ᐊᒼ},
					'pm' => q{ᐲᒼ},
				},
				'wide' => {
					'am' => q{ᐊᒼ},
					'pm' => q{ᐲᒼ},
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
			'full' => q{y MMMM d, EEEE},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		regionFormat => q({0} ᐁᐃᐢᐸᓂᐠ),
		regionFormat => q({0} ᑮᓯᑳᐤ ᐁᐃᐢᐸᓂᐠ),
		regionFormat => q({0} ᐯᔭᑯᐦᑖᐏᐣ ᐁᐃᐢᐸᓂᐠ),
		'America/Coral_Harbour' => {
			exemplarCity => q#ᐊᑎᐦᑯᑲᐣ#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ᐁᐟᒪᐣᑐᐣ#,
		},
		'America/Inuvik' => {
			exemplarCity => q#ᐃᓄᐱᐠ#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ᐃᑳᓫᐅᐃᐟ#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#ᓴᐢᑳᐟᒉᐘᐣ#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#ᐑᓂᐯᐠ#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#ᓇᒨᓇ ᑭᐢᑫᓂᑖᑿᐣ ᐃᐦᑖᐏᐣ#,
		},
		'GMT' => {
			long => {
				'standard' => q#ᐠᕑᐁᓂᐨ ᐯᔭᑯᐦᑖᐏᐣ ᐁᐃᐢᐸᓂᐠ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
