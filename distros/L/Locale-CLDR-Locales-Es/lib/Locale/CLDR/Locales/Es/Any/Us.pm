=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Any::Us - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Us;
# This file auto generated from Data\common\main\es_US.xml
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

extends('Locale::CLDR::Locales::Es::Any::419');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ace' => 'acehnés',
 				'alt' => 'altái meridional',
 				'ar_001' => 'árabe estándar moderno',
 				'arp' => 'arapaho',
 				'ars' => 'árabe najdi',
 				'bax' => 'bamun',
 				'bho' => 'bhojpuri',
 				'bla' => 'siksika',
 				'bua' => 'buriat',
 				'dum' => 'neerlandés medieval',
 				'enm' => 'inglés medieval',
 				'eu' => 'euskera',
 				'frm' => 'francés medieval',
 				'gan' => 'gan (China)',
 				'gmh' => 'alemán de la alta edad media',
 				'grc' => 'griego antiguo',
 				'gu' => 'gurayatí',
 				'hil' => 'hiligainón',
 				'hsn' => 'xiang (China)',
 				'ht' => 'criollo haitiano',
 				'inh' => 'ingusetio',
 				'kab' => 'cabilio',
 				'kbd' => 'kabardiano',
 				'krc' => 'karachay-balkar',
 				'lo' => 'lao',
 				'lou' => 'creole de Luisiana',
 				'lrc' => 'lorí del norte',
 				'lus' => 'lushai',
 				'mga' => 'irlandés medieval',
 				'nd' => 'ndebele del norte',
 				'nl_BE' => 'flamenco',
 				'nr' => 'ndebele meridional',
 				'nso' => 'sotho septentrional',
 				'rm' => 'romanche',
 				'se' => 'sami del norte',
 				'shu' => 'árabe chadiano',
 				'sma' => 'sami meridional',
 				'smn' => 'sami de Inari',
 				'ss' => 'siswati',
 				'st' => 'sesoto',
 				'sw_CD' => 'swahili del Congo',
 				'syr' => 'siriaco',
 				'tet' => 'tetún',
 				'tn' => 'setchwana',
 				'tyv' => 'tuviniano',
 				'tzm' => 'tamazight del Marruecos Central',
 				'ug@alt=variant' => 'uigur variante',
 				'xal' => 'kalmyk',
 				'zh_Hans' => 'chino simplificado',
 				'zh_Hans@alt=long' => 'chino mandarín simplificado',
 				'zh_Hant' => 'chino tradicional',
 				'zh_Hant@alt=long' => 'chino mandarín tradicional',

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
			'Hrkt' => 'silabarios del japonés',
 			'Zzzz' => 'letra desconocida',

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
			'011' => 'África occidental',
 			'014' => 'África oriental',
 			'015' => 'África septentrional',
 			'018' => 'África meridional',
 			'030' => 'Asia oriental',
 			'034' => 'Asia meridional',
 			'035' => 'Sudeste asiático',
 			'039' => 'Europa meridional',
 			'145' => 'Asia occidental',
 			'151' => 'Europa oriental',
 			'154' => 'Europa septentrional',
 			'155' => 'Europa occidental',
 			'AC' => 'Isla de la Ascensión',
 			'BA' => 'Bosnia y Herzegovina',
 			'EH' => 'Sahara Occidental',
 			'GB@alt=short' => 'RU',
 			'GG' => 'Guernsey',
 			'QO' => 'Territorios alejados de Oceanía',
 			'TA' => 'Tristán de Acuña',
 			'UM' => 'Islas menores alejadas de EE. UU.',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'numbers' => {
 				'gujr' => q{dígitos en gujarati},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'UK' => q{imperial},

		}
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{[...]},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(picó{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(picó{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centí{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centí{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kiló{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kiló{0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramos por decilitro),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramos por decilitro),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} este),
						'north' => q({0} norte),
						'south' => q({0} sur),
						'west' => q({0} oeste),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} este),
						'north' => q({0} norte),
						'south' => q({0} sur),
						'west' => q({0} oeste),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamperio),
						'one' => q({0} miliamperio),
						'other' => q({0} miliamperios),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamperio),
						'one' => q({0} miliamperio),
						'other' => q({0} miliamperios),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohmios),
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohmios),
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Calorías),
						'one' => q({0} Caloría),
						'other' => q({0} Calorías),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Calorías),
						'one' => q({0} Caloría),
						'other' => q({0} Calorías),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(julios),
						'one' => q({0} julio),
						'other' => q({0} julios),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(julios),
						'one' => q({0} julio),
						'other' => q({0} julios),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojulios),
						'one' => q({0} kilojulio),
						'other' => q({0} kilojulio),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojulios),
						'one' => q({0} kilojulio),
						'other' => q({0} kilojulio),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilovatios por hora),
						'one' => q({0} kilovatio por hora),
						'other' => q({0} kilovatios por hora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilovatios por hora),
						'one' => q({0} kilovatio por hora),
						'other' => q({0} kilovatios por hora),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(feminine),
						'name' => q(em tipográfica),
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(feminine),
						'name' => q(em tipográfica),
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixeles),
						'one' => q({0} megapixel),
						'other' => q({0} megapixeles),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixeles),
						'one' => q({0} megapixel),
						'other' => q({0} megapixeles),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixeles por centímetro),
						'one' => q({0} pixel por centímetro),
						'other' => q({0} pixeles por centímetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixeles por centímetro),
						'one' => q({0} pixel por centímetro),
						'other' => q({0} pixeles por centímetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixeles por pulgada),
						'one' => q({0} pixel por pulgada),
						'other' => q({0} pixeles por pulgada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixeles por pulgada),
						'one' => q({0} pixel por pulgada),
						'other' => q({0} pixeles por pulgada),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(millas naúticas),
						'one' => q({0} milla naútica),
						'other' => q({0} millas naúticas),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(millas naúticas),
						'one' => q({0} milla naútica),
						'other' => q({0} millas naúticas),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} caballo de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} caballo de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0} grado),
						'other' => q({0} grados),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0} grado),
						'other' => q({0} grados),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'one' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(libra fuerza-pies),
						'one' => q({0} libra fuerza-pie),
						'other' => q({0} libra fuerza-pies),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(libra fuerza-pies),
						'one' => q({0} libra fuerza-pie),
						'other' => q({0} libra fuerza-pies),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acres-pies),
						'one' => q({0} acre-pie),
						'other' => q({0} acres pies),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acres-pies),
						'one' => q({0} acre-pie),
						'other' => q({0} acres pies),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dracma fluida),
						'one' => q({0} dracma fluida),
						'other' => q({0} dreacmas fluidas),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dracma fluida),
						'one' => q({0} dracma fluida),
						'other' => q({0} dreacmas fluidas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(onzas fluidas imperiales),
						'one' => q(onza fluida imperial),
						'other' => q({0} onzas fluidas imperiales),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(onzas fluidas imperiales),
						'one' => q(onza fluida imperial),
						'other' => q({0} onzas fluidas imperiales),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(jigger),
						'one' => q({0} jigger),
						'other' => q({0} jiggers),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jigger),
						'one' => q({0} jigger),
						'other' => q({0} jiggers),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectárea),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectárea),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(día),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(día),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punto),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punto),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(braza),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(braza),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0}mil),
						'other' => q({0}mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0}mil),
						'other' => q({0}mil),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
				},
				'short' => {
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mins),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mins),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} m),
						'other' => q({0} mm.),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} m),
						'other' => q({0} mm.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} a),
						'other' => q({0} aa.),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} a),
						'other' => q({0} aa.),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(th US),
						'one' => q({0} th US),
						'other' => q({0} th US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(th US),
						'one' => q({0} th US),
						'other' => q({0} th US),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(px),
						'one' => q({0} px),
						'other' => q({0} px),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(px),
						'one' => q({0} px),
						'other' => q({0} px),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} a. l.),
						'other' => q({0} a. l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} a. l.),
						'other' => q({0} a. l.),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nudo),
						'one' => q({0} nudo),
						'other' => q({0} nudos),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nudo),
						'one' => q({0} nudo),
						'other' => q({0} nudos),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lbf⋅ft),
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lbf⋅ft),
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bsh),
						'one' => q({0} bsh),
						'other' => q({0} bsh),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bsh),
						'one' => q({0} bsh),
						'other' => q({0} bsh),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tza.),
						'one' => q({0} tza.),
						'other' => q({0} tzas.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tza.),
						'one' => q({0} tza.),
						'other' => q({0} tzas.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(Tm),
						'one' => q({0} Tm),
						'other' => q({0} Tm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(Tm),
						'one' => q({0} Tm),
						'other' => q({0} Tm),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cdapostre),
						'one' => q({0} cdapostre),
						'other' => q({0} cdapostre),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cdapostre),
						'one' => q({0} cdapostre),
						'other' => q({0} cdapostre),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(cdapostre imp.),
						'one' => q({0} cdapostre imp.),
						'other' => q({0} cdaspostre imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(cdapostre imp.),
						'one' => q({0} cdapostre imp.),
						'other' => q({0} cdaspostre imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl dracma),
						'one' => q({0} fl dracma),
						'other' => q({0} fl dracmas),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl dracma),
						'one' => q({0} fl dracma),
						'other' => q({0} fl dracmas),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(jigger),
						'one' => q({0} jigger),
						'other' => q({0} jiggers),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jigger),
						'one' => q({0} jigger),
						'other' => q({0} jiggers),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} y {1}),
		} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'short' => {
				'1000' => {
					'one' => '0 K',
					'other' => '0 K',
				},
				'10000' => {
					'one' => '00 K',
					'other' => '00 K',
				},
				'100000' => {
					'one' => '000 K',
					'other' => '000 K',
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BDT' => {
			display_name => {
				'currency' => q(taka bangladesí),
				'one' => q(taka bangladesí),
				'other' => q(takas bangladesíes),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum butanés),
				'one' => q(ngultrum butanés),
				'other' => q(gultrums bultaneses),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr),
				'one' => q(birr),
				'other' => q(birres),
			},
		},
		'FKP' => {
			symbol => '£',
		},
		'JPY' => {
			symbol => '¥',
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laosiano),
				'one' => q(kip laosiano),
				'other' => q(kips laosianos),
			},
		},
		'RON' => {
			symbol => 'lei',
		},
		'SSP' => {
			symbol => '£',
		},
		'SYP' => {
			symbol => '£',
		},
		'THB' => {
			display_name => {
				'currency' => q(bat),
				'one' => q(bat),
				'other' => q(bats),
			},
		},
		'USD' => {
			symbol => '$',
		},
		'UZS' => {
			display_name => {
				'currency' => q(sum),
				'one' => q(sum),
				'other' => q(sums),
			},
		},
		'VEF' => {
			symbol => 'Bs',
		},
		'VND' => {
			display_name => {
				'currency' => q(dong vietnamita),
				'one' => q(dong vietnamita),
				'other' => q(dongs vietnamitas),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franco CFA de África central),
				'one' => q(franco CFA de África central),
				'other' => q(francos CFA de África central),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambiano),
				'one' => q(kwacha zambiano),
				'other' => q(kwachas zambianos),
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
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
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

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
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
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d MMM y},
			'short' => q{d/M/y},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			yyyyMEd => q{E, d/M/y GGGGG},
		},
		'gregorian' => {
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMMd => q{d MMM y G},
			Hmsvvvv => q{HH:mm:ss (vvvv)},
			MMMEd => q{E, d 'de' MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			yMEd => q{E, d/M/y},
			yMM => q{MM/y},
			yMMMEd => q{EEE, d 'de' MMM 'de' y},
			yQQQ => q{QQQ y},
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
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			fallback => '{0}-{1}',
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
			},
		},
		'gregorian' => {
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
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMd => {
				d => q{d–d 'de' MMM},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
			},
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y},
			},
			yMMMM => {
				y => q{MMMM 'de' y – MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM y},
				d => q{d–d 'de' MMM 'de' y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Africa/Djibouti' => {
			exemplarCity => q#Yibutí#,
		},
		'Alaska' => {
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
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
			long => {
				'daylight' => q#hora de verano de las Montañas Rocosas#,
				'generic' => q#hora de las Montañas Rocosas#,
				'standard' => q#hora estándar de las Montañas Rocosas#,
			},
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
		'Apia' => {
			long => {
				'daylight' => q#hora de verano de Apia#,
				'generic' => q#hora de Apia#,
				'standard' => q#hora estándar de Apia#,
			},
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pionyang#,
		},
		'Atlantic' => {
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#hora de Chamorro#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#hora de las Islas Cocos#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#hora de verano media de las Islas Cook#,
				'generic' => q#hora de las Islas Cook#,
				'standard' => q#hora estándar de las Islas Cook#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#hora de verano de la isla de Pascua#,
				'generic' => q#hora de la isla de Pascua#,
				'standard' => q#hora estándar de la isla de Pascua#,
			},
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#hora de verano de Europa oriental#,
				'generic' => q#hora de Europa oriental#,
				'standard' => q#hora estándar de Europa oriental#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#hora del extremo oriental de Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#hora de verano de Europa occidental#,
				'generic' => q#hora de Europa occidental#,
				'standard' => q#hora estándar de Europa occidental#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#hora de verano de las islas Malvinas#,
				'generic' => q#hora de las islas Malvinas#,
				'standard' => q#hora estándar de las islas Malvinas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#hora de las islas Gilbert#,
			},
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#hora del Océano Índico#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#hora de la isla Macquarie#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#hora de las islas Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#hora de las Islas Marshall#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#hora de verano de la isla Norfolk#,
				'generic' => q#hora de la isla Norfolk#,
				'standard' => q#hora estándar de la isla Norfolk#,
			},
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#hora de las islas Fénix#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#hora de Pyongyang#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#hora de las Islas Salomón#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#hora de la isla Wake#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
