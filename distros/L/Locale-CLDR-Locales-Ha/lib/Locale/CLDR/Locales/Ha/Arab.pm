=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ha::Arab - Package for language Hausa

=cut

package Locale::CLDR::Locales::Ha::Arab;
# This file auto generated from Data\common\main\ha_Arab.xml
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
has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => '',
			characters => 'right-to-left',
		}}
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
			index => ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ڢ', 'ك', 'ل', 'م', 'ن'],
			main => qr{[ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ڢ ك ل م ن]},
		};
	},
EOT
: sub {
		return { index => ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ڢ', 'ك', 'ل', 'م', 'ن'], };
},
);


has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arab',
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(نَيْرَ),
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
							'جَن',
							'ڢَب',
							'مَر',
							'أَڢْر',
							'مَي',
							'يُون',
							'يُول',
							'أَغُ',
							'سَت',
							'أُكْت',
							'نُو',
							'دِس'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جَنَيْرُ',
							'ڢَبْرَيْرُ',
							'مَرِسْ',
							'أَڢْرِلُ',
							'مَيُ',
							'يُونِ',
							'يُولِ',
							'أَغُسْتَ',
							'سَتُمْبَ',
							'أُكْتوُبَ',
							'نُوَمْبَ',
							'دِسَمْبَ'
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
						mon => 'لِت',
						tue => 'تَل',
						wed => 'لَر',
						thu => 'أَلْح',
						fri => 'جُم',
						sat => 'أَسَ',
						sun => 'لَح'
					},
					wide => {
						mon => 'لِتِنِنْ',
						tue => 'تَلَتَ',
						wed => 'لَرَبَ',
						thu => 'أَلْحَمِسْ',
						fri => 'جُمَعَ',
						sat => 'أَسَبَرْ',
						sun => 'لَحَدِ'
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
					'am' => q{A.M.},
					'pm' => q{P.M.},
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
				'0' => 'غَبَنِنْ مِلَدِ',
				'1' => 'مِلَدِ'
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

no Moo;

1;

# vim: tabstop=4
