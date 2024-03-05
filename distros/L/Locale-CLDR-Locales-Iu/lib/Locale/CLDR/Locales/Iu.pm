=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Iu - Package for language Inuktitut

=cut

package Locale::CLDR::Locales::Iu;
# This file auto generated from Data\common\main\iu.xml
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
				'fr' => 'ᐅᐃᒍᐃᕐᒥᐅᖅ',
 				'iu' => 'ᐃᓄᒃᑎᑐᑦ',

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
			'CA' => 'ᑲᓇᑕᒥ',

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
			index => ['ᐃ', 'ᐄ', 'ᐅ', 'ᐆ', 'ᐊ', 'ᐋ', 'ᐱ', 'ᐲ', 'ᐳ', 'ᐴ', 'ᐸ', 'ᐹ', 'ᑎ', 'ᑏ', 'ᑐ', 'ᑑ', 'ᑕ', 'ᑖ', 'ᑦ', 'ᑭ', 'ᑮ', 'ᑯ', 'ᑰ', 'ᑳ', 'ᒃ', 'ᒋ', 'ᒌ', 'ᒍ', 'ᒎ', 'ᒐ', 'ᒑ', 'ᒡ', 'ᒥ', 'ᒦ', 'ᒨ', 'ᒪ', 'ᒫ', 'ᒻ', 'ᓂ', 'ᓃ', 'ᓄ', 'ᓅ', 'ᓇ', 'ᓈ', 'ᓐ', 'ᓖ', 'ᓗ', 'ᓘ', 'ᓚ', 'ᓛ', 'ᓪ', 'ᓯ', 'ᓰ', 'ᓱ', 'ᓲ', 'ᓴ', 'ᔅ', 'ᔨ', 'ᔩ', 'ᔪ', 'ᔫ', 'ᔭ', 'ᔮ', 'ᔾ', 'ᕆ', 'ᕇ', 'ᕈ', 'ᕋ', 'ᕌ', 'ᕐ', 'ᕕ', 'ᕖ', 'ᕗ', 'ᕘ', 'ᕙ', 'ᕚ', 'ᕝ', 'ᕿ', 'ᖁ', 'ᖂ', 'ᖃ', 'ᖅ', 'ᖏ', 'ᖑ', 'ᖒ', 'ᖓ', 'ᖔ', 'ᖕ', 'ᙱ', 'ᙳ', 'ᙴ', 'ᙵ', 'ᙶ', 'ᖖ', 'ᖠ', 'ᖡ', 'ᖢ', 'ᖣ', 'ᖤ', 'ᖥ'],
			main => qr{[ᐃ ᐄ ᐅ ᐆ ᐊ ᐋ ᐱ ᐲ ᐳ ᐴ ᐸ ᐹ ᑉ ᑎ ᑏ ᑐ ᑑ ᑕ ᑖ ᑦ ᑭ ᑮ ᑯ ᑰ ᑲ ᑳ ᒃ ᒋ ᒌ ᒍ ᒎ ᒐ ᒑ ᒡ ᒥ ᒦ ᒧ ᒨ ᒪ ᒫ ᒻ ᓂ ᓃ ᓄ ᓅ ᓇ ᓈ ᓐ ᓕ ᓖ ᓗ ᓘ ᓚ ᓛ ᓪ ᓯ ᓰ ᓱ ᓲ ᓴ ᓵ ᔅ ᔨ ᔩ ᔪ ᔫ ᔭ ᔮ ᔾ ᕆ ᕇ ᕈ ᕉ ᕋ ᕌ ᕐ ᕕ ᕖ ᕗ ᕘ ᕙ ᕚ ᕝ ᕿ ᖀ ᖁ ᖂ ᖃ ᖅ ᖏ ᖑ ᖒ ᖓ ᖔ ᖕ ᙱ ᙲ ᙳ ᙴ ᙵ ᙶ ᖖ ᖠ ᖡ ᖢ ᖣ ᖤ ᖥ ᖦ]},
		};
	},
EOT
: sub {
		return { index => ['ᐃ', 'ᐄ', 'ᐅ', 'ᐆ', 'ᐊ', 'ᐋ', 'ᐱ', 'ᐲ', 'ᐳ', 'ᐴ', 'ᐸ', 'ᐹ', 'ᑎ', 'ᑏ', 'ᑐ', 'ᑑ', 'ᑕ', 'ᑖ', 'ᑦ', 'ᑭ', 'ᑮ', 'ᑯ', 'ᑰ', 'ᑳ', 'ᒃ', 'ᒋ', 'ᒌ', 'ᒍ', 'ᒎ', 'ᒐ', 'ᒑ', 'ᒡ', 'ᒥ', 'ᒦ', 'ᒨ', 'ᒪ', 'ᒫ', 'ᒻ', 'ᓂ', 'ᓃ', 'ᓄ', 'ᓅ', 'ᓇ', 'ᓈ', 'ᓐ', 'ᓖ', 'ᓗ', 'ᓘ', 'ᓚ', 'ᓛ', 'ᓪ', 'ᓯ', 'ᓰ', 'ᓱ', 'ᓲ', 'ᓴ', 'ᔅ', 'ᔨ', 'ᔩ', 'ᔪ', 'ᔫ', 'ᔭ', 'ᔮ', 'ᔾ', 'ᕆ', 'ᕇ', 'ᕈ', 'ᕋ', 'ᕌ', 'ᕐ', 'ᕕ', 'ᕖ', 'ᕗ', 'ᕘ', 'ᕙ', 'ᕚ', 'ᕝ', 'ᕿ', 'ᖁ', 'ᖂ', 'ᖃ', 'ᖅ', 'ᖏ', 'ᖑ', 'ᖒ', 'ᖓ', 'ᖔ', 'ᖕ', 'ᙱ', 'ᙳ', 'ᙴ', 'ᙵ', 'ᙶ', 'ᖖ', 'ᖠ', 'ᖡ', 'ᖢ', 'ᖣ', 'ᖤ', 'ᖥ'], };
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
							'ᔭᓐᓄᐊᓕ',
							'ᕕᕝᕗᐊᓕ',
							'ᒫᑦᓯ',
							'ᐊᐃᑉᐳᓗ',
							'ᒪᐃ',
							'ᔫᓂ',
							'ᔪᓚᐃ',
							'ᐊᐅᒡᒍᓯ',
							'ᓯᑎᐱᕆ',
							'ᐆᑦᑑᕝᕙ',
							'ᓄᕕᐱᕆ',
							'ᑎᓯᐱᕆ'
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
						mon => 'ᓇᒡᒐᔾᔭᐅ',
						tue => 'ᓇᒡᒐᔾᔭᐅᓕᖅᑭ',
						wed => 'ᐱᖓᑦᓯᖅ',
						thu => 'ᓯᑕᒻᒥᖅ',
						fri => 'ᑕᓪᓕᒻᒥᐅᑦ',
						sat => 'ᓈᑦᓰᖑᔭᓛᕐᓂᐊᖅ',
						sun => 'ᓈᑦᑏᖑᔭᖅ'
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
					'am' => q{am},
					'pm' => q{pm},
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
			'short' => q{MM/dd/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{MM/dd/y},
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
		'generic' => {
			Ed => q{E, d},
			Gy => q{y G},
			MEd => q{E, MM/dd},
			MMMEd => q{E, MMM d},
			Md => q{MM/dd},
			y => q{y},
			yM => q{MM/y},
			yMEd => q{E, MM/dd/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d, y},
			yMd => q{MM/dd/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E, d},
			Gy => q{y G},
			MEd => q{E, MM/dd},
			MMMEd => q{E, MMM d},
			Md => q{MM/dd},
			yM => q{MM/y},
			yMEd => q{E, MM/dd/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d, y},
			yMd => q{MM/dd/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
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
