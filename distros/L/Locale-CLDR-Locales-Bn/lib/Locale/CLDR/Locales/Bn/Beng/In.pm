=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bn::Beng::In - Package for language Bangla

=cut

package Locale::CLDR::Locales::Bn::Beng::In;
# This file auto generated from Data\common\main\bn_IN.xml
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

extends('Locale::CLDR::Locales::Bn::Beng');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ksh' => 'কোলোনিয়ান',

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
			'018' => 'দক্ষিণাঞ্চলীয় আফ্রিকা',
 			'202' => 'সাহারা-নিম্ন আফ্রিকা',
 			'CD@alt=variant' => 'কঙ্গো (DRC)',
 			'NZ@alt=variant' => 'আওটেয়ারোয়া নিউজিল্যান্ড',
 			'QO' => 'ওশিয়ানিয়ার দূরবর্তী অঞ্চল',
 			'UM' => 'মার্কিন যুক্তরাষ্ট্রের দূরবর্তী দ্বীপপুঞ্জ',

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
 				'gregorian' => q{গ্রেগোরিয়ান ক্যালেন্ডার},
 				'iso8601' => q{ISO-8601 ক্যালেন্ডার},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'US' => q{ইউএস},

		}
	},
);

has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-medial' => '{0}…{1}',
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
					'' => {
						'name' => q(প্রধান দিক),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(প্রধান দিক),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(দিক),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(দিক),
					},
				},
			} }
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'beng' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤ #,##,##0.00',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤#,##,##0.00)',
						'positive' => '¤#,##,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##,##0.00',
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
		'ANG' => {
			display_name => {
				'currency' => q(নেদারল্যান্ডস অ্যান্টিলিয়ান গিল্ডার),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(আরুবান গিল্ডার),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(বারমুডান ডলার),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(গুয়াতেমালান কেৎসাল),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(হন্ডুরান লেম্পিরা),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(হাইতিয়ান গুর্দ),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(মেক্সিকান পেসো),
			},
		},
		'USD' => {
			symbol => '$',
		},
		'XCD' => {
			display_name => {
				'currency' => q(পূর্ব ক্যারিবিয়ান ডলার),
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
							'জানু',
							'ফেব',
							'মার্চ',
							'এপ্রি',
							'মে',
							'জুন',
							'জুল',
							'আগ',
							'সেপ্টেঃ',
							'অক্টোঃ',
							'নভেঃ',
							'ডিসেঃ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'জানু',
							'ফেব',
							'মার্চ',
							'এপ্রিল',
							'মে',
							'জুন',
							'জুলাই',
							'আগস্ট',
							'সেপ্টেঃ',
							'অক্টোঃ',
							'নভেঃ',
							'ডিসেঃ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'জা',
							'ফে',
							'মা',
							'এ',
							'মে',
							'জুন',
							'জুল',
							'আ',
							'সে',
							'অ',
							'ন',
							'ডি'
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
						mon => 'সোঃ',
						tue => 'মঃ',
						wed => 'বুঃ',
						thu => 'বৃঃ',
						fri => 'শুঃ',
						sat => 'শঃ',
						sun => 'রঃ'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'afternoon2' if $time >= 1600
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'afternoon2' if $time >= 1600
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'wide' => {
					'afternoon1' => q{দুপুরবেলায়},
					'afternoon2' => q{বিকাল},
					'evening1' => q{সন্ধ্যাবেলায়},
					'morning1' => q{ভোরবেলায়},
					'morning2' => q{সকালবেলায়},
					'night1' => q{রাত্রি},
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
				'0' => 'খ্রিঃপূঃ',
				'1' => 'খ্রিঃ'
			},
			wide => {
				'1' => 'খ্রিষ্টাব্দ'
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
			MMMMW => q{MMMM এর W নম্বর সপ্তাহ},
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
