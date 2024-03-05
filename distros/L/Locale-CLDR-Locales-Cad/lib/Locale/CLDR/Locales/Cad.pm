=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Cad - Package for language Caddo

=cut

package Locale::CLDR::Locales::Cad;
# This file auto generated from Data\common\main\cad.xml
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
				'cad' => 'Caddo',

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
			auxiliary => qr{[c f g j l q r v x z]},
			index => ['A', 'B', '{CH}', 'D', 'E', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'S', '{SH}', 'T', '{TS}', 'U', 'W', 'Y'],
			main => qr{[aáà {aː}{áː}{àː} b {ch} {chʼ} d eéè {eː}{éː}{èː} h iíì {iː}{íː}{ìː} k {kʼ} m n oóò {oː}{óː}{òː} p s t {tsʼ} {tʼ} uúù {uː}{úː}{ùː} w y ˀ ʼ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', '{CH}', 'D', 'E', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'S', '{SH}', 'T', '{TS}', 'U', 'W', 'Y'], };
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
						'name' => q(Kaˀisch’áyˀah),
						'other' => q({0} Kaˀisch’áyˀah),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Kaˀisch’áyˀah),
						'other' => q({0} Kaˀisch’áyˀah),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Nish),
						'other' => q(Nish {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Nish),
						'other' => q(Nish {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Wísts’iˀ inikuˀ),
						'other' => q(Wísts’iˀ inikuˀ {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Wísts’iˀ inikuˀ),
						'other' => q(Wísts’iˀ inikuˀ {0}),
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
							'Cháykáhday Haˀimay',
							'Tsahkápbiˀ',
							'Wánit',
							'Háshnihtiˀtiˀ',
							'Háshnih Haˀimay',
							'Háshnihtsiˀ',
							'Násˀahˀatsus',
							'Dahósikah nish',
							'Híisikah nish',
							'Nípbaatiˀtiˀ',
							'Nípbaa Haˀimay',
							'Cháykáhdaytiˀtiˀ'
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
						mon => 'Wísts’i hayashuh',
						tue => 'Bít hayashuh',
						wed => 'Dahó hayashuh',
						thu => 'Hiwí hayashuh',
						fri => 'Dissik’an hayashuh',
						sat => 'Inikuˀtiˀtiˀ',
						sun => 'Inikuˀ'
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
