=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Shaw - Package for language English

=cut

package Locale::CLDR::Locales::En::Shaw;
# This file auto generated from Data\common\main\en_Shaw.xml
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
has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'001' => '𐑢𐑻𐑤𐑛',
 			'019' => '·𐑩𐑥𐑧𐑮𐑦𐑒𐑩𐑟',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{𐑥𐑧𐑑𐑮𐑦𐑒},

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
			index => ['𐑐', '𐑑', '𐑒', '𐑓', '𐑔', '𐑕', '𐑖', '𐑗', '𐑘', '𐑙', '𐑚', '𐑛', '𐑜', '𐑝', '𐑞', '𐑟', '𐑠', '𐑡', '𐑢', '𐑣', '𐑤', '𐑥', '𐑦', '𐑧', '𐑨', '𐑩', '𐑪', '𐑫', '𐑬', '𐑭', '𐑮', '𐑯', '𐑰', '𐑱', '𐑲', '𐑳', '𐑴', '𐑵', '𐑶', '𐑷', '𐑸', '𐑹', '𐑺', '𐑻', '𐑼', '𐑽', '𐑾', '𐑿'],
			main => qr{[𐑐 𐑑 𐑒 𐑓 𐑔 𐑕 𐑖 𐑗 𐑘 𐑙 𐑚 𐑛 𐑜 𐑝 𐑞 𐑟 𐑠 𐑡 𐑢 𐑣 𐑤 𐑥 𐑦 𐑧 𐑨 𐑩 𐑪 𐑫 𐑬 𐑭 𐑮 𐑯 𐑰 𐑱 𐑲 𐑳 𐑴 𐑵 𐑶 𐑷 𐑸 𐑹 𐑺 𐑻 𐑼 𐑽 𐑾 𐑿]},
		};
	},
EOT
: sub {
		return { index => ['𐑐', '𐑑', '𐑒', '𐑓', '𐑔', '𐑕', '𐑖', '𐑗', '𐑘', '𐑙', '𐑚', '𐑛', '𐑜', '𐑝', '𐑞', '𐑟', '𐑠', '𐑡', '𐑢', '𐑣', '𐑤', '𐑥', '𐑦', '𐑧', '𐑨', '𐑩', '𐑪', '𐑫', '𐑬', '𐑭', '𐑮', '𐑯', '𐑰', '𐑱', '𐑲', '𐑳', '𐑴', '𐑵', '𐑶', '𐑷', '𐑸', '𐑹', '𐑺', '𐑻', '𐑼', '𐑽', '𐑾', '𐑿'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:𐑘𐑧𐑕|𐑘|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:𐑯𐑴|𐑯|no|n)$' }
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
							'·𐑡𐑨',
							'·𐑓𐑧',
							'·𐑥𐑸',
							'·𐑱𐑐',
							'·𐑥𐑱',
							'·𐑡𐑵',
							'·𐑡𐑫',
							'·𐑪𐑜',
							'·𐑕𐑧',
							'·𐑷𐑒',
							'·𐑯𐑴',
							'·𐑛𐑭'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'·𐑡𐑨𐑙𐑘𐑭𐑢𐑺𐑰',
							'·𐑓𐑧𐑚𐑘𐑵𐑢𐑺𐑰',
							'·𐑥𐑸𐑗',
							'·𐑱𐑐𐑮𐑭𐑤',
							'·𐑥𐑱',
							'·𐑡𐑵𐑯',
							'·𐑡𐑫𐑤𐑲',
							'·𐑪𐑜𐑭𐑕𐑑',
							'·𐑕𐑧𐑐𐑑𐑧𐑥𐑚𐑸',
							'·𐑷𐑒𐑑𐑴𐑚𐑸',
							'·𐑯𐑴𐑝𐑧𐑥𐑚𐑸',
							'·𐑛𐑭𐑕𐑧𐑥𐑚𐑸'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'𐑡',
							'𐑓',
							'𐑥',
							'𐑱',
							'𐑥',
							'𐑡',
							'𐑡',
							'𐑪',
							'𐑕',
							'𐑷',
							'𐑯',
							'𐑛'
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
						mon => '·𐑥𐑭',
						tue => '·𐑑𐑵',
						wed => '·𐑢𐑧',
						thu => '·𐑔𐑻',
						fri => '·𐑓𐑮',
						sat => '·𐑕𐑨',
						sun => '·𐑕𐑭'
					},
					wide => {
						mon => '·𐑥𐑭𐑙𐑛𐑱',
						tue => '·𐑑𐑵𐑟𐑛𐑱',
						wed => '·𐑢𐑧𐑙𐑟𐑛𐑱',
						thu => '·𐑔𐑻𐑟𐑛𐑱',
						fri => '·𐑓𐑮𐑲𐑛𐑱',
						sat => '·𐑕𐑨𐑛𐑻𐑛𐑱',
						sun => '·𐑕𐑭𐑙𐑛𐑱'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => '𐑥',
						tue => '𐑑',
						wed => '𐑢',
						thu => '𐑔',
						fri => '𐑓',
						sat => '𐑕',
						sun => '𐑕'
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
					abbreviated => {0 => '𐑒1',
						1 => '𐑒2',
						2 => '𐑒3',
						3 => '𐑒4'
					},
					wide => {0 => '1𐑕𐑑 𐑒𐑢𐑸𐑛𐑸',
						1 => '2𐑯𐑛 𐑒𐑢𐑸𐑛𐑸',
						2 => '3𐑻𐑛 𐑒𐑢𐑸𐑛𐑸',
						3 => '4𐑹𐑔 𐑒𐑢𐑸𐑛𐑸'
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
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
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
				'abbreviated' => {
					'am' => q{𐑨.𐑥.},
					'pm' => q{𐑐.𐑥.},
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
				'0' => '𐑚·𐑒',
				'1' => '𐑨𐑛'
			},
			narrow => {
				'0' => '𐑚',
				'1' => '𐑨'
			},
			wide => {
				'0' => '𐑚𐑰𐑓𐑪𐑮 ·𐑒𐑮𐑲𐑕𐑑',
				'1' => '𐑨𐑙𐑴 𐑛𐑪𐑥𐑦𐑙𐑰'
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
		gmtFormat => q(·𐑜𐑥𐑑{0}),
		gmtZeroFormat => q(·𐑜𐑥𐑑),
		regionFormat => q({0} 𐑑𐑲𐑥),
	 } }
);
no Moo;

1;

# vim: tabstop=4
