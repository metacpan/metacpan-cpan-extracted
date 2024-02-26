=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Latn::Ca - Package for language English

=cut

package Locale::CLDR::Locales::En::Latn::Ca;
# This file auto generated from Data\common\main\en_CA.xml
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

extends('Locale::CLDR::Locales::En::Latn');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar_001' => 'Arabic (Modern Standard)',
 				'bn' => 'Bengali',
 				'mfe' => 'Mauritian Creole',
 				'my@alt=variant' => 'Myanmar language',
 				'nds_NL' => 'West Low German',
 				'ro_MD' => 'Moldovan',

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
			'057' => 'Micronesian region',
 			'AG' => 'Antigua and Barbuda',
 			'BA' => 'Bosnia and Herzegovina',
 			'BL' => 'Saint-Barthélemy',
 			'EA' => 'Ceuta and Melilla',
 			'GS' => 'South Georgia and South Sandwich Islands',
 			'HM' => 'Heard and McDonald Islands',
 			'KN' => 'Saint Kitts and Nevis',
 			'LC' => 'Saint Lucia',
 			'MF' => 'Saint Martin',
 			'MO@alt=short' => 'Macau',
 			'PM' => 'Saint-Pierre-et-Miquelon',
 			'PS' => 'Palestinian territories',
 			'SH' => 'Saint Helena',
 			'SJ' => 'Svalbard and Jan Mayen',
 			'ST' => 'São Tomé and Príncipe',
 			'TC' => 'Turks and Caicos Islands',
 			'TT' => 'Trinidad and Tobago',
 			'UM' => 'US Outlying Islands',
 			'VC' => 'Saint Vincent and the Grenadines',
 			'VI' => 'US Virgin Islands',
 			'WF' => 'Wallis and Futuna',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'colcaselevel' => 'Case-Sensitive Sorting',
 			'hc' => 'Hour cycle (12 vs. 24)',
 			't0' => 'Machine-Translated',

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
 				'buddhist' => q{Buddhist calendar},
 				'chinese' => q{Chinese calendar},
 				'coptic' => q{Coptic calendar},
 				'dangi' => q{Dangi calendar},
 				'ethiopic' => q{Ethiopic calendar},
 				'ethiopic-amete-alem' => q{Ethiopic Amete Alem calendar},
 				'gregorian' => q{Gregorian calendar},
 				'hebrew' => q{Hebrew calendar},
 				'indian' => q{Indian national calendar},
 				'islamic' => q{Hijri calendar},
 				'islamic-civil' => q{Hijri calendar (tabular, civil epoch)},
 				'islamic-tbla' => q{Hijri calendar (tabular, astronomical epoch)},
 				'islamic-umalqura' => q{Hijri calendar (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 calendar},
 				'japanese' => q{Japanese calendar},
 				'persian' => q{Persian calendar},
 				'roc' => q{Minguo calendar},
 			},
 			'colnormalization' => {
 				'no' => q{Sort Without Normalisation},
 				'yes' => q{Sort Unicode Normalised},
 			},
 			'd0' => {
 				'ascii' => q{to ASCII},
 				'fwidth' => q{to full width},
 				'hwidth' => q{to half width},
 				'lower' => q{to lowercase},
 				'title' => q{to title case},
 				'upper' => q{to uppercase},
 			},
 			'fw' => {
 				'fri' => q{First day of week is Friday},
 				'mon' => q{First day of week is Monday},
 				'sat' => q{First day of week is Saturday},
 				'sun' => q{First day of week is Sunday},
 				'thu' => q{First day of week is Thursday},
 				'tue' => q{First day of week is Tuesday},
 				'wed' => q{First day of week is Wednesday},
 			},
 			'hc' => {
 				'h11' => q{12-hour system (0–11)},
 				'h12' => q{12-hour system (1–12)},
 				'h23' => q{24-hour system (0–23)},
 				'h24' => q{24-hour system (1–24)},
 			},
 			'm0' => {
 				'bgn' => q{US BGN transliteration},
 				'ungegn' => q{UN GEGN transliteration},
 			},
 			'ms' => {
 				'ussystem' => q{US measurement system},
 			},
 			'numbers' => {
 				'adlm' => q{Adlam digits},
 				'arab' => q{Arabic-Indic digits},
 				'armn' => q{Armenian numerals},
 				'armnlow' => q{Armenian lowercase numerals},
 				'beng' => q{Bangla digits},
 				'cakm' => q{Chakma digits},
 				'deva' => q{Devanagari digits},
 				'ethi' => q{Ethiopic numerals},
 				'geor' => q{Georgian numerals},
 				'grek' => q{Greek numerals},
 				'greklow' => q{Greek lowercase numerals},
 				'gujr' => q{Gujarati digits},
 				'guru' => q{Gurmukhi digits},
 				'hanidec' => q{Chinese decimal numerals},
 				'hebr' => q{Hebrew numerals},
 				'java' => q{Javanese digits},
 				'jpan' => q{Japanese numerals},
 				'jpanfin' => q{Japanese financial numerals},
 				'khmr' => q{Khmer digits},
 				'knda' => q{Kannada digits},
 				'laoo' => q{Lao digits},
 				'latn' => q{Western digits},
 				'mlym' => q{Malayalam digits},
 				'mtei' => q{Meetei Mayek digits},
 				'mymr' => q{Myanmar digits},
 				'native' => q{Native digits},
 				'olck' => q{Ol Chiki digits},
 				'orya' => q{Odia digits},
 				'roman' => q{Roman numerals},
 				'romanlow' => q{Roman lowercase numerals},
 				'tamldec' => q{Tamil digits},
 				'telu' => q{Telugu digits},
 				'thai' => q{Thai digits},
 				'tibt' => q{Tibetan digits},
 				'vaii' => q{Vai digits},
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
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metres per second squared),
						'one' => q({0} metre per second squared),
						'other' => q({0} metres per second squared),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metres per second squared),
						'one' => q({0} metre per second squared),
						'other' => q({0} metres per second squared),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(square centimetres),
						'one' => q({0} square centimetre),
						'other' => q({0} square centimetres),
						'per' => q({0} per square centimetre),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(square centimetres),
						'one' => q({0} square centimetre),
						'other' => q({0} square centimetres),
						'per' => q({0} per square centimetre),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(square kilometres),
						'one' => q({0} square kilometre),
						'other' => q({0} square kilometres),
						'per' => q({0} per square kilometre),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(square kilometres),
						'one' => q({0} square kilometre),
						'other' => q({0} square kilometres),
						'per' => q({0} per square kilometre),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(square metres),
						'one' => q({0} square metre),
						'other' => q({0} square metres),
						'per' => q({0} per square metre),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(square metres),
						'one' => q({0} square metre),
						'other' => q({0} square metres),
						'per' => q({0} per square metre),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrams per decilitre),
						'one' => q({0} milligram per decilitre),
						'other' => q({0} milligrams per decilitre),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrams per decilitre),
						'one' => q({0} milligram per decilitre),
						'other' => q({0} milligrams per decilitre),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimoles per litre),
						'one' => q({0} millimole per litre),
						'other' => q({0} millimoles per litre),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimoles per litre),
						'one' => q({0} millimole per litre),
						'other' => q({0} millimoles per litre),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(per mille),
						'one' => q({0} per mille),
						'other' => q({0} per mille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(per mille),
						'one' => q({0} per mille),
						'other' => q({0} per mille),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(per myriad),
						'one' => q({0} per myriad),
						'other' => q({0} per myriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(per myriad),
						'one' => q({0} per myriad),
						'other' => q({0} per myriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litres per 100 kilometres),
						'one' => q({0} litre per 100 kilometres),
						'other' => q({0} litres per 100 kilometres),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litres per 100 kilometres),
						'one' => q({0} litre per 100 kilometres),
						'other' => q({0} litres per 100 kilometres),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litres per kilometre),
						'one' => q({0} litre per kilometre),
						'other' => q({0} litres per kilometre),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litres per kilometre),
						'one' => q({0} litre per kilometre),
						'other' => q({0} litres per kilometre),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miles per US gallon),
						'one' => q({0} mile per US gallon),
						'other' => q({0} miles per US gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miles per US gallon),
						'one' => q({0} mile per US gallon),
						'other' => q({0} miles per US gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0} kilowatt-hour),
						'other' => q({0} kilowatt-hours),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0} kilowatt-hour),
						'other' => q({0} kilowatt-hours),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-hour per 100 kilometres),
						'one' => q({0} kilowatt-hour per 100 kilometres),
						'other' => q({0} kilowatt-hours per 100 kilometres),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-hour per 100 kilometres),
						'one' => q({0} kilowatt-hour per 100 kilometres),
						'other' => q({0} kilowatt-hours per 100 kilometres),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} dot),
						'other' => q({0} dots),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} dot),
						'other' => q({0} dots),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dots per centimetre),
						'one' => q({0} dot per centimetre),
						'other' => q({0} dots per centimetre),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dots per centimetre),
						'one' => q({0} dot per centimetre),
						'other' => q({0} dots per centimetre),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixels per centimetre),
						'one' => q({0} pixel per centimetre),
						'other' => q({0} pixels per centimetre),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixels per centimetre),
						'one' => q({0} pixel per centimetre),
						'other' => q({0} pixels per centimetre),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centimetres),
						'one' => q({0} centimetre),
						'other' => q({0} centimetres),
						'per' => q({0} per centimetre),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimetres),
						'one' => q({0} centimetre),
						'other' => q({0} centimetres),
						'per' => q({0} per centimetre),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decimetre),
						'one' => q({0} decimetre),
						'other' => q({0} decimetres),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decimetre),
						'one' => q({0} decimetre),
						'other' => q({0} decimetres),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0} earth radius),
						'other' => q({0} earth radii),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0} earth radius),
						'other' => q({0} earth radii),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometres),
						'one' => q({0} kilometre),
						'other' => q({0} kilometres),
						'per' => q({0} per kilometre),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometres),
						'one' => q({0} kilometre),
						'other' => q({0} kilometres),
						'per' => q({0} per kilometre),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metres),
						'one' => q({0} metre),
						'other' => q({0} metres),
						'per' => q({0} per metre),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metres),
						'one' => q({0} metre),
						'other' => q({0} metres),
						'per' => q({0} per metre),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrometre),
						'one' => q({0} micrometre),
						'other' => q({0} micrometres),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrometre),
						'one' => q({0} micrometre),
						'other' => q({0} micrometres),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(Scandinavian mile),
						'one' => q({0} Scandinavian mile),
						'other' => q({0} Scandinavian miles),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(Scandinavian mile),
						'one' => q({0} Scandinavian mile),
						'other' => q({0} Scandinavian miles),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimetres),
						'one' => q({0} millimetre),
						'other' => q({0} millimetres),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimetres),
						'one' => q({0} millimetre),
						'other' => q({0} millimetres),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometres),
						'one' => q({0} nanometre),
						'other' => q({0} nanometres),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometres),
						'one' => q({0} nanometre),
						'other' => q({0} nanometres),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picometres),
						'one' => q({0} picometre),
						'other' => q({0} picometres),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picometres),
						'one' => q({0} picometre),
						'other' => q({0} picometres),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candelas),
						'one' => q({0} candela),
						'other' => q({0} candelas),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candelas),
						'one' => q({0} candela),
						'other' => q({0} candelas),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumens),
						'one' => q({0} lumen),
						'other' => q({0} lumens),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumens),
						'one' => q({0} lumen),
						'other' => q({0} lumens),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonnes),
						'one' => q({0} tonne),
						'other' => q({0} tonnes),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonnes),
						'one' => q({0} tonne),
						'other' => q({0} tonnes),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimetres of mercury),
						'one' => q({0} millimetre of mercury),
						'other' => q({0} millimetres of mercury),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimetres of mercury),
						'one' => q({0} millimetre of mercury),
						'other' => q({0} millimetres of mercury),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometres per hour),
						'one' => q({0} kilometre per hour),
						'other' => q({0} kilometres per hour),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometres per hour),
						'one' => q({0} kilometre per hour),
						'other' => q({0} kilometres per hour),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metres per second),
						'one' => q({0} metre per second),
						'other' => q({0} metres per second),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metres per second),
						'one' => q({0} metre per second),
						'other' => q({0} metres per second),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(degree),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(degree),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton metres),
						'one' => q({0} newton metre),
						'other' => q({0} newton metres),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton metres),
						'one' => q({0} newton metre),
						'other' => q({0} newton metres),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(centilitres),
						'one' => q({0} centilitre),
						'other' => q({0} centilitres),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(centilitres),
						'one' => q({0} centilitre),
						'other' => q({0} centilitres),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cubic centimetres),
						'one' => q({0} cubic centimetre),
						'other' => q({0} cubic centimetres),
						'per' => q({0} per cubic centimetre),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cubic centimetres),
						'one' => q({0} cubic centimetre),
						'other' => q({0} cubic centimetres),
						'per' => q({0} per cubic centimetre),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(cubic kilometres),
						'one' => q({0} cubic kilometre),
						'other' => q({0} cubic kilometres),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(cubic kilometres),
						'one' => q({0} cubic kilometre),
						'other' => q({0} cubic kilometres),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(cubic metres),
						'one' => q({0} cubic metre),
						'other' => q({0} cubic metres),
						'per' => q({0} per cubic metre),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(cubic metres),
						'one' => q({0} cubic metre),
						'other' => q({0} cubic metres),
						'per' => q({0} per cubic metre),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(decilitres),
						'one' => q({0} decilitre),
						'other' => q({0} decilitres),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(decilitres),
						'one' => q({0} decilitre),
						'other' => q({0} decilitres),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(US dessertspoon),
						'one' => q({0} US dessertspoon),
						'other' => q({0} US dessertspoons),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(US dessertspoon),
						'one' => q({0} US dessertspoon),
						'other' => q({0} US dessertspoons),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dessertspoon),
						'one' => q({0} dessertspoon),
						'other' => q({0} dessertspoons),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dessertspoon),
						'one' => q({0} dessertspoon),
						'other' => q({0} dessertspoons),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fluid drams),
						'one' => q({0} fluid dram),
						'other' => q({0} fluid drams),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fluid drams),
						'one' => q({0} fluid dram),
						'other' => q({0} fluid drams),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(US fluid ounces),
						'one' => q({0} US fluid ounce),
						'other' => q({0} US fluid ounces),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(US fluid ounces),
						'one' => q({0} US fluid ounce),
						'other' => q({0} US fluid ounces),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounces),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounces),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(US gallons),
						'one' => q({0} US gallon),
						'other' => q({0} US gallons),
						'per' => q({0} per US gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(US gallons),
						'one' => q({0} US gallon),
						'other' => q({0} US gallons),
						'per' => q({0} per US gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} per gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} per gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hectolitres),
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hectolitres),
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litres),
						'one' => q({0} litre),
						'other' => q({0} litres),
						'per' => q({0} per litre),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litres),
						'one' => q({0} litre),
						'other' => q({0} litres),
						'per' => q({0} per litre),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitres),
						'one' => q({0} megalitre),
						'other' => q({0} megalitres),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitres),
						'one' => q({0} megalitre),
						'other' => q({0} megalitres),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millilitres),
						'one' => q({0} millilitre),
						'other' => q({0} millilitres),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millilitres),
						'one' => q({0} millilitre),
						'other' => q({0} millilitres),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(US quarts),
						'one' => q({0} US quart),
						'other' => q({0} US quarts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(US quarts),
						'one' => q({0} US quart),
						'other' => q({0} US quarts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0}rev),
						'other' => q({0}revs),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}rev),
						'other' => q({0}revs),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'per' => q({0}/sq in),
					},
					# Core Unit Identifier
					'square-inch' => {
						'per' => q({0}/sq in),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metres²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metres²),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg US),
						'one' => q({0}mpgUS),
						'other' => q({0}mpgUS),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg US),
						'one' => q({0}mpgUS),
						'other' => q({0}mpgUS),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0}bit),
						'other' => q({0}bits),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}bit),
						'other' => q({0}bits),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0}/hr),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0}/hr),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0}/mo),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0}/mo),
					},
					# Long Unit Identifier
					'duration-second' => {
						'per' => q({0}/sec),
					},
					# Core Unit Identifier
					'second' => {
						'per' => q({0}/sec),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0}/wk),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0}/wk),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0}/yr),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0}/yr),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metre),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metre),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lx),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(deg),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(deg),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cups),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cups),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(US dsp),
						'one' => q({0}USdsp),
						'other' => q({0}USdsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(US dsp),
						'one' => q({0}USdsp),
						'other' => q({0}USdsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl dr),
						'one' => q({0}fl dr),
						'other' => q({0}fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl dr),
						'one' => q({0}fl dr),
						'other' => q({0}fl dr),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(US fl oz),
						'one' => q({0}US fl oz),
						'other' => q({0}US fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(US fl oz),
						'one' => q({0}US fl oz),
						'other' => q({0}US fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(US gal),
						'one' => q({0}USgal),
						'other' => q({0}USgal),
						'per' => q({0}/USgal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(US gal),
						'one' => q({0}USgal),
						'other' => q({0}USgal),
						'per' => q({0}/USgal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(jiggers),
						'one' => q({0}jigger),
						'other' => q({0}jiggers),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jiggers),
						'one' => q({0}jigger),
						'other' => q({0}jiggers),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litre),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litre),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(US qt),
						'one' => q({0}USqt),
						'other' => q({0}USqt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(US qt),
						'one' => q({0}USqt),
						'other' => q({0}USqt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metres/sec²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metres/sec²),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0} rev),
						'other' => q({0} revs),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0} rev),
						'other' => q({0} revs),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(sq inches),
						'one' => q({0} sq in),
						'other' => q({0} sq in),
						'per' => q({0}/sq in),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(sq inches),
						'one' => q({0} sq in),
						'other' => q({0} sq in),
						'per' => q({0}/sq in),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metres²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metres²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'per' => q({0}/sq mi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'per' => q({0}/sq mi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(sq yards),
						'one' => q({0} sq yd),
						'other' => q({0} sq yd),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(sq yards),
						'one' => q({0} sq yd),
						'other' => q({0} sq yd),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(items),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(items),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrams/decilitre),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrams/decilitre),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimoles/litre),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimoles/litre),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(moles),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(moles),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(per mille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(per mille),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(per myriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(per myriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litres/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litres/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litres/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litres/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miles/US gal),
						'one' => q({0} mpg US),
						'other' => q({0} mpg US),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miles/US gal),
						'one' => q({0} mpg US),
						'other' => q({0} mpg US),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} hr),
						'other' => q({0} hrs),
						'per' => q({0}/hr),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} hr),
						'other' => q({0} hrs),
						'per' => q({0}/hr),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0} μsec),
						'other' => q({0} μsecs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0} μsec),
						'other' => q({0} μsecs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} millisec),
						'other' => q({0} millisecs),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} millisec),
						'other' => q({0} millisecs),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} min),
						'other' => q({0} mins),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} min),
						'other' => q({0} mins),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} mo),
						'other' => q({0} mos),
						'per' => q({0}/mo),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} mo),
						'other' => q({0} mos),
						'per' => q({0}/mo),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0} nanosec),
						'other' => q({0} nanosecs),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0} nanosec),
						'other' => q({0} nanosecs),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} sec),
						'other' => q({0} secs),
						'per' => q({0}/sec),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} sec),
						'other' => q({0} secs),
						'per' => q({0}/sec),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0}/wk),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0}/wk),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0}/yr),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0}/yr),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metres),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metres),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μmetres),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmetres),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0} grain),
						'other' => q({0} grains),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0} grain),
						'other' => q({0} grains),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bars),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bars),
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
						'name' => q(metres/sec),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metres/sec),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(deg C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(deg C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(deg F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(deg F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(deg),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(deg),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cu centimetres),
						'one' => q({0}/cu cm),
						'other' => q({0}/cu cm),
						'per' => q({0}/cu cm),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cu centimetres),
						'one' => q({0}/cu cm),
						'other' => q({0}/cu cm),
						'per' => q({0}/cu cm),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(cu feet),
						'one' => q({0} cu ft),
						'other' => q({0} cu ft),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(cu feet),
						'one' => q({0} cu ft),
						'other' => q({0} cu ft),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(cu inches),
						'one' => q({0} cu in),
						'other' => q({0} cu in),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(cu inches),
						'one' => q({0} cu in),
						'other' => q({0} cu in),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(cu kilometres),
						'one' => q({0} cu km),
						'other' => q({0} cu km),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(cu kilometres),
						'one' => q({0} cu km),
						'other' => q({0} cu km),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(cu metres),
						'one' => q({0}/cu m),
						'other' => q({0}/cu m),
						'per' => q({0}/cu m),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(cu metres),
						'one' => q({0}/cu m),
						'other' => q({0}/cu m),
						'per' => q({0}/cu m),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(cu miles),
						'one' => q({0} cu mi),
						'other' => q({0} cu mi),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(cu miles),
						'one' => q({0} cu mi),
						'other' => q({0} cu mi),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(cu yards),
						'one' => q({0} cu yd),
						'other' => q({0} cu yd),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(cu yards),
						'one' => q({0} cu yd),
						'other' => q({0} cu yd),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(US dssp),
						'one' => q({0} US dssp),
						'other' => q({0} US dssp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(US dssp),
						'one' => q({0} US dssp),
						'other' => q({0} US dssp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dssp),
						'one' => q({0} dssp),
						'other' => q({0} dssp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dssp),
						'one' => q({0} dssp),
						'other' => q({0} dssp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl drams),
						'one' => q({0} fl dram),
						'other' => q({0} fl drams),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl drams),
						'one' => q({0} fl dram),
						'other' => q({0} fl drams),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q({0} drops),
						'other' => q({0} drops),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q({0} drops),
						'other' => q({0} drops),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(US fl oz),
						'one' => q({0} US fl oz),
						'other' => q({0} US fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(US fl oz),
						'one' => q({0} US fl oz),
						'other' => q({0} US fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(US gal),
						'one' => q({0} US gal),
						'other' => q({0} US gal),
						'per' => q({0}/US gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(US gal),
						'one' => q({0} US gal),
						'other' => q({0} US gal),
						'per' => q({0}/US gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0} jiggers),
						'other' => q({0} jiggers),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0} jiggers),
						'other' => q({0} jiggers),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litres),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litres),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q({0} pinches),
						'other' => q({0} pinches),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0} pinches),
						'other' => q({0} pinches),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(US qts),
						'one' => q({0} US qt),
						'other' => q({0} US qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(US qts),
						'one' => q({0} US qt),
						'other' => q({0} US qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
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

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AFN' => {
			display_name => {
				'one' => q(Afghan afghani),
				'other' => q(Afghan afghanis),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermudian Dollar),
				'one' => q(Bermudian dollar),
				'other' => q(Bermudian dollars),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Belarusian New Rouble \(1994–1999\)),
				'one' => q(Belarusian new rouble \(1994–1999\)),
				'other' => q(Belarusian new roubles \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Belarusian Rouble),
				'one' => q(Belarusian rouble),
				'other' => q(Belarusian roubles),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belarusian Rouble \(2000–2016\)),
				'one' => q(Belarusian rouble \(2000–2016\)),
				'other' => q(Belarusian roubles \(2000–2016\)),
			},
		},
		'CAD' => {
			symbol => '$',
		},
		'JPY' => {
			symbol => 'JP¥',
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvian Rouble),
				'one' => q(Latvian rouble),
				'other' => q(Latvian roubles),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russian Rouble),
				'one' => q(Russian rouble),
				'other' => q(Russian roubles),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Russian Rouble \(1991–1998\)),
				'one' => q(Russian rouble \(1991–1998\)),
				'other' => q(Russian roubles \(1991–1998\)),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Saint Helena Pound),
				'one' => q(Saint Helena pound),
				'other' => q(Saint Helena pounds),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé and Príncipe Dobra),
				'one' => q(São Tomé and Príncipe dobra),
				'other' => q(São Tomé and Príncipe dobras),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tajikistani Rouble),
				'one' => q(Tajikistani rouble),
				'other' => q(Tajikistani roubles),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad and Tobago Dollar),
				'one' => q(Trinidad and Tobago dollar),
				'other' => q(Trinidad and Tobago dollars),
			},
		},
		'USD' => {
			symbol => 'US$',
		},
		'XXX' => {
			display_name => {
				'currency' => q(unknown currency),
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
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'afternoon1' => q{aft},
					'am' => q{am},
					'evening1' => q{eve},
					'midnight' => q{mid},
					'morning1' => q{mor},
					'night1' => q{night},
					'noon' => q{n},
					'pm' => q{pm},
				},
				'wide' => {
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
					'afternoon1' => q{aft},
					'am' => q{a.m.},
					'evening1' => q{eve},
					'midnight' => q{mid},
					'morning1' => q{mor},
					'night1' => q{night},
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
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
			'full' => q{EEEE, MMMM d, r (U)},
			'long' => q{MMMM d, r (U)},
			'medium' => q{MMM d, r},
			'short' => q{M/d/r},
		},
		'generic' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{y-MM-dd},
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
		'chinese' => {
		},
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
		'chinese' => {
		},
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
		'chinese' => {
			GyMMMEd => q{E, MMM d, r(U)},
			GyMMMMEd => q{E, d MMMM r(U)},
			GyMMMMd => q{d MMMM r(U)},
			M => q{LL},
			MEd => q{E, d/M},
			Md => q{d/M},
			UMd => q{d/M/U},
			yMd => q{d/M/r},
			yyyyM => q{r-MM},
			yyyyMEd => q{E, d/M/r},
			yyyyMMMEd => q{E, MMM d, r(U)},
			yyyyMMMMEd => q{E, d MMMM r(U)},
			yyyyMMMMd => q{d MMMM r(U)},
			yyyyMd => q{d/M/r},
		},
		'generic' => {
			Ed => q{E d},
			MEd => q{E, d/M},
			Md => q{d/M},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMd => q{d/M/y GGGGG},
		},
		'gregorian' => {
			Ed => q{E d},
			MEd => q{E, d/M},
			MMdd => q{dd/MM},
			Md => q{d/M},
			yM => q{y-MM},
			yMEd => q{E, d/M/y},
			yMd => q{d/M/y},
		},
		'islamic' => {
			Ed => q{E d},
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
		'chinese' => {
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
		'generic' => {
			Bh => {
				B => q{h B–h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B–h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{y G–y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG–M/y GGGGG},
				M => q{M/y–M/y GGGGG},
				y => q{M/y–M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG–E, M/d/y GGGGG},
				M => q{E, M/d/y–E, M/d/y GGGGG},
				d => q{E, M/d/y–E, M/d/y GGGGG},
				y => q{E, M/d/y–E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G–MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G–E, MMM d, y G},
				M => q{E, MMM d–E, MMM d, y G},
				d => q{E, MMM d–E, MMM d, y G},
				y => q{E, MMM d, y–E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G–MMM d, y G},
				M => q{MMM d–MMM d, y G},
				d => q{MMM d–d, y G},
				y => q{MMM d, y–MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG–M/d/y GGGGG},
				M => q{M/d/y–M/d/y GGGGG},
				d => q{M/d/y–M/d/y GGGGG},
				y => q{M/d/y–M/d/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM d–E, MMM d},
				d => q{E, MMM d–E, MMM d},
			},
			MMMd => {
				M => q{MMM d–MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0}–{1}',
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y–M/y GGGGG},
				y => q{M/y–M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d–E, MMM d, y G},
				d => q{E, MMM d–E, MMM d, y G},
				y => q{E, MMM d, y–E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y–MMMM y G},
			},
			yMMMd => {
				M => q{MMM d–MMM d, y G},
				d => q{MMM d–d, y G},
				y => q{MMM d, y–MMM d, y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B–h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B–h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{y G–y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y G–M/y G},
				M => q{M/y–M/y G},
				y => q{M/y–M/y G},
			},
			GyMEd => {
				G => q{E, M/d/y G–E, M/d/y G},
				M => q{E, M/d/y–E, M/d/y G},
				d => q{E, M/d/y–E, M/d/y G},
				y => q{E, M/d/y–E, M/d/y G},
			},
			GyMMM => {
				G => q{MMM y G–MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G–E, MMM d, y G},
				M => q{E, MMM d–E, MMM d, y G},
				d => q{E, MMM d–E, MMM d, y G},
				y => q{E, MMM d, y–E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G–MMM d, y G},
				M => q{MMM d–MMM d, y G},
				d => q{MMM d–d, y G},
				y => q{MMM d, y–MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y G–M/d/y G},
				M => q{M/d/y–M/d/y G},
				d => q{M/d/y–M/d/y G},
				y => q{M/d/y–M/d/y G},
			},
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM d–E, MMM d},
				d => q{E, MMM d–E, MMM d},
			},
			MMMd => {
				M => q{MMM d–MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0}–{1}',
			h => {
				a => q{h a–h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a–h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a–h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M/y–M/y},
				y => q{M/y–M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y–MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d–E, MMM d, y},
				d => q{E, MMM d–E, MMM d, y},
				y => q{E, MMM d, y–E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y–MMMM y},
			},
			yMMMd => {
				M => q{MMM d–MMM d, y},
				d => q{MMM d–d, y},
				y => q{MMM d, y–MMM d, y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
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
		'Afghanistan' => {
			short => {
				'standard' => q#AFT#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska Daylight Saving Time#,
				'generic' => q#Alaska Time#,
				'standard' => q#Alaska Standard Time#,
			},
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Saint Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint Vincent#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Central Daylight Saving Time#,
				'generic' => q#Central Time#,
				'standard' => q#Central Standard Time#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern Daylight Saving Time#,
				'generic' => q#Eastern Time#,
				'standard' => q#Eastern Standard Time#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain Daylight Saving Time#,
				'generic' => q#Mountain Time#,
				'standard' => q#Mountain Standard Time#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific Daylight Saving Time#,
				'generic' => q#Pacific Time#,
				'standard' => q#Pacific Standard Time#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia Daylight Saving Time#,
				'generic' => q#Apia Time#,
				'standard' => q#Apia Standard Time#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabian Daylight Saving Time#,
				'generic' => q#Arabian Time#,
				'standard' => q#Arabian Standard Time#,
			},
		},
		'Argentina' => {
			short => {
				'generic' => q#ART#,
			},
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantic Daylight Saving Time#,
				'generic' => q#Atlantic Time#,
				'standard' => q#Atlantic Standard Time#,
			},
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Saint Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Australian Central Daylight Saving Time#,
				'generic' => q#Central Australia Time#,
				'standard' => q#Australian Central Standard Time#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australian Central Western Daylight Saving Time#,
				'generic' => q#Australian Central Western Time#,
				'standard' => q#Australian Central Western Standard Time#,
			},
			short => {
				'daylight' => q#ACWDT#,
				'generic' => q#ACWT#,
				'standard' => q#ACWST#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australian Eastern Daylight Saving Time#,
				'generic' => q#Eastern Australia Time#,
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
				'daylight' => q#Australian Western Daylight Saving Time#,
				'generic' => q#Western Australia Time#,
				'standard' => q#Australian Western Standard Time#,
			},
			short => {
				'daylight' => q#AWDT#,
				'standard' => q#AWST#,
			},
		},
		'Bangladesh' => {
			short => {
				'standard' => q#BST#,
			},
		},
		'Bhutan' => {
			short => {
				'standard' => q#BTT#,
			},
		},
		'Brasilia' => {
			short => {
				'daylight' => q#BRST#,
				'generic' => q#BRT#,
			},
		},
		'Brunei' => {
			short => {
				'standard' => q#BNT#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham Daylight Saving Time#,
				'generic' => q#Chatham Time#,
				'standard' => q#Chatham Standard Time#,
			},
			short => {
				'daylight' => q#CHADT#,
				'standard' => q#CHAST#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#China Daylight Saving Time#,
				'generic' => q#China Time#,
				'standard' => q#China Standard Time#,
			},
		},
		'Christmas' => {
			short => {
				'standard' => q#CXT#,
			},
		},
		'Cocos' => {
			short => {
				'standard' => q#CCT#,
			},
		},
		'Colombia' => {
			short => {
				'daylight' => q#COST#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cuba Daylight Saving Time#,
				'generic' => q#Cuba Time#,
				'standard' => q#Cuba Standard Time#,
			},
		},
		'East_Timor' => {
			short => {
				'standard' => q#TLT#,
			},
		},
		'Easter' => {
			short => {
				'daylight' => q#EASST#,
				'standard' => q#EAST#,
			},
		},
		'Ecuador' => {
			short => {
				'standard' => q#ECT#,
			},
		},
		'Falkland' => {
			short => {
				'daylight' => q#FKST#,
				'generic' => q#FKT#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#French Southern and Antarctic Time#,
			},
		},
		'Galapagos' => {
			short => {
				'standard' => q#GALT#,
			},
		},
		'Greenland_Eastern' => {
			short => {
				'generic' => q#EGT#,
			},
		},
		'Guyana' => {
			short => {
				'standard' => q#GYT#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutian Daylight Saving Time#,
				'generic' => q#Hawaii-Aleutian Time#,
				'standard' => q#Hawaii-Aleutian Standard Time#,
			},
		},
		'India' => {
			short => {
				'standard' => q#IST#,
			},
		},
		'Indochina' => {
			short => {
				'standard' => q#ICT#,
			},
		},
		'Indonesia_Central' => {
			short => {
				'standard' => q#WITA#,
			},
		},
		'Indonesia_Eastern' => {
			short => {
				'standard' => q#WIT#,
			},
		},
		'Indonesia_Western' => {
			short => {
				'standard' => q#WIB#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran Daylight Saving Time#,
				'generic' => q#Iran Time#,
				'standard' => q#Iran Standard Time#,
			},
			short => {
				'daylight' => q#IRDT#,
				'standard' => q#IRST#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel Daylight Saving Time#,
				'generic' => q#Israel Time#,
				'standard' => q#Israel Standard Time#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan Daylight Saving Time#,
				'generic' => q#Japan Time#,
				'standard' => q#Japan Standard Time#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korean Daylight Saving Time#,
				'generic' => q#Korean Time#,
				'standard' => q#Korean Standard Time#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe Daylight Saving Time#,
				'generic' => q#Lord Howe Time#,
				'standard' => q#Lord Howe Standard Time#,
			},
		},
		'Malaysia' => {
			short => {
				'standard' => q#MYT#,
			},
		},
		'Maldives' => {
			short => {
				'standard' => q#MVT#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Northwest Mexico Daylight Saving Time#,
				'generic' => q#Northwest Mexico Time#,
				'standard' => q#Northwest Mexico Standard Time#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexican Pacific Daylight Saving Time#,
				'generic' => q#Mexican Pacific Time#,
				'standard' => q#Mexican Pacific Standard Time#,
			},
		},
		'Nepal' => {
			short => {
				'standard' => q#NPT#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#New Zealand Daylight Saving Time#,
				'generic' => q#New Zealand Time#,
				'standard' => q#New Zealand Standard Time#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland Daylight Saving Time#,
				'generic' => q#Newfoundland Time#,
				'standard' => q#Newfoundland Standard Time#,
			},
			short => {
				'daylight' => q#NDT#,
				'generic' => q#NT#,
				'standard' => q#NST#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Island Daylight Saving Time#,
				'generic' => q#Norfolk Island Time#,
				'standard' => q#Norfolk Island Standard Time#,
			},
		},
		'Noronha' => {
			short => {
				'generic' => q#FNT#,
			},
		},
		'Pakistan' => {
			short => {
				'standard' => q#PKT#,
			},
		},
		'Paraguay' => {
			short => {
				'daylight' => q#PYST#,
				'generic' => q#PYT#,
			},
		},
		'Peru' => {
			short => {
				'generic' => q#PET#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint-Pierre-et-Miquelon Daylight Saving Time#,
				'generic' => q#Saint-Pierre-et-Miquelon Time#,
				'standard' => q#Saint-Pierre-et-Miquelon Standard Time#,
			},
			short => {
				'daylight' => q#PMDT#,
				'generic' => q#PMT#,
				'standard' => q#PMST#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Daylight Saving Time#,
				'generic' => q#Samoa Time#,
				'standard' => q#Samoa Standard Time#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei Daylight Saving Time#,
				'generic' => q#Taipei Time#,
				'standard' => q#Taipei Standard Time#,
			},
		},
		'Uruguay' => {
			short => {
				'daylight' => q#UYST#,
				'standard' => q#UYT#,
			},
		},
		'Venezuela' => {
			short => {
				'standard' => q#VET#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis and Futuna Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
