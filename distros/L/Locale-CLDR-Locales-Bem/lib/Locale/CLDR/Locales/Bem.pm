=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bem - Package for language Bemba

=cut

package Locale::CLDR::Locales::Bem;
# This file auto generated from Data\common\main\bem.xml
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
				'ak' => 'Ichi Akan',
 				'am' => 'Ichi Amhari',
 				'ar' => 'Ichi Arab',
 				'be' => 'Ichi Belarus',
 				'bem' => 'Ichibemba',
 				'bg' => 'Ichi Bulgariani',
 				'bn' => 'Ichi Bengali',
 				'cs' => 'Ichi Cheki',
 				'de' => 'Ichi Jemani',
 				'el' => 'Ichi Griki',
 				'en' => 'Ichi Sungu',
 				'es' => 'Ichi Spanishi',
 				'fa' => 'Ichi Pesia',
 				'fr' => 'Ichi Frenchi',
 				'ha' => 'Ichi Hausa',
 				'hi' => 'Ichi Hindu',
 				'hu' => 'Ichi Hangarian',
 				'id' => 'Ichi Indonesiani',
 				'ig' => 'Ichi Ibo',
 				'it' => 'Ichi Italiani',
 				'ja' => 'Ichi Japanisi',
 				'jv' => 'Ichi Javanisi',
 				'km' => 'Ichi Khmer',
 				'ko' => 'Ichi Koriani',
 				'ms' => 'Ichi Maleshani',
 				'my' => 'Ichi Burma',
 				'ne' => 'Ichi Nepali',
 				'nl' => 'Ichi Dachi',
 				'pa' => 'Ichi Punjabi',
 				'pl' => 'Ichi Polishi',
 				'pt' => 'Ichi Potogisi',
 				'ro' => 'Ichi Romaniani',
 				'ru' => 'Ichi Rusiani',
 				'rw' => 'Ichi Rwanda',
 				'so' => 'Ichi Somalia',
 				'sv' => 'Ichi Swideni',
 				'ta' => 'Ichi Tamil',
 				'th' => 'Ichi Thai',
 				'tr' => 'Ichi Takishi',
 				'uk' => 'Ichi Ukraniani',
 				'ur' => 'Ichi Urudu',
 				'vi' => 'Ichi Vietinamu',
 				'yo' => 'Ichi Yoruba',
 				'zh' => 'Ichi Chainisi',
 				'zu' => 'Ichi Zulu',

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
			'ZM' => 'Zambia',

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
			auxiliary => qr{[d h q r v x z]},
			index => ['A', 'B', 'C', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'S', '{SH}', 'T', 'U', 'W', 'Y'],
			main => qr{[a b c e f g i j k l m n o p s {sh} t u w y]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'S', '{SH}', 'T', 'U', 'W', 'Y'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ee|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Awe|A|no|n)$' }
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ZMW' => {
			symbol => 'K',
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
							'Jan',
							'Feb',
							'Mac',
							'Epr',
							'Mei',
							'Jun',
							'Jul',
							'Oga',
							'Sep',
							'Okt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januari',
							'Februari',
							'Machi',
							'Epreo',
							'Mei',
							'Juni',
							'Julai',
							'Ogasti',
							'Septemba',
							'Oktoba',
							'Novemba',
							'Disemba'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'E',
							'M',
							'J',
							'J',
							'O',
							'S',
							'O',
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
					wide => {
						mon => 'Palichimo',
						tue => 'Palichibuli',
						wed => 'Palichitatu',
						thu => 'Palichine',
						fri => 'Palichisano',
						sat => 'Pachibelushi',
						sun => 'Pa Mulungu'
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
					'am' => q{uluchelo},
					'pm' => q{akasuba},
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Before Yesu',
				'1' => 'After Yesu'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
		'generic' => {
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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
