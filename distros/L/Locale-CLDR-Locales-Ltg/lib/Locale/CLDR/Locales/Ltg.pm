=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ltg - Package for language Latgalian

=cut

package Locale::CLDR::Locales::Ltg;
# This file auto generated from Data\common\main\ltg.xml
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
				'en' => 'angļu',
 				'ltg' => 'latgalīšu',
 				'lv' => 'latvīšu',

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
			'LV' => 'Latveja',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Volūda: {0}',
 			'script' => 'Raksteiba: {0}',
 			'region' => 'Regions: {0}',

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
			auxiliary => qr{[q ŗ w x]},
			main => qr{[aā b cč d eē f gģ h iī j kķ lļ m nņ oō p r sš t uū v y zž]},
			numbers => qr{[\- ‑ , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’‚ "“”„ ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'EUR' => {
			display_name => {
				'currency' => q(eiro),
				'other' => q(eiro),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Latvejis lats),
				'other' => q(Latvejis lati),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvejis rublis),
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
					wide => {
						nonleap => [
							'janvars',
							'februars',
							'marts',
							'apreļs',
							'majs',
							'juņs',
							'juļs',
							'augusts',
							'septembris',
							'oktobris',
							'novembris',
							'decembris'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'janvars',
							'februars',
							'marts',
							'apreļs',
							'majs',
							'juņs',
							'juļs',
							'augusts',
							'septembris',
							'oktobris',
							'novembris',
							'decembris'
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
						mon => 'pyrmūdīne',
						tue => 'ūtardīne',
						wed => 'trešdīne',
						thu => 'catūrtdīne',
						fri => 'pīktdīne',
						sat => 'sastdīne',
						sun => 'svātdīne'
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
					wide => {0 => '1. catūrksnis',
						1 => '2. catūrksnis',
						2 => '3. catūrksnis',
						3 => '4. catūrksnis'
					},
				},
				'stand-alone' => {
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
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
					'am' => q{prīškpušdīnē},
					'pm' => q{piecpušdīnē},
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
				'0' => 'p.m.e.',
				'1' => 'm.e.'
			},
			wide => {
				'0' => 'pyrma myusu erys',
				'1' => 'myusu erā'
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
		'gregorian' => {
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			yMMMd => q{y. 'g'. d. MMM},
			yMd => q{d.MM.y.},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Laika jūsla: {0}),
		regionFormat => q({0}: vosorys laiks),
		regionFormat => q({0}: standarta laiks),
		'GMT' => {
			long => {
				'standard' => q#Griničys laiks#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
