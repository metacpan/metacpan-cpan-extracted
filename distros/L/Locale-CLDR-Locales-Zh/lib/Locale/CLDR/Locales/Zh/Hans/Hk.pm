=head1

Locale::CLDR::Locales::Zh::Hans::Hk - Package for language Chinese

=cut

package Locale::CLDR::Locales::Zh::Hans::Hk;
# This file auto generated from Data\common\main\zh_Hans_HK.xml
#	on Fri 13 Apr  7:36:35 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Zh::Hans');
has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'karat' => {
						'name' => q(开),
						'other' => q({0}开),
					},
					'kelvin' => {
						'name' => q(开氏度),
						'other' => q({0}开氏度),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'second' => {
						'other' => q({0}秒),
					},
				},
				'narrow' => {
					'foot' => {
						'other' => q({0}英尺),
					},
					'inch' => {
						'other' => q({0}英寸),
					},
					'light-year' => {
						'other' => q({0}光年),
					},
					'mile' => {
						'other' => q({0}英里),
					},
					'picometer' => {
						'other' => q({0}皮米),
					},
					'yard' => {
						'other' => q({0}码),
					},
				},
				'short' => {
					'g-force' => {
						'other' => q({0}G力),
					},
					'karat' => {
						'name' => q(开),
						'other' => q({0}开),
					},
					'kelvin' => {
						'name' => q(开氏度),
						'other' => q({0}°K),
					},
				},
			} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000000000000' => {
					'other' => '0万亿',
				},
				'10000000000000' => {
					'other' => '00万亿',
				},
				'100000000000000' => {
					'other' => '000万亿',
				},
			},
			'short' => {
				'1000000000000' => {
					'other' => '0万亿',
				},
				'10000000000000' => {
					'other' => '00万亿',
				},
				'100000000000000' => {
					'other' => '000万亿',
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
		'CNY' => {
			symbol => 'CN¥',
		},
		'KYD' => {
			display_name => {
				'currency' => q(开曼群岛元),
				'other' => q(开曼群岛元),
			},
		},
		'NIO' => {
			display_name => {
				'other' => q(尼加拉瓜科多巴),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(白银),
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
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
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

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'roc' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'short' => q{Gd/M/yy},
		},
		'chinese' => {
			'full' => q{U年MMMd日EEEE},
			'long' => q{U年MMMd日},
			'medium' => q{U年MMMd日},
		},
		'generic' => {
			'short' => q{d/M/yyGGGGG},
		},
		'gregorian' => {
			'short' => q{d/M/yy},
		},
		'islamic' => {
			'short' => q{Gd/M/yy},
		},
		'japanese' => {
			'short' => q{Gd/M/yy},
		},
		'roc' => {
			'short' => q{Gd/M/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			M => q{L},
			MEd => q{M/dE},
		},
		'gregorian' => {
			HHmm => q{HH:mm},
			MEd => q{E, d/M},
			MMMMdd => q{M月d日},
			MMdd => q{dd/MM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{d/M/y（E）},
			yMM => q{MM/y},
			yMd => q{d/M/y},
		},
		'generic' => {
			HHmm => q{HH:mm},
			MEd => q{E, d/M},
			MMM => q{M月},
			MMMMdd => q{M月d日},
			Md => q{d/M},
			yyyyM => q{M/yGGGGG},
			yyyyMEd => q{E, d/M/yGGGGG},
			yyyyMd => q{d/M/yGGGGG},
		},
		'japanese' => {
			MEd => q{M/dE},
			Md => q{M/d},
		},
		'roc' => {
			M => q{L},
			MMM => q{M月},
			Md => q{M-d},
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
		'gregorian' => {
			Hmv => {
				H => q{vHH:mm–HH:mm},
				m => q{vHH:mm–HH:mm},
			},
			Hv => {
				H => q{vHH–HH},
			},
			fallback => '{0}–{1}',
			h => {
				h => q{ah至h时},
			},
			yM => {
				M => q{y年M月至y年M月},
			},
			yMEd => {
				M => q{d/M/yE至d/M/yE},
				d => q{d/M/yE至d/M/yE},
				y => q{d/M/yE至d/M/yE},
			},
			yMMMEd => {
				d => q{y年M月d日E至M月d日E},
			},
			yMd => {
				M => q{d/M/y至d/M/y},
				d => q{d/M/y至d/M/y},
				y => q{d/M/y至d/M/y},
			},
		},
		'generic' => {
			Hmv => {
				H => q{vHH:mm–HH:mm},
				m => q{vHH:mm–HH:mm},
			},
			Hv => {
				H => q{vHH–HH},
			},
			fallback => '{0}–{1}',
			h => {
				h => q{ah至h时},
			},
			yM => {
				M => q{y年M月至y年M月},
			},
			yMEd => {
				M => q{d/M/yE至d/M/yE},
				d => q{d/M/yE至d/M/yE},
				y => q{d/M/yE至d/M/yE},
			},
			yMMMEd => {
				d => q{y年M月d日E至M月d日E},
			},
			yMd => {
				M => q{d/M/y至d/M/y},
				d => q{d/M/y至d/M/y},
				y => q{d/M/y至d/M/y},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
