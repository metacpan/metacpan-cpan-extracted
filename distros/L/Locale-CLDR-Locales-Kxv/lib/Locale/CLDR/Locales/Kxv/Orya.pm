=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kxv::Orya - Package for language Kuvi

=cut

package Locale::CLDR::Locales::Kxv::Orya;
# This file auto generated from Data\common\main\kxv_Orya.xml
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
				'en' => 'ଇଂରାଜୀ',
 				'kxv' => 'କୁୱି',

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
			'Deva' => 'ଦେୱନାଗରୀ',
 			'Latn' => 'ଲାଟିନ୍',
 			'Orya' => 'ଅଡ଼ିଆ',
 			'Telu' => 'ତେଲୁଗୁ',

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
			'IN' => 'ବାରତ',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{ମେଟ୍ରିକ},
 			'UK' => q{ୟୁକେ},
 			'US' => q{ୟୁଏସ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'କାତା: {0}',
 			'script' => 'ଅକର: {0}',
 			'region' => 'ମୁଟ୍ହା: {0}',

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
			main => qr{[଼ ଁଂଃ ଅ {ଅ\:} ଆ {ଆ\:} ଇ ଈ ଉ ଊ ଏ {ଏ\:} କ ଗ ଙ ଚ ଜ ଞ ଟ ଡ ଣ ତ ଦ ନ ପ ବ ମ ୟ ର ଲ ଳ ୱ ସ ହ ା ି ୀ ୁ ୂ େ ୍]},
			numbers => qr{[\- ‑ , . % ‰ + 0 ୧ ୨ ୩ ୪ ୫ ୬ ୭ ୮ ୯]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'orya',
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##,##0.###',
				},
			},
		},
} },
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
						'positive' => '¤#,##,##0.00',
					},
				},
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
					wide => {
						nonleap => [
							'ପୁସୁ ଲେଞ୍ଜୁ',
							'ମାହାକା ଲେଞ୍ଜୁ',
							'ପାଗୁଣି ଲେଞ୍ଜୁ',
							'ହିରେ ଲେଞ୍ଜୁ',
							'ବେସେ ଲେଞ୍ଜୁ',
							'ଜାଟା ଲେଞ୍ଜୁ',
							'ଆସାଡ଼ି ଲେଞ୍ଜୁ',
							'ସ୍ରାବାଁ ଲେଞ୍ଜୁ',
							'ବଦ ଲେଞ୍ଜୁ',
							'ଦାସାରା ଲେଞ୍ଜୁ',
							'ଦିୱିଡ଼ି ଲେଞ୍ଜୁ',
							'ପାଣ୍ଡେ ଲେଞ୍ଜୁ'
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
						mon => 'ସମ୍ବାରା',
						tue => 'ମାଙ୍ଗାଡ଼ା',
						wed => 'ପୁଦାରା',
						thu => 'ଲାକି ୱାରା',
						fri => 'ସୁକ୍ରୁ ୱାରା',
						sat => 'ସାନି ୱାରା',
						sun => 'ଆଦି ୱାରା'
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
				'wide' => {
					'am' => q{ଏ ଏମ},
					'pm' => q{ପି ଏମ},
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
		'gregorian' => {
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} ବେଲା),
		regionFormat => q({0} ଡେଲାଇଟ ବେଲା),
		regionFormat => q({0} ମାନାଙ୍କ ବେଲା),
		'GMT' => {
			long => {
				'standard' => q#ଗ୍ରିନୱିଚ ମିନ ବେଲା#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
