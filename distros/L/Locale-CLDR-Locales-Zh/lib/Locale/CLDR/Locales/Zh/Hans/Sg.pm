=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Zh::Hans::Sg - Package for language Chinese

=cut

package Locale::CLDR::Locales::Zh::Hans::Sg;
# This file auto generated from Data\common\main\zh_Hans_SG.xml
#	on Tue  5 Dec  1:40:24 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

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

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ANG' => {
			display_name => {
				'other' => q(荷兰安的列斯盾),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
		},
		'NIO' => {
			display_name => {
				'other' => q(尼加拉瓜科多巴),
			},
		},
		'SGD' => {
			symbol => '$',
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
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
			'short' => q{dd/MM/yyGGGGG},
		},
		'gregorian' => {
			'short' => q{dd/MM/yy},
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
		'generic' => {
			MEd => q{M-dE},
			MMMMdd => q{M月d日},
			MMdd => q{MM-dd},
			Md => q{M-d},
			yyyyMEd => q{Gy年M月d日，E},
			yyyyMd => q{Gy年M月d日},
		},
		'gregorian' => {
			MEd => q{M-dE},
			MMM => q{M月},
			MMMMdd => q{M月d日},
			MMdd => q{MM-dd},
			Md => q{M-d},
			yMEd => q{y年M月d日，E},
			yMd => q{y年M月d日},
		},
		'japanese' => {
			MEd => q{M/dE},
			Md => q{M/d},
		},
		'roc' => {
			MEd => q{M-dE},
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
		'generic' => {
			Hmv => {
				H => q{vHH:mm–HH:mm},
				m => q{vHH:mm–HH:mm},
			},
			Hv => {
				H => q{vHH–HH},
			},
			MEd => {
				M => q{M-dE至M-dE},
				d => q{M-dE至M-dE},
			},
			MMMEd => {
				d => q{M月d日E至M月d日E},
			},
			Md => {
				M => q{M-d至M-d},
				d => q{M-d至M-d},
			},
			fallback => '{0}至{1}',
			yM => {
				M => q{y年M月至y年M月},
			},
			yMEd => {
				M => q{d/M/yE至d/M/yE},
				d => q{d/M/yE至d/M/yE},
				y => q{d/M/yE至d/M/yE},
			},
			yMd => {
				M => q{d/M/y至d/M/y},
				d => q{d/M/y至d/M/y},
				y => q{d/M/y至d/M/y},
			},
		},
		'gregorian' => {
			Hmv => {
				H => q{vHH:mm–HH:mm},
				m => q{vHH:mm–HH:mm},
			},
			Hv => {
				H => q{vHH–HH},
			},
			MEd => {
				M => q{M-dE至M-dE},
				d => q{M-dE至M-dE},
			},
			MMMEd => {
				d => q{M月d日E至M月d日E},
			},
			Md => {
				M => q{M-d至M-d},
				d => q{M-d至M-d},
			},
			d => {
				d => q{d日至d日},
			},
			fallback => '{0}至{1}',
			yM => {
				M => q{y年M月至y年M月},
			},
			yMEd => {
				M => q{d/M/yE至d/M/yE},
				d => q{d/M/yE至d/M/yE},
				y => q{d/M/yE至d/M/yE},
			},
			yMd => {
				M => q{d/M/y至d/M/y},
				d => q{d/M/y至d/M/y},
				y => q{d/M/y至d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'America/Scoresbysund' => {
			exemplarCity => q#斯考斯伯松德#,
		},
		'Malaysia' => {
			short => {
				'standard' => q#MYT#,
			},
		},
		'Singapore' => {
			short => {
				'standard' => q#SGT#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
