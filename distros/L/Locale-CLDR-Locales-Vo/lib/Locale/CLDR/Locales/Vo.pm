=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Vo - Package for language Volapük

=cut

package Locale::CLDR::Locales::Vo;
# This file auto generated from Data\common\main\vo.xml
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
				'de' => 'Deutänapük',
 				'en' => 'Linglänapük',
 				'eo' => 'Sperantapük',
 				'es' => 'Spanyänapük',
 				'fr' => 'Fransänapük',
 				'it' => 'Litaliyänapük',
 				'ja' => 'Yapänapük',
 				'pt' => 'Portugänapük',
 				'ru' => 'Rusänapük',
 				'vo' => 'Volapük',
 				'zh' => 'Tsyinänapük',

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
			'BR' => 'Brasilän',
 			'CN' => 'Tsyinän',
 			'DE' => 'Deutän',
 			'ES' => 'Spanyän',
 			'FR' => 'Fransän',
 			'GB' => 'Regän Pebalöl',
 			'GE' => 'Grusiyän',
 			'GR' => 'Grikän',
 			'IN' => 'Lindän',
 			'IT' => 'Litaliyän',
 			'JP' => 'Yapän',
 			'MX' => 'Mäxikän',
 			'NR' => 'Naureän',
 			'PT' => 'Portugän',
 			'PW' => 'Palauäns',
 			'RU' => 'Rusän',
 			'US' => 'Lamerikän',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Pük: {0}',
 			'region' => 'Topäd: {0}',

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
			auxiliary => qr{[q w]},
			index => ['A', 'Ä', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'T', 'U', 'Ü', 'V', 'X', 'Y', 'Z'],
			main => qr{[a ä b c d e f g h i j k l m n o ö p r s t u ü v x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Ä', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'T', 'U', 'Ü', 'V', 'X', 'Y', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'initial' => '… {0}',
			'medial' => '{0} … {1}',
		};
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
						'name' => q(dels),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dels),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(muls),
						'one' => q(mul {0}),
						'other' => q(muls {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(muls),
						'one' => q(mul {0}),
						'other' => q(muls {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(vigs),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(vigs),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(yels),
						'one' => q(yel {0}),
						'other' => q(yels {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(yels),
						'one' => q(yel {0}),
						'other' => q(yels {0}),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:si|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:|no|n)$' }
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
							'yan',
							'feb',
							'mäz',
							'prl',
							'may',
							'yun',
							'yul',
							'gst',
							'set',
							'ton',
							'nov',
							'dek'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'yanul',
							'febul',
							'mäzul',
							'prilul',
							'mayul',
							'yunul',
							'yulul',
							'gustul',
							'setul',
							'tobul',
							'novul',
							'dekul'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'yan',
							'feb',
							'mäz',
							'prl',
							'may',
							'yun',
							'yul',
							'gst',
							'set',
							'tob',
							'nov',
							'dek'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Y',
							'F',
							'M',
							'P',
							'M',
							'Y',
							'Y',
							'G',
							'S',
							'T',
							'N',
							'D'
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
						mon => 'mu.',
						tue => 'tu.',
						wed => 've.',
						thu => 'dö.',
						fri => 'fr.',
						sat => 'zä.',
						sun => 'su.'
					},
					wide => {
						mon => 'mudel',
						tue => 'tudel',
						wed => 'vedel',
						thu => 'dödel',
						fri => 'fridel',
						sat => 'zädel',
						sun => 'sudel'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mu',
						tue => 'Tu',
						wed => 'Ve',
						thu => 'Dö',
						fri => 'Fr',
						sat => 'Zä',
						sun => 'Su'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'V',
						thu => 'D',
						fri => 'F',
						sat => 'Z',
						sun => 'S'
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
					abbreviated => {0 => 'Yf1',
						1 => 'Yf2',
						2 => 'Yf3',
						3 => 'Yf4'
					},
					wide => {0 => '1id yelafoldil',
						1 => '2id yelafoldil',
						2 => '3id yelafoldil',
						3 => '4id yelafoldil'
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
				'0' => 'b. t. kr.',
				'1' => 'p. t. kr.'
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
			'full' => q{G y MMMM'a' 'd'. d'id'},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM. d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{y MMMM'a' 'd'. d'id'},
			'long' => q{y MMMM d},
			'medium' => q{y MMM. d},
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
