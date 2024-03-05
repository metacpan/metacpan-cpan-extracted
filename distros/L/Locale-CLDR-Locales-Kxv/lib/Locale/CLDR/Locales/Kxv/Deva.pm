=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kxv::Deva - Package for language Kuvi

=cut

package Locale::CLDR::Locales::Kxv::Deva;
# This file auto generated from Data\common\main\kxv_Deva.xml
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
				'en' => 'इंराजी',
 				'kxv' => 'कुवि',

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
			'Deva' => 'देवनागरी',
 			'Latn' => 'लातिन',
 			'Orya' => 'ऑड़िया',
 			'Telu' => 'तेलुगू',

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
			'IN' => 'बारत',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{मीट्रिक},
 			'UK' => q{यूके},
 			'US' => q{यूएस},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'काता: {0}',
 			'script' => 'ऑकॉरॉ : {0}',
 			'region' => 'मुट्-हा: {0}',

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
			main => qr{[ँ ंः अ {अऽ} आ {आऽ} इ ई उ ऊ ए {एऽ} ओ {ओऽ} क ग ङ च ज ञ ट ड{ड़} ण त द न प ब म य र ल ळ व स ह ऽ ा ि ी ु ू े ो ्]},
			numbers => qr{[\- ‑ , . % ‰ + 0 १ २ ३ ४ ५ ६ ७ ८ ९]},
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
	default		=> 'deva',
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
							'पुसु लेञ्जु',
							'माहाका लेञ्जु',
							'पागुणी लेञ्जु',
							'हिरे लेञ्जु',
							'बेसे लेञ्जु',
							'जाटा लेञ्जु',
							'आसाड़ी लेञ्जु',
							'स्राबाँ लेञ्जु',
							'बोदो लेञ्जु',
							'दसारा लेञ्जु',
							'दिवी लेञ्जु',
							'पान्डे लेञ्जु'
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
						mon => 'साॅम्वारा',
						tue => 'मंगाड़ा',
						wed => 'पुद्दारा',
						thu => 'लाक्कि वारा',
						fri => 'सुकुरु वारा',
						sat => 'सान्नि वारा',
						sun => 'आदि वारा'
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
					'am' => q{ए एम},
					'pm' => q{पी एम},
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
		regionFormat => q({0} बेला),
		regionFormat => q({0} मानांकॉ बेला),
		regionFormat => q({0} डेलाइट बेला),
		'GMT' => {
			long => {
				'standard' => q#ग्रीनविच मीन बेला#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
