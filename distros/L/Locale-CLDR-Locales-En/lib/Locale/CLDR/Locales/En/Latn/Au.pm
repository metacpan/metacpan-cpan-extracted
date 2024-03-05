=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Latn::Au - Package for language English

=cut

package Locale::CLDR::Locales::En::Latn::Au;
# This file auto generated from Data\common\main\en_AU.xml
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

extends('Locale::CLDR::Locales::En::Latn::001');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'bn' => 'Bengali',
 				'ckb@alt=menu' => 'Kurdish (Central)',
 				'ckb@alt=variant' => 'Kurdish (Sorani)',
 				'en_US' => 'United States English',
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

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'001' => 'World',
 			'BL' => 'St. Barthélemy',
 			'KN' => 'St. Kitts & Nevis',
 			'LC' => 'St. Lucia',
 			'MF' => 'St. Martin',
 			'VC' => 'St. Vincent & Grenadines',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'colcasefirst' => 'Upper case / Lower case Ordering',
 			'x' => 'Private Use',
 			'x0' => 'Private Use Transform',

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

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(per mill),
						'one' => q({0} per mill),
						'other' => q({0} per mill),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(per mill),
						'one' => q({0} per mill),
						'other' => q({0} per mill),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt hours),
						'one' => q({0} kilowatt hour),
						'other' => q({0} kilowatt hours),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt hours),
						'one' => q({0} kilowatt hour),
						'other' => q({0} kilowatt hours),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometre),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometre),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrometres),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrometres),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pounds per square inch),
						'one' => q({0} pound per square inch),
						'other' => q({0} pounds per square inch),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pounds per square inch),
						'one' => q({0} pound per square inch),
						'other' => q({0} pounds per square inch),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(degrees),
						'one' => q({0} degree),
						'other' => q({0} degrees),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(degrees),
						'one' => q({0} degree),
						'other' => q({0} degrees),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fluid ounces),
						'one' => q({0} Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounces),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fluid ounces),
						'one' => q({0} Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounces),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(C.),
						'one' => q({0}C.),
						'other' => q({0}C.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(C.),
						'one' => q({0}C.),
						'other' => q({0}C.),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsec.),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsec.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msec.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msec.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sec.),
						'one' => q({0}s.),
						'other' => q({0}s.),
						'per' => q({0} ps.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sec.),
						'one' => q({0}s.),
						'other' => q({0}s.),
						'per' => q({0} ps.),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} bus.),
						'other' => q({0} bus.),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} bus.),
						'other' => q({0} bus.),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsp US),
						'one' => q({0}dsp US),
						'other' => q({0}dsp US),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp US),
						'one' => q({0}dsp US),
						'other' => q({0}dsp US),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal US),
						'one' => q({0} gal US),
						'other' => q({0} gal US),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal US),
						'one' => q({0} gal US),
						'other' => q({0} gal US),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal.),
						'one' => q({0}gal.),
						'other' => q({0}gal.),
						'per' => q({0}/gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal.),
						'one' => q({0}gal.),
						'other' => q({0}gal.),
						'per' => q({0}/gal.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt US),
						'one' => q({0}qt US),
						'other' => q({0}qt US),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt US),
						'one' => q({0}qt US),
						'other' => q({0}qt US),
					},
				},
				'short' => {
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin.),
						'one' => q({0} arcmin.),
						'other' => q({0} arcmin.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin.),
						'one' => q({0} arcmin.),
						'other' => q({0} arcmin.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsec.),
						'one' => q({0} arcsec.),
						'other' => q({0} arcsec.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsec.),
						'one' => q({0} arcsec.),
						'other' => q({0} arcsec.),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(per mill),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(per mill),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miles/gal. US),
						'one' => q({0} m.p.g. US),
						'other' => q({0} m.p.g. US),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miles/gal. US),
						'one' => q({0} m.p.g. US),
						'other' => q({0} m.p.g. US),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miles/gal.),
						'one' => q({0} m.p.g.),
						'other' => q({0} m.p.g.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miles/gal.),
						'one' => q({0} m.p.g.),
						'other' => q({0} m.p.g.),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(C.),
						'one' => q({0} C.),
						'other' => q({0} C.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(C.),
						'one' => q({0} C.),
						'other' => q({0} C.),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsec.),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsec.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisec.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisec.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosec.),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosec.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} secs),
						'per' => q({0} ps.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} secs),
						'per' => q({0} ps.),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(AU),
						'one' => q({0} AU),
						'other' => q({0} AU),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(AU),
						'one' => q({0} AU),
						'other' => q({0} AU),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} CM),
						'other' => q({0} CM),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} CM),
						'other' => q({0} CM),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(in Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(in Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metres/sec.),
						'one' => q({0} m/s.),
						'other' => q({0} m/s.),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metres/sec.),
						'one' => q({0} m/s.),
						'other' => q({0} m/s.),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(deg C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(deg C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(deg F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(deg F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(deg.),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(deg.),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} bus.),
						'other' => q({0} bus.),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} bus.),
						'other' => q({0} bus.),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
						'one' => q({0} fl oz Imp.),
						'other' => q({0} fl oz Imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
						'one' => q({0} fl oz Imp.),
						'other' => q({0} fl oz Imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal US),
						'one' => q({0} gal US),
						'other' => q({0} gal US),
						'per' => q({0}/gal US),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal US),
						'one' => q({0} gal US),
						'other' => q({0} gal US),
						'per' => q({0}/gal US),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal.),
						'one' => q({0} gal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal.),
						'one' => q({0} gal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
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
		'AFN' => {
			display_name => {
				'one' => q(Afghan Afghani),
				'other' => q(Afghan Afghanis),
			},
		},
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
			display_name => {
				'currency' => q(Bolivian boliviano),
			},
		},
		'BRL' => {
			symbol => 'BRL',
		},
		'CAD' => {
			symbol => 'CAD',
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
		'ETB' => {
			display_name => {
				'one' => q(Ethiopian birr),
				'other' => q(Ethiopian birrs),
			},
		},
		'EUR' => {
			symbol => 'EUR',
		},
		'GBP' => {
			symbol => 'GBP',
		},
		'GEL' => {
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
		'LSL' => {
			display_name => {
				'one' => q(Lesotho loti),
				'other' => q(Lesotho lotis),
			},
		},
		'MKD' => {
			display_name => {
				'one' => q(Macedonian denar),
				'other' => q(Macedonian denar),
			},
		},
		'MVR' => {
			display_name => {
				'one' => q(Maldivian rufiyaa),
				'other' => q(Maldivian rufiyaas),
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
		'PHP' => {
			symbol => 'PHP',
		},
		'PYG' => {
			symbol => 'Gs',
		},
		'QAR' => {
			display_name => {
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
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leonean Leone \(1964–2022\)),
				'one' => q(Sierra Leonean leone \(1964–2022\)),
				'other' => q(Sierra Leonean leones \(1964–2022\)),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Suriname Dollar),
				'one' => q(Suriname dollar),
				'other' => q(Suriname dollars),
			},
		},
		'TRY' => {
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
		'VES' => {
			display_name => {
				'currency' => q(Venezuelan bolívar),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'one' => q(Vietnamese dong),
				'other' => q(Vietnamese dongs),
			},
		},
		'VUV' => {
			display_name => {
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatus),
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
							'Jan',
							'Feb',
							'Mar',
							'Apr',
							'May',
							'June',
							'July',
							'Aug',
							'Sept',
							'Oct',
							'Nov',
							'Dec'
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
							'May',
							'June',
							'July',
							'Aug',
							'Sept',
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
					narrow => {
						mon => 'M.',
						tue => 'Tu.',
						wed => 'W.',
						thu => 'Th.',
						fri => 'F.',
						sat => 'Sa.',
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
			if ($_ eq 'generic') {
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
			if ($_ eq 'islamic') {
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
					'afternoon1' => q{in the afternoon},
					'evening1' => q{in the evening},
					'midnight' => q{midnight},
					'morning1' => q{in the morning},
					'night1' => q{at night},
					'noon' => q{midday},
				},
				'narrow' => {
					'afternoon1' => q{in the afternoon},
					'am' => q{am},
					'evening1' => q{in the evening},
					'midnight' => q{midnight},
					'morning1' => q{in the morning},
					'night1' => q{at night},
					'noon' => q{midday},
					'pm' => q{pm},
				},
				'wide' => {
					'afternoon1' => q{in the afternoon},
					'evening1' => q{in the evening},
					'midnight' => q{midnight},
					'morning1' => q{in the morning},
					'night1' => q{at night},
					'noon' => q{midday},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'noon' => q{midday},
				},
				'narrow' => {
					'am' => q{am},
					'noon' => q{midday},
					'pm' => q{pm},
				},
				'wide' => {
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
			GyMMMEEEEd => q{EEEE d MMM y G},
			MMMEEEEd => q{EEEE d MMM},
			MMMMEEEEd => q{EEEE d MMMM},
			yMEd => q{E, dd/MM/y},
			yMd => q{dd/MM/y},
			yyyyMMMEEEEd => q{EEEE d MMM y G},
			yyyyMMMMEEEEd => q{EEEE d MMMM y G},
		},
		'gregorian' => {
			GyMMMEEEEd => q{EEEE d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, d/M},
			MMMEEEEd => q{EEEE d MMM},
			MMMMEEEEd => q{EEEE d MMMM},
			Md => q{d/M},
			yMMMEEEEd => q{EEEE d MMM y},
			yMMMMEEEEd => q{EEEE d MMMM y},
		},
		'islamic' => {
			Ed => q{E d},
			M => q{LL},
			MMMEd => q{E, d MMM},
			yyyyM => q{MM/y GGGGG},
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
			GyMEd => {
				G => q{E dd/MM/y GGGGG – E dd/MM/y GGGGG},
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMEEEEd => {
				M => q{EEEE d MMM – EEEE d MMM},
				d => q{EEEE d MMM – EEEE d MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			yMMMEEEEd => {
				M => q{EEEE d MMM – EEEE d MMM y G},
				d => q{EEEE d MMM – EEEE d MMM y G},
				y => q{EEEE d MMM y – EEEE d MMM y G},
			},
			yMMMEd => {
				d => q{E, d MMM – E, d MMM y G},
			},
			yMMMMEEEEd => {
				M => q{EEEE d MMMM – EEEE d MMMM y G},
				d => q{EEEE d MMMM – EEEE d MMMM y G},
				y => q{EEEE d MMMM y – EEEE d MMMM y G},
			},
		},
		'gregorian' => {
			GyMEd => {
				G => q{E, d/M/y G – E, d/M/y G},
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			GyMMMEEEEd => {
				G => q{EEEE d MMM y G – EEEE d MMM y G},
				M => q{EEEE d MMM – EEEE d MMM y G},
				d => q{EEEE d MMM – EEEE d MMM y G},
				y => q{EEEE d MMM y – EEEE d MMM y G},
			},
			GyMd => {
				G => q{d/M/y G – d/M/y G},
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
			yMMMEEEEd => {
				M => q{EEEE d MMM – EEEE d MMM y},
				d => q{EEEE d – EEEE d MMM y},
				y => q{EEEE d MMM y – EEEE d MMM y},
			},
			yMMMMEEEEd => {
				M => q{EEEE d MMMM – EEEE d MMMM y},
				d => q{EEEE d – EEEE d MMMM y},
				y => q{EEEE d MMMM y – EEEE d MMMM y},
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
		'Arabian' => {
			long => {
				'daylight' => q#Arabia Daylight Time#,
				'generic' => q#Arabia Time#,
				'standard' => q#Arabia Standard Time#,
			},
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
		'Gulf' => {
			short => {
				'standard' => q#Gulf ST#,
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
