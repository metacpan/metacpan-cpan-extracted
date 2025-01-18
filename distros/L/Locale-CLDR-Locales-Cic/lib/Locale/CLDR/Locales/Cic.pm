=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Cic - Package for language Chickasaw

=cut

package Locale::CLDR::Locales::Cic;
# This file auto generated from Data\common\main\cic.xml
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
				'cic' => 'Chikashshanompaʼ',

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

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[á{á̱} c d e g í{í̱} j ó{ó̱} q r u v x z]},
			index => ['A{A̱}', 'B', '{CH}', 'D', 'E', 'F', 'H', 'I{I̱}', 'K', 'L', '{LH}', 'M', 'N', 'O{O̱}', 'P', 'S', '{SH}', 'T', 'V', 'W', 'Y'],
			main => qr{[a{a̱} b {ch} f h i{i̱} k l {lh} m n {ng} o{o̱} p s {sh} t w y ʼ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A{A̱}', 'B', '{CH}', 'D', 'E', 'F', 'H', 'I{I̱}', 'K', 'L', '{LH}', 'M', 'N', 'O{O̱}', 'P', 'S', '{SH}', 'T', 'V', 'W', 'Y'], };
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
						'name' => q(Nittak),
						'other' => q({0} Nittak),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Nittak),
						'other' => q({0} Nittak),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Hashiʼ kanalli chaffaʼ),
						'other' => q(Hashiʼ kanalli chaffaʼ {0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Hashiʼ kanalli chaffaʼ),
						'other' => q(Hashiʼ kanalli chaffaʼ {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Hashiʼ kanallloshiʼ),
						'other' => q(Hashiʼ kanallloshiʼ {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Hashiʼ kanallloshiʼ),
						'other' => q(Hashiʼ kanallloshiʼ {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Hashiʼ alhpisaʼ),
						'other' => q(Hashiʼ alhpisaʼ {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Hashiʼ alhpisaʼ),
						'other' => q(Hashiʼ alhpisaʼ {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Nittak hollo ittataklaʼ),
						'other' => q(Nittak hollo ittataklaʼ {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Nittak hollo ittataklaʼ),
						'other' => q(Nittak hollo ittataklaʼ {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Afammi),
						'other' => q(Afammi {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Afammi),
						'other' => q(Afammi {0}),
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
					wide => {
						nonleap => [
							'Hashiʼ Ammoʼnaʼ',
							'Hashiʼ Atokloʼ',
							'Hashiʼ Atochchíʼnaʼ',
							'Iiplal',
							'Mih',
							'Choon',
							'Choola',
							'Akaas',
							'Siptimpaʼ',
							'Aaktopaʼ',
							'Nofimpaʼ',
							'Tiisimpaʼ'
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
						mon => 'Mantiʼ',
						tue => 'Chostiʼ',
						wed => 'Winstiʼ',
						thu => 'Soistiʼ',
						fri => 'Nannalhchifaʼ Nittak',
						sat => 'Nittak Holloʼ Nakfish',
						sun => 'Nittak Holloʼ'
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
