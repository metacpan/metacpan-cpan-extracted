=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mus - Package for language Muscogee

=cut

package Locale::CLDR::Locales::Mus;
# This file auto generated from Data\common\main\mus.xml
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
				'mus' => 'Mvskoke',

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
			auxiliary => qr{[b d ē g j q z]},
			index => ['A', 'C', 'E', 'F', 'H', 'I', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y'],
			main => qr{[a c e f h i k l m n o p r s t u v w y ʼ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'C', 'E', 'F', 'H', 'I', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y'], };
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
						'name' => q(Nettv),
						'other' => q({0} Nettv),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Nettv),
						'other' => q({0} Nettv),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Hvse-vkērkv),
						'other' => q(Hvse-vkērkv {0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Hvse-vkērkv),
						'other' => q(Hvse-vkērkv {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Hvse),
						'other' => q(Hvse {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Hvse),
						'other' => q(Hvse {0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Lvplvpkuce),
						'other' => q(Lvplvpkuce {0}),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Lvplvpkuce),
						'other' => q(Lvplvpkuce {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Nettv-cako),
						'other' => q(Nettv-cako {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Nettv-cako),
						'other' => q(Nettv-cako {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Ohrolopē),
						'other' => q(Ohrolopē {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Ohrolopē),
						'other' => q(Ohrolopē {0}),
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
							'Rvfo Cuse',
							'Hotvle Hvse',
							'Tasahcuce',
							'Tasahce Rakko',
							'Ke Hvse',
							'Kvco Hvse',
							'Hiyuce',
							'Hiyo Rakko',
							'Otowoskuce',
							'Otowoskv Rakko',
							'Ehole',
							'Rvfo Rakko'
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
						mon => 'Enhvteceskv',
						tue => 'Enhvteceskv Enhvyvtke',
						wed => 'Ennvrkvpv',
						thu => 'Ennvrkvpv Enhvyvtke',
						fri => 'Nak Okkoskv Nettv',
						sat => 'Nettv Cakcuse',
						sun => 'Nettv Cako'
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
