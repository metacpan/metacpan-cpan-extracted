=head1

Locale::CLDR::Locales::Ar::Any::Sa - Package for language Arabic

=cut

package Locale::CLDR::Locales::Ar::Any::Sa;
# This file auto generated from Data\common\main\ar_SA.xml
#	on Fri 13 Apr  7:01:24 am GMT

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

extends('Locale::CLDR::Locales::Ar::Any');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'arn' => 'المابودونجونية',
 				'gn' => 'الغورانية',
 				'hsb' => 'صوربيا العليا',
 				'lo' => 'اللاوو',
 				'sh' => 'الكرواتية الصربية',
 				'sma' => 'سامي الجنوبية',
 				'sw' => 'السواحيلية',
 				'sw_CD' => 'السواحيلية الكونغولية',
 				'te' => 'التيلوجو',
 				'ti' => 'التيغرينية',

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
			'AC' => 'جزيرة أسينشين',
 			'BS' => 'جزر البهاما',
 			'CZ@alt=variant' => 'التشيك',
 			'EA' => 'سبتة ومليلية',
 			'MO' => 'ماكاو الصينية (منطقة إدارية خاصة)',
 			'MO@alt=short' => 'ماكاو',
 			'MS' => 'مونتيسيرات',
 			'PM' => 'سان بيير وميكولون',
 			'UY' => 'أوروغواي',

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
			numbers => qr{[‎ \- , . ٪ ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'percentSign' => q(٪),
		},
	} }
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
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'night2' if $time >= 100
						&& $time < 300;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'night1' if $time >= 0
						&& $time < 100;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night2' if $time >= 100
						&& $time < 300;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
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
					'evening1' => q{مساءً},
					'morning2' => q{ص},
					'afternoon2' => q{بعد الظهر},
					'morning1' => q{فجرًا},
					'afternoon1' => q{ظهرًا},
					'night2' => q{ل},
					'night1' => q{منتصف الليل},
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

no Moo;

1;

# vim: tabstop=4
