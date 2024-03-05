=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Aa - Package for language Afar

=cut

package Locale::CLDR::Locales::Aa;
# This file auto generated from Data\common\main\aa.xml
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
				'aa' => 'Qafar',

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
			'DJ' => 'Yabuuti',
 			'ER' => 'Eretria',
 			'ET' => 'Otobbia',

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
			auxiliary => qr{[j p v z]},
			index => ['A', 'B', 'T', 'S', 'E', 'C', 'K', 'X', 'I', 'D', 'Q', 'R', 'F', 'G', 'O', 'L', 'M', 'N', 'U', 'W', 'H', 'Y'],
			main => qr{[a b t s e c k x i d q r f g o l m n u w h y]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'T', 'S', 'E', 'C', 'K', 'X', 'I', 'D', 'Q', 'R', 'F', 'G', 'O', 'L', 'M', 'N', 'U', 'W', 'H', 'Y'], };
},
);


has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
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
		'ETB' => {
			symbol => 'Br',
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
							'Qun',
							'Nah',
							'Cig',
							'Agd',
							'Cax',
							'Qas',
							'Qad',
							'Leq',
							'Way',
							'Dit',
							'Xim',
							'Kax'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Qunxa Garablu',
							'Kudo',
							'Ciggilta Kudo',
							'Agda Baxis',
							'Caxah Alsa',
							'Qasa Dirri',
							'Qado Dirri',
							'Liiqen',
							'Waysu',
							'Diteli',
							'Ximoli',
							'Kaxxa Garablu'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Q',
							'N',
							'C',
							'A',
							'C',
							'Q',
							'Q',
							'L',
							'W',
							'D',
							'X',
							'K'
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
						mon => 'Etl',
						tue => 'Tal',
						wed => 'Arb',
						thu => 'Kam',
						fri => 'Gum',
						sat => 'Sab',
						sun => 'Aca'
					},
					wide => {
						mon => 'Etleeni',
						tue => 'Talaata',
						wed => 'Arbaqa',
						thu => 'Kamiisi',
						fri => 'Gumqata',
						sat => 'Sabti',
						sun => 'Acaada'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'E',
						tue => 'T',
						wed => 'A',
						thu => 'K',
						fri => 'G',
						sat => 'S',
						sun => 'A'
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
					'am' => q{saaku},
					'pm' => q{carra},
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
				'0' => 'YD',
				'1' => 'YW'
			},
			wide => {
				'0' => 'Yaasuusuk Duma',
				'1' => 'Yaasuusuk Wadir'
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
			'full' => q{EEEE, MMMM dd, y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd-MMM-y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM dd, y},
			'long' => q{dd MMMM y},
			'medium' => q{dd-MMM-y},
			'short' => q{dd/MM/yy},
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
