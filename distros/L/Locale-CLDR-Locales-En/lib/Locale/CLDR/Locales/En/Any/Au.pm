=head1

Locale::CLDR::Locales::En::Any::Au - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Au;
# This file auto generated from Data\common\main\en_AU.xml
#	on Fri 13 Apr  7:07:47 am GMT

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

extends('Locale::CLDR::Locales::En::Any::001');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'bn' => 'Bengali',
 				'en_US' => 'United States English',
 				'frc' => 'frc',
 				'lou' => 'lou',
 				'ro_MD' => 'Moldovan',

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
			'Beng' => 'Bengali',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'dangi' => q{Korean Calendar},
 				'ethiopic' => q{Ethiopian Calendar},
 			},

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'generic' => {
						'name' => q(degrees),
						'one' => q({0} degree),
						'other' => q({0} degrees),
					},
					'kilometer' => {
						'name' => q(kilometre),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatt hours),
						'one' => q({0} kilowatt hour),
						'other' => q({0} kilowatt hours),
					},
					'metric-ton' => {
						'name' => q(tonnes),
						'one' => q(tonne),
						'other' => q({0} tonnes),
					},
					'micrometer' => {
						'name' => q(micrometres),
					},
				},
				'narrow' => {
					'bushel' => {
						'one' => q({0} bus.),
						'other' => q({0} bus.),
					},
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					'mile-per-hour' => {
						'name' => q(m.p.h.),
						'one' => q({0} m.p.h.),
						'other' => q({0} m.p.h.),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					'millisecond' => {
						'name' => q(msec.),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					'second' => {
						'name' => q(sec.),
						'one' => q({0} s.),
						'other' => q({0} s.),
					},
				},
				'short' => {
					'arc-minute' => {
						'name' => q(arcmin.),
						'one' => q({0} arcmin.),
						'other' => q({0} arcmin.),
					},
					'arc-second' => {
						'name' => q(arcsec.),
						'one' => q({0} arcsec.),
						'other' => q({0} arcsec.),
					},
					'astronomical-unit' => {
						'name' => q(AU),
						'one' => q({0} AU),
						'other' => q({0} AU),
					},
					'bushel' => {
						'one' => q({0} bus.),
						'other' => q({0} bus.),
					},
					'carat' => {
						'one' => q({0} CM),
						'other' => q({0} CM),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'century' => {
						'name' => q(C.),
						'one' => q({0} C.),
						'other' => q({0} C.),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'degree' => {
						'one' => q({0} deg.),
						'other' => q({0} deg.),
					},
					'fathom' => {
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					'gallon' => {
						'name' => q(US gal.),
						'one' => q({0} gal. US),
						'other' => q({0} gal. US),
						'per' => q({0}/gal. US),
					},
					'gallon-imperial' => {
						'name' => q(gal.),
						'one' => q({0} gal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
					},
					'generic' => {
						'name' => q(deg.),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hour' => {
						'per' => q({0} phr),
					},
					'kilocalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'kilometer-per-hour' => {
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
					},
					'light-year' => {
						'one' => q({0} l.y.),
						'other' => q({0} l.y.),
					},
					'liter' => {
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'meter-per-second' => {
						'name' => q(metres/sec.),
						'one' => q({0} m/s.),
						'other' => q({0} m/s.),
					},
					'microsecond' => {
						'name' => q(μsec.),
					},
					'mile-per-gallon' => {
						'name' => q(miles/gal. US),
						'one' => q({0} m.p.g. US),
						'other' => q({0} m.p.g. US),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miles/gal.),
						'one' => q({0} m.p.g.),
						'other' => q({0} m.p.g.),
					},
					'mile-per-hour' => {
						'one' => q({0} m.p.h.),
						'other' => q({0} m.p.h.),
					},
					'millibar' => {
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimole-per-liter' => {
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(millisec.),
					},
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					'month' => {
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					'nanosecond' => {
						'name' => q(nanosec.),
					},
					'second' => {
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} sec.),
						'per' => q({0} ps.),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} and {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'exponential' => q(e),
			'timeSeparator' => q(.),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AUD' => {
			symbol => '$',
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnia-Herzegovina Convertible Marka),
				'one' => q(Bosnia-Herzegovina convertible marka),
				'other' => q(Bosnia-Herzegovina convertible marka),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados Dollar),
				'one' => q(Barbados dollar),
				'other' => q(Barbados dollars),
			},
		},
		'BDT' => {
			symbol => 'Tk',
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda Dollar),
				'one' => q(Bermuda dollar),
				'other' => q(Bermuda dollars),
			},
		},
		'BOB' => {
			symbol => '$b',
			display_name => {
				'currency' => q(Boliviano),
				'one' => q(boliviano),
				'other' => q(bolivianos),
			},
		},
		'BRL' => {
			symbol => 'BRL',
		},
		'CAD' => {
			symbol => 'CAD',
		},
		'CNH' => {
			display_name => {
				'currency' => q(CNH),
				'one' => q(CNH),
				'other' => q(CNH),
			},
		},
		'CNY' => {
			symbol => 'CNY',
		},
		'CUP' => {
			symbol => '₱',
		},
		'EGP' => {
			symbol => '£',
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'GBP' => {
			symbol => 'GBP',
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'one' => q(Georgian lari),
				'other' => q(Georgian lari),
			},
		},
		'HKD' => {
			symbol => 'HKD',
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(Israeli Shekel),
				'one' => q(Israeli shekel),
				'other' => q(Israeli sheckles),
			},
		},
		'INR' => {
			symbol => 'INR',
		},
		'ISK' => {
			symbol => 'Kr',
		},
		'JPY' => {
			symbol => 'JPY',
		},
		'KRW' => {
			symbol => 'KRW',
		},
		'KZT' => {
			display_name => {
				'one' => q(Kazakhstani tenge),
				'other' => q(Kazakhstani tenge),
			},
		},
		'LAK' => {
			display_name => {
				'one' => q(Laotian kip),
				'other' => q(Laotian kip),
			},
		},
		'MKD' => {
			display_name => {
				'one' => q(Macedonian denar),
				'other' => q(Macedonian denar),
			},
		},
		'MXN' => {
			symbol => 'MXN',
		},
		'NZD' => {
			symbol => 'NZD',
		},
		'PGK' => {
			display_name => {
				'one' => q(Papua New Guinean kina),
				'other' => q(Papua New Guinean kinas),
			},
		},
		'PYG' => {
			symbol => 'Gs',
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatari Riyal),
				'one' => q(Qatari riyal),
				'other' => q(Quatari riyals),
			},
		},
		'SCR' => {
			symbol => 'Rs',
		},
		'SEK' => {
			symbol => 'Kr',
		},
		'SRD' => {
			display_name => {
				'currency' => q(Suriname Dollar),
				'one' => q(Suriname dollar),
				'other' => q(Suriname dollars),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'one' => q(Turkish lira),
				'other' => q(Turkish lire),
			},
		},
		'TWD' => {
			symbol => 'TWD',
		},
		'USD' => {
			symbol => 'USD',
		},
		'UYU' => {
			symbol => '$U',
			display_name => {
				'currency' => q(Peso Uruguayo),
			},
		},
		'UZS' => {
			display_name => {
				'one' => q(Uzbekistani som),
				'other' => q(Uzbekistani soms),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'one' => q(Vietnamese dong),
				'other' => q(Vietnamese dongs),
			},
		},
		'WST' => {
			display_name => {
				'one' => q(Samoan tala),
				'other' => q(Samoan talas),
			},
		},
		'XAF' => {
			symbol => 'XAF',
		},
		'XCD' => {
			symbol => 'XCD',
		},
		'XOF' => {
			symbol => 'XOF',
		},
		'XPF' => {
			symbol => 'CFP',
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
							'Jan.',
							'Feb.',
							'Mar.',
							'Apr.',
							'May',
							'Jun.',
							'Jul.',
							'Aug.',
							'Sep.',
							'Oct.',
							'Nov.',
							'Dec.'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jan.',
							'Feb.',
							'Mar.',
							'Apr.',
							'May',
							'Jun.',
							'Jul.',
							'Aug.',
							'Sep.',
							'Oct.',
							'Nov.',
							'Dec.'
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
						mon => 'Mon.',
						tue => 'Tue.',
						wed => 'Wed.',
						thu => 'Thu.',
						fri => 'Fri.',
						sat => 'Sat.',
						sun => 'Sun.'
					},
					narrow => {
						mon => 'M.',
						tue => 'Tu.',
						wed => 'W.',
						thu => 'Th.',
						fri => 'F.',
						sat => 'Sa.',
						sun => 'Su.'
					},
					short => {
						mon => 'Mon.',
						tue => 'Tu.',
						wed => 'Wed.',
						thu => 'Th.',
						fri => 'Fri.',
						sat => 'Sat.',
						sun => 'Su.'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mon.',
						tue => 'Tue.',
						wed => 'Wed.',
						thu => 'Thu.',
						fri => 'Fri.',
						sat => 'Sat.',
						sun => 'Sun.'
					},
					narrow => {
						mon => 'M.',
						tue => 'Tu.',
						wed => 'W.',
						thu => 'Th.',
						fri => 'F.',
						sat => 'Sa.',
						sun => 'Su.'
					},
					short => {
						mon => 'Mon.',
						tue => 'Tu.',
						wed => 'Wed.',
						thu => 'Th.',
						fri => 'Fri.',
						sat => 'Sat.',
						sun => 'Su.'
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
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					'noon' => q{midday},
					'night1' => q{night},
					'afternoon1' => q{afternoon},
					'morning1' => q{morning},
					'midnight' => q{midnight},
					'pm' => q{pm},
					'am' => q{am},
					'evening1' => q{evening},
				},
				'narrow' => {
					'evening1' => q{evening},
					'am' => q{am},
					'night1' => q{night},
					'noon' => q{midday},
					'afternoon1' => q{afternoon},
					'morning1' => q{morning},
					'pm' => q{pm},
					'midnight' => q{midnight},
				},
				'wide' => {
					'evening1' => q{in the evening},
					'am' => q{am},
					'pm' => q{pm},
					'midnight' => q{midnight},
					'night1' => q{at night},
					'noon' => q{midday},
					'morning1' => q{in the morning},
					'afternoon1' => q{in the afternoon},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'noon' => q{midday},
					'am' => q{am},
					'pm' => q{pm},
				},
				'narrow' => {
					'pm' => q{pm},
					'am' => q{am},
					'noon' => q{midday},
				},
				'wide' => {
					'pm' => q{pm},
					'am' => q{am},
					'noon' => q{midday},
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
		},
		'islamic' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'short' => q{d/M/yy},
		},
		'islamic' => {
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
		},
		'islamic' => {
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
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			yMEd => q{E, dd/MM/y},
			yMd => q{dd/MM/y},
		},
		'gregorian' => {
			MEd => q{E, d/M},
			Md => q{d/M},
		},
		'islamic' => {
			yMEd => q{E, dd/MM/y},
			yMd => q{dd/MM/y},
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
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			yMMMEd => {
				d => q{E, d MMM – E, d MMM y G},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Africa_Eastern' => {
			long => {
				'standard' => q#Eastern Africa Time#,
			},
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St Barthélemy#,
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabia Daylight Time#,
				'generic' => q#Arabia Time#,
				'standard' => q#Arabia Standard Time#,
			},
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Australian Central Daylight Time#,
				'generic' => q#Australian Central Time#,
				'standard' => q#Australian Central Standard Time#,
			},
			short => {
				'daylight' => q#ACDT#,
				'generic' => q#ACT#,
				'standard' => q#ACST#,
			},
		},
		'Australia_CentralWestern' => {
			short => {
				'daylight' => q#ACWDT#,
				'generic' => q#ACWT#,
				'standard' => q#ACWST#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australian Eastern Daylight Time#,
				'generic' => q#Australian Eastern Time#,
				'standard' => q#Australian Eastern Standard Time#,
			},
			short => {
				'daylight' => q#AEDT#,
				'generic' => q#AET#,
				'standard' => q#AEST#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Australian Western Daylight Time#,
				'generic' => q#Australian Western Time#,
				'standard' => q#Australian Western Standard Time#,
			},
			short => {
				'daylight' => q#AWDT#,
				'generic' => q#AWT#,
				'standard' => q#AWST#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#China Summer Time#,
				'generic' => q#China Time#,
				'standard' => q#China Standard Time#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cook Island Summer Time#,
				'generic' => q#Cook Island Time#,
				'standard' => q#Cook Island Standard Time#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan Summer Time#,
				'generic' => q#Japan Time#,
				'standard' => q#Japan Standard Time#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korean Summer Time#,
				'generic' => q#Korea Time#,
				'standard' => q#Korean Standard Time#,
			},
		},
		'Lord_Howe' => {
			short => {
				'daylight' => q#LHDT#,
				'generic' => q#LHT#,
				'standard' => q#LHST#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moscow Daylight Time#,
				'generic' => q#Moscow Time#,
				'standard' => q#Moscow Standard Time#,
			},
		},
		'New_Zealand' => {
			short => {
				'daylight' => q#NZDT#,
				'generic' => q#NZT#,
				'standard' => q#NZST#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Summer Time#,
				'generic' => q#Samoa Time#,
				'standard' => q#Samoa Standard Time#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei Summer Time#,
				'generic' => q#Taipei Time#,
				'standard' => q#Taipei Standard Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
