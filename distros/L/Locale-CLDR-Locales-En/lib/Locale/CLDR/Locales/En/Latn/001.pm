=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Latn::001 - Package for language English

=cut

package Locale::CLDR::Locales::En::Latn::001;
# This file auto generated from Data\common\main\en_001.xml
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
has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'bla' => 'Siksika',
 				'mus' => 'Creek',
 				'nds_NL' => 'West Low German',

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
			'BL' => 'St Barthélemy',
 			'KN' => 'St Kitts & Nevis',
 			'LC' => 'St Lucia',
 			'MF' => 'St Martin',
 			'PM' => 'St Pierre & Miquelon',
 			'SH' => 'St Helena',
 			'UM' => 'US Outlying Islands',
 			'VC' => 'St Vincent & the Grenadines',
 			'VI' => 'US Virgin Islands',

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
 			'colnormalization' => 'Normalised Sorting',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'colnormalization' => {
 				'no' => q{Sort Without Normalisation},
 				'yes' => q{Sort Unicode Normalised},
 			},
 			'hc' => {
 				'h11' => q{12-Hour System (0–11)},
 				'h12' => q{12-Hour System (1–12)},
 				'h23' => q{24-Hour System (0–23)},
 				'h24' => q{24-Hour System (1–24)},
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
					'concentr-karat' => {
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
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
					'concentr-percent' => {
						'name' => q(per cent),
						'one' => q({0} per cent),
						'other' => q({0} per cent),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(per cent),
						'one' => q({0} per cent),
						'other' => q({0} per cent),
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
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0} kilowatt-hour),
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
						'other' => q({0} earth radii),
					},
					# Core Unit Identifier
					'earth-radius' => {
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
						'other' => q({0} candelas),
					},
					# Core Unit Identifier
					'candela' => {
						'other' => q({0} candelas),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'other' => q({0} lumens),
					},
					# Core Unit Identifier
					'lumen' => {
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
					'area-square-meter' => {
						'name' => q(metres²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metres²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(carat),
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(carat),
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
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
					'length-meter' => {
						'name' => q(metre),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metre),
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
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(US dsp),
						'one' => q({0}US dsp),
						'other' => q({0}US dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(US dsp),
						'one' => q({0}US dsp),
						'other' => q({0}US dsp),
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
						'one' => q({0}galUS),
						'other' => q({0}galUS),
						'per' => q({0}/galUS),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(US gal),
						'one' => q({0}galUS),
						'other' => q({0}galUS),
						'per' => q({0}/galUS),
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
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'other' => q({0}jiggers),
					},
					# Core Unit Identifier
					'jigger' => {
						'other' => q({0}jiggers),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litre),
						'one' => q({0}l),
						'other' => q({0}l),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litre),
						'one' => q({0}l),
						'other' => q({0}l),
						'per' => q({0}/l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0}ml),
						'other' => q({0}ml),
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
						'other' => q({0} revs),
					},
					# Core Unit Identifier
					'revolution' => {
						'other' => q({0} revs),
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
					'concentr-karat' => {
						'name' => q(carats),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(carats),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimole/litre),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimole/litre),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(per cent),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(per cent),
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
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litres/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litres/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
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
					'duration-hour' => {
						'one' => q({0} hr),
						'other' => q({0} hrs),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} hr),
						'other' => q({0} hrs),
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
					'duration-second' => {
						'one' => q({0} sec),
						'other' => q({0} secs),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} sec),
						'other' => q({0} secs),
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
						'one' => q({0} grains),
						'other' => q({0} grains),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0} grains),
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
					'speed-meter-per-second' => {
						'name' => q(metres/sec),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metres/sec),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(US dstspn),
						'one' => q({0} US dstspn),
						'other' => q({0} US dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(US dstspn),
						'one' => q({0} US dstspn),
						'other' => q({0} US dstspn),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dstspn),
						'one' => q({0} dstspn),
						'other' => q({0} dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dstspn),
						'one' => q({0} dstspn),
						'other' => q({0} dstspn),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
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
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litres),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litres),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
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
		'ETB' => {
			display_name => {
				'other' => q(Ethiopian birr),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
		},
		'LSL' => {
			display_name => {
				'other' => q(Lesotho maloti),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvian Rouble),
				'one' => q(Latvian rouble),
				'other' => q(Latvian roubles),
			},
		},
		'MGA' => {
			display_name => {
				'other' => q(Malagasy ariary),
			},
		},
		'MVR' => {
			display_name => {
				'other' => q(Maldivian rufiyaa),
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
				'currency' => q(St Helena Pound),
				'one' => q(St Helena pound),
				'other' => q(St Helena pounds),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tajikistani Rouble),
				'one' => q(Tajikistani rouble),
				'other' => q(Tajikistani roubles),
			},
		},
		'USD' => {
			symbol => 'US$',
		},
		'VUV' => {
			display_name => {
				'other' => q(Vanuatu vatu),
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
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							'Sept'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							'Sept'
						],
						leap => [
							
						],
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
					'am' => q{am},
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{am},
					'pm' => q{pm},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{am},
					'pm' => q{pm},
				},
				'narrow' => {
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{am},
					'pm' => q{pm},
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
			'full' => q{EEEE, d MMMM r(U)},
			'long' => q{d MMMM r(U)},
			'medium' => q{d MMM r},
			'short' => q{dd/MM/r},
		},
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
		'chinese' => {
			Ed => q{E d},
			GyMMMEd => q{E, d MMM r},
			GyMMMMEd => q{E, d MMMM r(U)},
			GyMMMMd => q{d MMMM r(U)},
			GyMMMd => q{d MMM r},
			M => q{LL},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			UMMMd => q{d MMM U},
			UMd => q{dd/MM/U},
			yyyyM => q{MM/r},
			yyyyMEd => q{E, dd/MM/r},
			yyyyMMMEd => q{E, d MMM r},
			yyyyMMMMEd => q{E, d MMMM r(U)},
			yyyyMMMMd => q{d MMMM r(U)},
			yyyyMMMd => q{d MMM r},
			yyyyMd => q{dd/MM/r},
		},
		'generic' => {
			Ed => q{E d},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			M => q{LL},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			Ed => q{E d},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y G},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{dd/MM},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMMMEd => q{E, d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
		},
		'islamic' => {
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
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
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM U},
				d => q{E, d – E, d MMM U},
				y => q{E, d MMM U – E, d MMM U},
			},
			yMMMd => {
				M => q{d MMM – d MMM U},
				d => q{d – d MMM U},
				y => q{d MMM U – d MMM U},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'generic' => {
			Gy => {
				y => q{y–y G},
			},
			GyMEd => {
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
		},
		'gregorian' => {
			GyMEd => {
				G => q{E, dd/MM/y G – E, dd/MM/y G},
				M => q{E, dd/MM/y – E, dd/MM/y G},
				d => q{E, dd/MM/y – E, dd/MM/y G},
				y => q{E, dd/MM/y – E, dd/MM/y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y G – dd/MM/y G},
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
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
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			h => {
				h => q{h–h a},
			},
			hv => {
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Alaska' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St Vincent#,
		},
		'America_Central' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'America_Eastern' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'America_Mountain' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'America_Pacific' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Atlantic' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St Pierre & Miquelon Daylight Time#,
				'generic' => q#St Pierre & Miquelon Time#,
				'standard' => q#St Pierre & Miquelon Standard Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
