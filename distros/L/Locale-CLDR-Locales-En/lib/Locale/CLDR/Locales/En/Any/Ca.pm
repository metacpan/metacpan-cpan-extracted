=head1

Locale::CLDR::Locales::En::Any::Ca - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Ca;
# This file auto generated from Data\common\main\en_CA.xml
#	on Sun  5 Aug  5:58:21 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
 				'mfe' => 'Mauritian',
 				'ro_MD' => 'Moldovan',
 				'tvl' => 'Tuvaluan',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
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
 				'dangi' => q{Korean Calendar},
 				'ethiopic' => q{Ethiopian Calendar},
 			},
 			'd0' => {
 				'fwidth' => q{To Full Width},
 				'hwidth' => q{To Half Width},
 				'lower' => q{To Lower Case},
 				'title' => q{To Title Case},
 				'upper' => q{To Upper Case},
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
					'karat' => {
						'name' => q(karats),
						'one' => q({0} karat),
						'other' => q({0} karats),
					},
					'kilowatt-hour' => {
						'one' => q({0} kilowatt-hour),
						'other' => q({0} kilowatt-hours),
					},
				},
				'narrow' => {
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					'day' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					'foot' => {
						'name' => q(ft.),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'inch' => {
						'name' => q(in.),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
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
					'mile' => {
						'name' => q(mi.),
					},
					'mile-per-hour' => {
						'name' => q(mi./hr.),
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
						'one' => q({0} msec.),
						'other' => q({0} msec.),
					},
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					'month' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} sec.),
						'other' => q({0} sec.),
					},
					'stone' => {
						'name' => q(st.),
					},
					'week' => {
						'name' => q(w),
						'one' => q({0} w),
						'other' => q({0} w),
					},
					'yard' => {
						'name' => q(yd.),
					},
					'year' => {
						'name' => q(y),
						'one' => q({0} y),
						'other' => q({0} y),
					},
				},
				'short' => {
					'acre' => {
						'one' => q({0} ac.),
						'other' => q({0} ac.),
					},
					'acre-foot' => {
						'name' => q(acre ft.),
						'one' => q({0} ac. ft.),
						'other' => q({0} ac. ft.),
					},
					'arc-minute' => {
						'name' => q(arcmins.),
						'one' => q({0} arcmin.),
						'other' => q({0} arcmins.),
					},
					'arc-second' => {
						'name' => q(arcsecs.),
						'one' => q({0} arcsec.),
						'other' => q({0} arcsecs.),
					},
					'astronomical-unit' => {
						'name' => q(AU),
						'one' => q({0} AU),
						'other' => q({0} AU),
					},
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'century' => {
						'name' => q(c.),
						'one' => q({0} c.),
						'other' => q({0} c.),
					},
					'cubic-foot' => {
						'name' => q(cu. feet),
						'one' => q({0} cu. ft.),
						'other' => q({0} cu. ft.),
					},
					'cubic-inch' => {
						'name' => q(cu. inches),
						'one' => q({0} cu. in.),
						'other' => q({0} cu. in.),
					},
					'cubic-mile' => {
						'name' => q(cu. mi.),
						'one' => q({0} cu. mi.),
						'other' => q({0} cu. mi.),
					},
					'cubic-yard' => {
						'name' => q(cu. yards),
						'one' => q({0} cu. yd.),
						'other' => q({0} cu. yd.),
					},
					'cup' => {
						'one' => q({0} c.),
						'other' => q({0} c.),
					},
					'day' => {
						'per' => q({0}/day),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'degree' => {
						'name' => q(deg.),
						'one' => q({0} deg.),
						'other' => q({0} deg.),
					},
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fathom' => {
						'one' => q({0} fm.),
						'other' => q({0} fm.),
					},
					'fluid-ounce' => {
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
					},
					'foot' => {
						'one' => q({0} ft.),
						'other' => q({0} ft.),
						'per' => q({0}/ft.),
					},
					'furlong' => {
						'one' => q({0} fur.),
						'other' => q({0} fur.),
					},
					'gallon' => {
						'name' => q(US gal.),
						'one' => q({0} US gal.),
						'other' => q({0} US gal.),
						'per' => q({0}/US gal.),
					},
					'gallon-imperial' => {
						'name' => q(gal.),
						'one' => q({0} gal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hour' => {
						'name' => q(hrs.),
						'one' => q({0} hr.),
						'other' => q({0} hrs.),
						'per' => q({0}/hr.),
					},
					'inch' => {
						'one' => q({0} in.),
						'other' => q({0} in.),
						'per' => q({0}/in.),
					},
					'inch-hg' => {
						'name' => q(inHg),
					},
					'joule' => {
						'name' => q(J),
					},
					'karat' => {
						'name' => q(karats),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kilojoule' => {
						'name' => q(kJ),
					},
					'kilometer-per-hour' => {
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
					},
					'knot' => {
						'name' => q(kn.),
						'one' => q({0} kn.),
						'other' => q({0} kn.),
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
					},
					'meter-per-second-squared' => {
						'name' => q(metres/sec.²),
					},
					'microsecond' => {
						'name' => q(μsec.),
					},
					'mile' => {
						'one' => q({0} mi.),
						'other' => q({0} mi.),
					},
					'mile-per-gallon' => {
						'name' => q(mi./US gal.),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mi./gal.),
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
						'name' => q(millisecs.),
						'one' => q({0} millisec.),
						'other' => q({0} millisecs.),
					},
					'minute' => {
						'name' => q(mins.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					'month' => {
						'name' => q(mos.),
						'one' => q({0} mo.),
						'other' => q({0} mos.),
						'per' => q({0}/mo.),
					},
					'nanosecond' => {
						'name' => q(nanosec.),
						'one' => q({0} nanosec.),
						'other' => q({0} nanosec.),
					},
					'nautical-mile' => {
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
					},
					'ohm' => {
						'name' => q(Ω),
					},
					'ounce' => {
						'name' => q(oz.),
						'one' => q({0} oz.),
						'other' => q({0} oz.),
						'per' => q({0}/oz.),
					},
					'ounce-troy' => {
						'name' => q(oz. troy),
						'one' => q({0} oz t.),
						'other' => q({0} oz t.),
					},
					'pint' => {
						'one' => q({0} pt.),
						'other' => q({0} pt.),
					},
					'point' => {
						'one' => q({0} pt.),
						'other' => q({0} pts.),
					},
					'pound' => {
						'name' => q(lb.),
						'one' => q({0} lb.),
						'other' => q({0} lb.),
						'per' => q({0}/lb.),
					},
					'quart' => {
						'name' => q(qt.),
						'one' => q({0} qt.),
						'other' => q({0} qt.),
					},
					'radian' => {
						'name' => q(rad),
					},
					'second' => {
						'name' => q(secs.),
						'one' => q({0} sec.),
						'other' => q({0} secs.),
						'per' => q({0}/sec.),
					},
					'square-foot' => {
						'name' => q(sq. feet),
						'one' => q({0} sq. ft.),
						'other' => q({0} sq. ft.),
					},
					'square-inch' => {
						'name' => q(sq. inches),
						'one' => q({0} sq. in.),
						'other' => q({0} sq. in.),
						'per' => q({0}/sq. in.),
					},
					'square-mile' => {
						'name' => q(sq. miles),
						'one' => q({0} sq. mi.),
						'other' => q({0} sq. mi.),
						'per' => q({0}/sq. mi.),
					},
					'square-yard' => {
						'name' => q(sq. yards),
						'one' => q({0} sq. yd.),
						'other' => q({0} sq. yd.),
					},
					'stone' => {
						'one' => q({0} st.),
						'other' => q({0} st.),
					},
					'tablespoon' => {
						'name' => q(tbsp.),
						'one' => q({0} tbsp.),
						'other' => q({0} tbsp.),
					},
					'teaspoon' => {
						'name' => q(tsp.),
						'one' => q({0} tsp.),
						'other' => q({0} tsp.),
					},
					'ton' => {
						'one' => q({0} tn.),
						'other' => q({0} tn.),
					},
					'volt' => {
						'name' => q(V),
					},
					'watt' => {
						'name' => q(W),
					},
					'week' => {
						'name' => q(wks.),
						'one' => q({0} wk.),
						'other' => q({0} wks.),
						'per' => q({0}/wk.),
					},
					'yard' => {
						'one' => q({0} yd.),
						'other' => q({0} yd.),
					},
					'year' => {
						'name' => q(yrs.),
						'one' => q({0} yr.),
						'other' => q({0} yrs.),
						'per' => q({0}/yr.),
					},
				},
			} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'exponential' => q(e),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'CAD' => {
			symbol => '$',
		},
		'ILS' => {
			display_name => {
				'one' => q(Israeli new sheqel),
				'other' => q(Israeli new sheqels),
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
							'Jan',
							'Feb',
							'Mar',
							'Apr',
							'',
							'Jun',
							'Jul',
							'Aug',
							'Sep',
							'Oct',
							'Nov',
							'Dec'
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
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
					'pm' => q{p.m.},
					'am' => q{a.m.},
				},
				'abbreviated' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'wide' => {
					'pm' => q{p.m.},
					'am' => q{a.m.},
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
		'chinese' => {
		},
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
		'chinese' => {
			'full' => q{EEEE, MMMM d, r(U)},
			'long' => q{MMMM d, r(U)},
			'medium' => q{MMM d, r},
			'short' => q{r-MM-dd},
		},
		'generic' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{y-MM-dd},
		},
		'islamic' => {
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
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
		'chinese' => {
		},
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
		'islamic' => {
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			MEd => q{E, MM-dd},
			MMMd => q{MMM d},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMd => q{MMM d, y G},
		},
		'generic' => {
			Ed => q{d E},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			MEd => q{E, d/M},
			MMMEd => q{E, MMM d},
			MMMd => q{MMM d},
			Md => q{d/M},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{d/M/y GGGGG},
		},
		'chinese' => {
			Ed => q{d E},
			GyMMMEd => q{E, MMM d, r(U)},
			GyMMMd => q{MMM d, r},
			MEd => q{E, d/M},
			MMMEd => q{E, MMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{d/M},
			UMMMd => q{MMM d, U},
			UMd => q{d/M/U},
			yMd => q{d/M/r},
			yyyyM => q{M/r},
			yyyyMEd => q{E, d/M/r},
			yyyyMMMEd => q{E, MMM d, r(U)},
			yyyyMMMd => q{MMM d, r},
			yyyyMd => q{d/M/r},
		},
		'gregorian' => {
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			MEd => q{E, d/M},
			MMMEd => q{E, MMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			MMdd => q{dd/MM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d, y},
			yMd => q{d/M/y},
			yw => q{'week' w 'of' y},
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
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'chinese' => {
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, U},
				d => q{E, MMM d – E, MMM d, U},
				y => q{E, MMM d, U – E, MMM d, U},
			},
			yMMMd => {
				M => q{MMM d – MMM d, U},
				d => q{MMM d – d, U},
				y => q{MMM d, U – MMM d, U},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
		'gregorian' => {
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Daylight Saving Time),
		'Alaska' => {
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'America_Central' => {
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Argentina' => {
			long => {
				'generic' => q#Argentina Time#,
				'standard' => q#Argentina Standard Time#,
			},
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Atlantic' => {
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Newfoundland' => {
			short => {
				'daylight' => q#NDT#,
				'generic' => q#NT#,
				'standard' => q#NST#,
			},
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
