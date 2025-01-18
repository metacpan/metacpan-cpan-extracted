=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Cch - Package for language Atsam

=cut

package Locale::CLDR::Locales::Cch;
# This file auto generated from Data\common\main\cch.xml
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
				'cch' => 'Atsam',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'ʼ'],
			main => qr{[a{a̱} b c {ch} d {dy} e f g{g̱} {gb} {gw} {gy} h {hy} i j kḵ {kp} {kw} l {ly} m nṉ {ny} o p {ph} {py} r {ry} s {sh} t u v w {wh} y{y̱} z ʼ]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'ʼ'], };
},
);


has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(Aman),
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
							'Dyon',
							'Baa',
							'Atat',
							'Anas',
							'Atyo',
							'Achi',
							'Atar',
							'Awur',
							'Shad',
							'Shak',
							'Naba',
							'Nata'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Pen Dyon',
							'Pen Baʼa',
							'Pen Atat',
							'Pen Anas',
							'Pen Atyon',
							'Pen Achirim',
							'Pen Atariba',
							'Pen Awurr',
							'Pen Shadon',
							'Pen Shakur',
							'Pen Kur Naba',
							'Pen Kur Natat'
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
						mon => 'Tung',
						tue => 'Gitung',
						wed => 'Tsan',
						thu => 'Nas',
						fri => 'Nat',
						sat => 'Chir',
						sun => 'Yok'
					},
					wide => {
						mon => 'Wai Tunga',
						tue => 'Toki Gitung',
						wed => 'Tsam Kasuwa',
						thu => 'Wai Na Nas',
						fri => 'Wai Na Tiyon',
						sat => 'Wai Na Chirim',
						sun => 'Wai Yoka Bawai'
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
				'0' => 'GM',
				'1' => 'M'
			},
			wide => {
				'0' => 'Gabanin Miladi',
				'1' => 'Miladi'
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
			'full' => q{EEEE, G y MMMM dd},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG yy/MM/dd},
		},
		'gregorian' => {
			'full' => q{EEEE, y MMMM dd},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{yy/MM/dd},
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
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
