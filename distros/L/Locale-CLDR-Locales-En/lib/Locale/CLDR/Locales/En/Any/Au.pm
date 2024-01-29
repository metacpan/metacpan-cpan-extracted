=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Any::Au - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::Au;
# This file auto generated from Data\common\main\en_AU.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
				'ar_001' => 'Modern Standard Arabic',
 				'bn' => 'Bengali',
 				'ckb@alt=menu' => 'Kurdish (Central)',
 				'ckb@alt=variant' => 'Kurdish (Sorani)',
 				'de_AT' => 'Austrian German',
 				'de_CH' => 'Swiss High German',
 				'en_AU' => 'Australian English',
 				'en_CA' => 'Canadian English',
 				'en_GB' => 'British English',
 				'en_GB@alt=short' => 'UK English',
 				'en_US' => 'United States English',
 				'en_US@alt=short' => 'US English',
 				'es_419' => 'Latin American Spanish',
 				'es_ES' => 'European Spanish',
 				'es_MX' => 'Mexican Spanish',
 				'fr_CA' => 'Canadian French',
 				'fr_CH' => 'Swiss French',
 				'pt_BR' => 'Brazilian Portuguese',
 				'pt_PT' => 'European Portuguese',
 				'ro_MD' => 'Moldovan',
 				'sr_ME' => 'Montenegrin',
 				'zh_Hans' => 'Simplified Chinese',
 				'zh_Hant' => 'Traditional Chinese',

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

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'SIMPLE' => 'SIMPLE',

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

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
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
					'mass-metric-ton' => {
						'one' => q(tonne),
						'other' => q({0} tonnes),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'one' => q(tonne),
						'other' => q({0} tonnes),
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
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(degrees),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounces),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounces),
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
					'duration-minute' => {
						'name' => q(min.),
						'one' => q({0}min.),
						'other' => q({0}min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min.),
						'one' => q({0}min.),
						'other' => q({0}min.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sec.),
						'one' => q({0}s.),
						'other' => q({0}s.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sec.),
						'one' => q({0}s.),
						'other' => q({0}s.),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
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
					'temperature-generic' => {
						'name' => q(°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
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
						'name' => q(dsp Imp.),
						'one' => q({0}dsp-Imp.),
						'other' => q({0}dsp-Imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp Imp.),
						'one' => q({0}dsp-Imp.),
						'other' => q({0}dsp-Imp.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal. US),
						'one' => q({0}gal. US),
						'other' => q({0}gal. US),
						'per' => q({0}/gal. US),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal. US),
						'one' => q({0}gal. US),
						'other' => q({0}gal. US),
						'per' => q({0}/gal. US),
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
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp.),
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
					'angle-degree' => {
						'one' => q({0} deg.),
						'other' => q({0} deg.),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} deg.),
						'other' => q({0} deg.),
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
					'duration-minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} mins),
						'per' => q({0}/min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} mins),
						'per' => q({0}/min.),
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
					'length-light-year' => {
						'one' => q({0} l.y.),
						'other' => q({0} l.y.),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} l.y.),
						'other' => q({0} l.y.),
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
					'temperature-generic' => {
						'name' => q(deg.),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(deg.),
						'one' => q({0}°),
						'other' => q({0}°),
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
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(US gal.),
						'one' => q({0} gal. US),
						'other' => q({0} gal. US),
						'per' => q({0}/gal. US),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(US gal.),
						'one' => q({0} gal. US),
						'other' => q({0} gal. US),
						'per' => q({0}/gal. US),
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
		'AED' => {
			symbol => 'AED',
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'one' => q(Afghan Afghani),
				'other' => q(Afghan Afghanis),
			},
		},
		'ALL' => {
			symbol => 'ALL',
		},
		'AMD' => {
			symbol => 'AMD',
		},
		'AOA' => {
			symbol => 'AOA',
		},
		'ARS' => {
			symbol => 'ARS',
		},
		'AUD' => {
			symbol => '$',
		},
		'AZN' => {
			symbol => 'AZN',
		},
		'BAM' => {
			symbol => 'BAM',
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
			symbol => 'BDT',
		},
		'BGN' => {
			symbol => 'BGN',
		},
		'BHD' => {
			symbol => 'BHD',
		},
		'BIF' => {
			symbol => 'BIF',
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda Dollar),
				'one' => q(Bermuda dollar),
				'other' => q(Bermuda dollars),
			},
		},
		'BND' => {
			symbol => 'BND',
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviano),
				'one' => q(boliviano),
				'other' => q(bolivianos),
			},
		},
		'BRL' => {
			symbol => 'BRL',
		},
		'BTN' => {
			symbol => 'BTN',
		},
		'BWP' => {
			symbol => 'BWP',
		},
		'CAD' => {
			symbol => 'CAD',
		},
		'CDF' => {
			symbol => 'CDF',
		},
		'CHF' => {
			symbol => 'CHF',
		},
		'CLP' => {
			symbol => 'CLP',
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
		'COP' => {
			symbol => 'COP',
		},
		'CUP' => {
			symbol => '₱',
		},
		'CVE' => {
			symbol => 'CVE',
		},
		'CZK' => {
			symbol => 'CZK',
		},
		'DJF' => {
			symbol => 'DJF',
		},
		'DZD' => {
			symbol => 'DZD',
		},
		'EGP' => {
			symbol => 'EGP',
		},
		'ERN' => {
			symbol => 'ERN',
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'one' => q(Ethiopian birr),
				'other' => q(Ethiopian birrs),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
		},
		'FKP' => {
			symbol => 'FKP',
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
		'GHS' => {
			symbol => 'GHS',
		},
		'GIP' => {
			symbol => 'GIP',
		},
		'GMD' => {
			symbol => 'GMD',
		},
		'GNF' => {
			symbol => 'GNF',
		},
		'GYD' => {
			symbol => 'GYD',
		},
		'HKD' => {
			symbol => 'HKD',
		},
		'HRK' => {
			symbol => 'HRK',
		},
		'HUF' => {
			symbol => 'HUF',
		},
		'IDR' => {
			symbol => 'IDR',
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
		'IQD' => {
			symbol => 'IQD',
		},
		'IRR' => {
			symbol => 'IRR',
		},
		'ISK' => {
			symbol => 'ISK',
		},
		'JOD' => {
			symbol => 'JOD',
		},
		'JPY' => {
			symbol => 'JPY',
		},
		'KES' => {
			symbol => 'KES',
		},
		'KGS' => {
			symbol => 'KGS',
		},
		'KHR' => {
			symbol => 'KHR',
		},
		'KMF' => {
			symbol => 'KMF',
		},
		'KPW' => {
			symbol => 'KPW',
		},
		'KRW' => {
			symbol => 'KRW',
		},
		'KWD' => {
			symbol => 'KWD',
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'one' => q(Kazakhstani tenge),
				'other' => q(Kazakhstani tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'one' => q(Laotian kip),
				'other' => q(Laotian kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
		},
		'LKR' => {
			symbol => 'LKR',
		},
		'LRD' => {
			symbol => 'LRD',
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'one' => q(Lesotho loti),
				'other' => q(Lesotho lotis),
			},
		},
		'LYD' => {
			symbol => 'LYD',
		},
		'MAD' => {
			symbol => 'MAD',
		},
		'MDL' => {
			symbol => 'MDL',
		},
		'MGA' => {
			symbol => 'MGA',
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'one' => q(Macedonian denar),
				'other' => q(Macedonian denar),
			},
		},
		'MMK' => {
			symbol => 'MMK',
		},
		'MNT' => {
			symbol => 'MNT',
		},
		'MOP' => {
			symbol => 'MOP',
		},
		'MRO' => {
			symbol => 'MRO',
		},
		'MUR' => {
			symbol => 'MUR',
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'one' => q(Maldivian rufiyaa),
				'other' => q(Maldivian rufiyaas),
			},
		},
		'MWK' => {
			symbol => 'MWK',
		},
		'MXN' => {
			symbol => 'MXN',
		},
		'MYR' => {
			symbol => 'MYR',
		},
		'MZN' => {
			symbol => 'MZN',
		},
		'NAD' => {
			symbol => 'NAD',
		},
		'NGN' => {
			symbol => 'NGN',
		},
		'NOK' => {
			symbol => 'NOK',
		},
		'NPR' => {
			symbol => 'NPR',
		},
		'NZD' => {
			symbol => 'NZD',
		},
		'OMR' => {
			symbol => 'OMR',
		},
		'PEN' => {
			symbol => 'PEN',
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'one' => q(Papua New Guinean kina),
				'other' => q(Papua New Guinean kinas),
			},
		},
		'PHP' => {
			symbol => 'PHP',
		},
		'PLN' => {
			symbol => 'PLN',
		},
		'PYG' => {
			symbol => 'PYG',
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Qatari Riyal),
				'one' => q(Qatari riyal),
				'other' => q(Quatari riyals),
			},
		},
		'RON' => {
			symbol => 'RON',
		},
		'RSD' => {
			symbol => 'RSD',
		},
		'RUB' => {
			symbol => 'RUB',
		},
		'RWF' => {
			symbol => 'RWF',
		},
		'SAR' => {
			symbol => 'SAR',
		},
		'SBD' => {
			symbol => 'SBD',
		},
		'SCR' => {
			symbol => 'Rs',
		},
		'SDG' => {
			symbol => 'SDG',
		},
		'SEK' => {
			symbol => 'SEK',
		},
		'SGD' => {
			symbol => 'SGD',
		},
		'SHP' => {
			symbol => 'SHP',
		},
		'SLL' => {
			symbol => 'SLL',
		},
		'SOS' => {
			symbol => 'SOS',
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Suriname Dollar),
				'one' => q(Suriname dollar),
				'other' => q(Suriname dollars),
			},
		},
		'SSP' => {
			symbol => 'SSP',
		},
		'SYP' => {
			symbol => 'SYP',
		},
		'SZL' => {
			symbol => 'SZL',
		},
		'THB' => {
			symbol => '฿',
		},
		'TJS' => {
			symbol => 'TJS',
		},
		'TMT' => {
			symbol => 'TMT',
		},
		'TND' => {
			symbol => 'TND',
		},
		'TOP' => {
			symbol => 'TOP',
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
		'TZS' => {
			symbol => 'TZS',
		},
		'UAH' => {
			symbol => 'UAH',
		},
		'UGX' => {
			symbol => 'UGX',
		},
		'USD' => {
			symbol => 'USD',
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Peso Uruguayo),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'one' => q(Uzbekistani som),
				'other' => q(Uzbekistani soms),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'one' => q(Venezuelan bolívar),
				'other' => q(Venezuelan bolívars),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(VES),
				'one' => q(VES),
				'other' => q(VES),
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
			symbol => 'VUV',
			display_name => {
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatus),
			},
		},
		'WST' => {
			symbol => 'WST',
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
		'YER' => {
			symbol => 'YER',
		},
		'ZAR' => {
			symbol => 'ZAR',
		},
		'ZMW' => {
			symbol => 'ZMW',
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'chinese' => {
				'format' => {
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Mo1',
							'Mo2',
							'Mo3',
							'Mo4',
							'Mo5',
							'Mo6',
							'Mo7',
							'Mo8',
							'Mo9',
							'Mo10',
							'Mo11',
							'Mo12'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'First Month',
							'Second Month',
							'Third Month',
							'Fourth Month',
							'Fifth Month',
							'Sixth Month',
							'Seventh Month',
							'Eighth Month',
							'Ninth Month',
							'Tenth Month',
							'Eleventh Month',
							'Twelfth Month'
						],
						leap => [
							
						],
					},
				},
			},
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
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
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
					wide => {
						nonleap => [
							'January',
							'February',
							'March',
							'April',
							'May',
							'June',
							'July',
							'August',
							'September',
							'October',
							'November',
							'December'
						],
						leap => [
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
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
					short => {
						mon => 'Mon',
						tue => 'Tu',
						wed => 'Wed',
						thu => 'Th',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Su'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mon',
						tue => 'Tue',
						wed => 'Wed',
						thu => 'Thu',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Sun'
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
						mon => 'Mon',
						tue => 'Tu',
						wed => 'Wed',
						thu => 'Th',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Su'
					},
					wide => {
						mon => 'Monday',
						tue => 'Tuesday',
						wed => 'Wednesday',
						thu => 'Thursday',
						fri => 'Friday',
						sat => 'Saturday',
						sun => 'Sunday'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => '1st quarter',
						1 => '2nd quarter',
						2 => '3rd quarter',
						3 => '4th quarter'
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
			if ($_ eq 'chinese') {
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
			if ($_ eq 'indian') {
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
					'afternoon1' => q{afternoon},
					'evening1' => q{evening},
					'midnight' => q{midnight},
					'morning1' => q{morning},
					'night1' => q{night},
					'noon' => q{midday},
				},
				'narrow' => {
					'afternoon1' => q{afternoon},
					'am' => q{am},
					'evening1' => q{evening},
					'midnight' => q{midnight},
					'morning1' => q{morning},
					'night1' => q{night},
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
					'afternoon1' => q{afternoon},
					'am' => q{am},
					'evening1' => q{evening},
					'midnight' => q{midnight},
					'morning1' => q{morning},
					'night1' => q{night},
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
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'indian' => {
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
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
		},
		'indian' => {
		},
		'islamic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'indian' => {
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
			'full' => q{{1} 'at' {0}},
			'long' => q{{1} 'at' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'indian' => {
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
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{LL},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			d => q{d},
			y => q{y G},
			yMEd => q{E, dd/MM/y},
			yMd => q{dd/MM/y},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
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
				G => q{E dd/MM/y GGGGG – E dd/MM/y GGGGG},
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
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
		'gregorian' => {
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMMEd => {
				G => q{E, d MMM, y G – E, d MMM, y G},
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				G => q{d MMM, y G – d MMM, y G},
				M => q{d MMM – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			MMMd => {
				d => q{d – d MMM},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtZeroFormat => q(GMT),
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
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
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
