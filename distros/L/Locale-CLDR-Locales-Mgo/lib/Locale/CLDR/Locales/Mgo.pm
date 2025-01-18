=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mgo - Package for language Metaʼ

=cut

package Locale::CLDR::Locales::Mgo;
# This file auto generated from Data\common\main\mgo.xml
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
				'mgo' => 'metaʼ',
 				'und' => 'ngam tisɔʼ',

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
			'Latn' => 'ngam ŋwaʼri',
 			'Zxxx' => 'ngam choʼ',
 			'Zzzz' => 'abo ŋwaʼri tisɔʼ',

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
			'CM' => 'Kamalun',
 			'ZZ' => 'aba aben tisɔ̀',

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
 				'gregorian' => q{ngàb mə̀kala},
 			},
 			'numbers' => {
 				'latn' => q{inu},
 			},

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
			auxiliary => qr{[c h l q v x]},
			index => ['A', 'B', '{CH}', 'D', 'E', 'Ə', 'F', 'G', '{GH}', 'I', 'J', 'K', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'W', 'Y', 'Z', 'ʼ'],
			main => qr{[aà b {ch} d eè ə{ə̀} f g {gh} iì j k m n ŋ oò ɔ{ɔ̀} p r s t uù w y z ʼ]},
			punctuation => qr{[, ; \: ! ? . '‘’ "“”]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', '{CH}', 'D', 'E', 'Ə', 'F', 'G', '{GH}', 'I', 'J', 'K', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'W', 'Y', 'Z', 'ʼ'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'short' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:èè|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ideg.|no|n)$' }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'XAF' => {
			display_name => {
				'currency' => q(shirè),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(iku ikap mɔʼɔ),
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
							'mbegtug',
							'imeg àbùbì',
							'imeg mbəŋchubi',
							'iməg ngwə̀t',
							'iməg fog',
							'iməg ichiibɔd',
							'iməg àdùmbə̀ŋ',
							'iməg ichika',
							'iməg kud',
							'iməg tèsiʼe',
							'iməg zò',
							'iməg krizmed'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'iməg mbegtug',
							'imeg àbùbì',
							'imeg mbəŋchubi',
							'iməg ngwə̀t',
							'iməg fog',
							'iməg ichiibɔd',
							'iməg àdùmbə̀ŋ',
							'iməg ichika',
							'iməg kud',
							'iməg tèsiʼe',
							'iməg zò',
							'iməg krizmed'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'M1',
							'A2',
							'M3',
							'N4',
							'F5',
							'I6',
							'A7',
							'I8',
							'K9',
							'10',
							'11',
							'12'
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
					short => {
						mon => 'A2',
						tue => 'A3',
						wed => 'A4',
						thu => 'A5',
						fri => 'A6',
						sat => 'A7',
						sun => 'A1'
					},
					wide => {
						mon => 'Aneg 2',
						tue => 'Aneg 3',
						wed => 'Aneg 4',
						thu => 'Aneg 5',
						fri => 'Aneg 6',
						sat => 'Aneg 7',
						sun => 'Aneg 1'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => '2',
						tue => '3',
						wed => '4',
						thu => '5',
						fri => '6',
						sat => '7',
						sun => '1'
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
			'full' => q{EEEE, G y MMMM dd},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, y MMMM dd},
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

no Moo;

1;

# vim: tabstop=4
