=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Latn::419 - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Latn::419;
# This file auto generated from Data\common\main\es_419.xml
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

extends('Locale::CLDR::Locales::Es::Latn');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'digits-ordinal-masculine-adjective','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal-masculine-plural','digits-ordinal-feminine-plural','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'digits-ordinal' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-masculine=),
				},
			},
		},
		'digits-ordinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ª.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ª.),
				},
			},
		},
		'digits-ordinal-feminine-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ᵃˢ.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ᵃˢ.),
				},
			},
		},
		'digits-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=º.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=º.),
				},
			},
		},
		'digits-ordinal-masculine-adjective' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%dord-mascabbrev=.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%dord-mascabbrev=.),
				},
			},
		},
		'digits-ordinal-masculine-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ᵒˢ.),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ᵒˢ.),
				},
			},
		},
		'dord-mascabbrev' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(º),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ᵉʳ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(º),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ᵉʳ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(º),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→→),
				},
			},
		},
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ady' => 'adigeo',
 				'alt' => 'altái del sur',
 				'arp' => 'arapajó',
 				'ars' => 'árabe de Néyed',
 				'bla' => 'siksiká',
 				'eu' => 'vasco',
 				'goh' => 'alemán de la alta edad antigua',
 				'grc' => 'griego clásico',
 				'gu' => 'gujarati',
 				'ht' => 'haitiano',
 				'kbd' => 'cabardiano',
 				'krc' => 'karachái-bálkaro',
 				'ks' => 'cachemiro',
 				'lo' => 'laosiano',
 				'ml' => 'malabar',
 				'mni' => 'manipuri',
 				'nr' => 'ndebele del sur',
 				'nso' => 'sesotho del norte',
 				'pa' => 'panyabí',
 				'prg' => 'prusiano antiguo',
 				'ps@alt=variant' => 'pashtún',
 				'rm' => 'retorrománico',
 				'sd' => 'sindhi',
 				'shu' => 'árabe (Chad)',
 				'sma' => 'sami del sur',
 				'st' => 'sesotho del sur',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili (Congo)',
 				'syr' => 'siríaco',
 				'tet' => 'tetun',
 				'tyv' => 'tuvano',
 				'ug@alt=variant' => 'uighur',
 				'wal' => 'walamo',
 				'wuu' => 'wu',
 				'xal' => 'calmuco',
 				'zun' => 'zuni',

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
			'Gujr' => 'gujarati',
 			'Hrkt' => 'katakana o hiragana',
 			'Laoo' => 'lao',
 			'Latn' => 'latín',
 			'Mlym' => 'malabar',
 			'Mtei' => 'manipuri',
 			'Syrc' => 'siríaco',

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
			'001' => 'mundo',
 			'011' => 'África del Oeste',
 			'014' => 'África del Este',
 			'015' => 'África del Norte',
 			'018' => 'África del Sur',
 			'030' => 'Asia del Este',
 			'034' => 'Asia del Sur',
 			'035' => 'Asia sudoriental',
 			'039' => 'Europa del Sur',
 			'145' => 'Asia del Oeste',
 			'151' => 'Europa del Este',
 			'154' => 'Europa del Norte',
 			'155' => 'Europa del Oeste',
 			'AC' => 'Isla Ascensión',
 			'AX' => 'Islas Åland',
 			'BA' => 'Bosnia-Herzegovina',
 			'CD@alt=variant' => 'Congo (República Democrática del Congo)',
 			'CG' => 'República del Congo',
 			'CI' => 'Costa de Marfil',
 			'EZ' => 'Eurozona',
 			'GB@alt=short' => 'R. U.',
 			'GS' => 'Islas Georgia del Sur y Sándwich del Sur',
 			'IC' => 'Islas Canarias',
 			'QO' => 'Islas Ultramarinas',
 			'RO' => 'Rumania',
 			'SA' => 'Arabia Saudita',
 			'TL' => 'Timor Oriental',
 			'TR@alt=variant' => 'Türkiye',
 			'UM' => 'Islas Ultramarinas de EE.UU.',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'colnormalization' => 'orden normalizado',

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
 				'islamic-rgsa' => q{calendario islámico (Arabia Saudita)},
 				'islamic-tbla' => q{calendario islámico tabular},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{ordenar símbolos},
 				'shifted' => q{ordenar ignorando símbolos},
 			},
 			'colbackwards' => {
 				'no' => q{ordenar acentos normalmente},
 				'yes' => q{ordenar acentos con inversión},
 			},
 			'colcasefirst' => {
 				'lower' => q{ordenar empezando por minúsculas},
 				'no' => q{ordenar siguiendo orden normal de mayúsculas y minúsculas},
 				'upper' => q{ordenar empezando por mayúsculas},
 			},
 			'colcaselevel' => {
 				'no' => q{ordenar sin distinguir entre mayúsculas y minúsculas},
 				'yes' => q{ordenar distinguiendo entre mayúsculas y minúsculas},
 			},
 			'collation' => {
 				'eor' => q{reglas de orden europeas},
 				'phonebook' => q{orden de agenda telefónica},
 			},
 			'numbers' => {
 				'tirh' => q{dígitos en tirh},
 				'traditional' => q{números traducionales},
 				'wara' => q{dígitos en Warang Citi},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'script' => 'Alfabeto: {0}',

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
					'acceleration-g-force' => {
						'name' => q(fuerza G),
						'one' => q({0} unidad de fuerza gravitacional),
						'other' => q({0} unidades de fuerza gravitacional),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(fuerza G),
						'one' => q({0} unidad de fuerza gravitacional),
						'other' => q({0} unidades de fuerza gravitacional),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojule),
						'other' => q({0} kilojules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojule),
						'other' => q({0} kilojules),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em tipográfico),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tipográfico),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milla escandinava),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milla escandinava),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(toneladas),
						'one' => q({0} tonelada),
						'other' => q({0} toneladas),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(toneladas),
						'one' => q({0} tonelada),
						'other' => q({0} toneladas),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(toneladas métricas),
						'one' => q({0} tonelada métrica),
						'other' => q({0} toneladas métricas),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(toneladas métricas),
						'one' => q({0} tonelada métrica),
						'other' => q({0} toneladas métricas),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(caballos de fuerza),
						'one' => q(caballo de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(caballos de fuerza),
						'one' => q(caballo de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-pies),
						'one' => q({0} acre pie),
						'other' => q({0} acres pies),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-pies),
						'one' => q({0} acre pie),
						'other' => q({0} acres pies),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(onzas fluidas),
						'one' => q({0} onza fluida),
						'other' => q({0} onzas fluidas),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(onzas fluidas),
						'one' => q({0} onza fluida),
						'other' => q({0} onzas fluidas),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metros²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metros²),
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
					'concentr-permyriad' => {
						'name' => q(‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d.),
						'one' => q({0}d.),
						'other' => q({0}dd.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d.),
						'one' => q({0}d.),
						'other' => q({0}dd.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}mm.),
						'per' => q({0}/m.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}mm.),
						'per' => q({0}/m.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem.),
						'one' => q({0}sem.),
						'other' => q({0}sems.),
						'per' => q({0}/sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem.),
						'one' => q({0}sem.),
						'other' => q({0}sems.),
						'per' => q({0}/sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a.),
						'one' => q({0}a.),
						'other' => q({0}aa.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a.),
						'one' => q({0}a.),
						'other' => q({0}aa.),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0} cal),
						'other' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0} cal),
						'other' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0}thm EE.UU.),
						'other' => q({0}thm EE.UU.),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}thm EE.UU.),
						'other' => q({0}thm EE.UU.),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh/100km),
						'other' => q({0} kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh/100km),
						'other' => q({0} kWh/100km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0}p),
						'other' => q({0}p),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0}p),
						'other' => q({0}p),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(aa. l.),
						'one' => q({0}a. l.),
						'other' => q({0}a.a. l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(aa. l.),
						'one' => q({0}a. l.),
						'other' => q({0}a.a. l.),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}mi esc.),
						'other' => q({0}mi esc.),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}mi esc.),
						'other' => q({0}mi esc.),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} oz),
						'other' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0}ozt),
						'other' => q({0}ozt),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0}ozt),
						'other' => q({0}ozt),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} lb),
						'other' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0}lb),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}ton),
						'other' => q({0}ton),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}ton),
						'other' => q({0}ton),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0} ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0} ac ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0} qt imp.),
						'other' => q({0}qt imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0} qt imp.),
						'other' => q({0}qt imp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grados),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grados),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dd.),
						'one' => q({0} d.),
						'other' => q({0} dd.),
						'per' => q({0}/d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dd.),
						'one' => q({0} d.),
						'other' => q({0} dd.),
						'per' => q({0}/d.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mm.),
						'one' => q({0} m.),
						'other' => q({0} mm.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mm.),
						'one' => q({0} m.),
						'other' => q({0} mm.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sems.),
						'one' => q({0} sem.),
						'other' => q({0} sems.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sems.),
						'one' => q({0} sem.),
						'other' => q({0} sems.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(aa.),
						'one' => q({0} a.),
						'other' => q({0} aa.),
						'per' => q({0}/a.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(aa.),
						'one' => q({0} a.),
						'other' => q({0} aa.),
						'per' => q({0}/a.),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(aa. l.),
						'one' => q({0} a. l.),
						'other' => q({0} aa. l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(aa. l.),
						'one' => q({0} a. l.),
						'other' => q({0} aa. l.),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pto.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pto.),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yardas),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yardas),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} tza.),
						'other' => q({0} tza.),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} tza.),
						'other' => q({0} tza.),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pintas),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pintas),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cdas.),
						'one' => q({0} cda.),
						'other' => q({0} cdas.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cdas.),
						'one' => q({0} cda.),
						'other' => q({0} cdas.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cdtas.),
						'one' => q({0} cdta.),
						'other' => q({0} cdtas.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cdtas.),
						'one' => q({0} cdta.),
						'other' => q({0} cdtas.),
					},
				},
			} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000000000000' => {
					'one' => '0 billón',
					'other' => '0 billón',
				},
				'10000000000000' => {
					'one' => '00 billones',
					'other' => '00 billones',
				},
				'100000000000000' => {
					'one' => '000 billones',
					'other' => '000 billones',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 K',
					'other' => '0 K',
				},
				'10000' => {
					'one' => '00 k',
					'other' => '00 k',
				},
				'100000' => {
					'one' => '000 k',
					'other' => '000 k',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
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
						'positive' => '¤#,##0.00',
					},
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
		'ANG' => {
			display_name => {
				'currency' => q(florín de las Antillas Neerlandesas),
				'one' => q(florín de las Antillas Neerlandesas),
				'other' => q(florines de las Antillas Neerlandesas),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dólar de Bermudas),
				'one' => q(dólar de Bermudas),
				'other' => q(dólares de Bermudas),
			},
		},
		'EGP' => {
			symbol => 'E£',
		},
		'EUR' => {
			symbol => 'EUR',
		},
		'FKP' => {
			symbol => 'FK£',
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde haitiano),
				'one' => q(gourde haitiano),
				'other' => q(gourdes haitianos),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kazajo),
				'one' => q(tenge kazajo),
				'other' => q(tengues kazajos),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malauí),
				'one' => q(kwacha malauí),
				'other' => q(kwachas malauíes),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(córdoba nicaragüense),
				'one' => q(córdoba nicaragüense),
				'other' => q(córdobas nicaragüenses),
			},
		},
		'SSP' => {
			symbol => 'SD£',
		},
		'SYP' => {
			symbol => 'S£',
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(baht tailandes),
				'one' => q(baht tailandes),
				'other' => q(bahts tailandeses),
			},
		},
		'USD' => {
			symbol => 'USD',
		},
		'UZS' => {
			display_name => {
				'currency' => q(som uzbeko),
				'one' => q(som uzbeko),
				'other' => q(soms uzbekos),
			},
		},
		'VEF' => {
			symbol => 'BsF',
		},
		'VND' => {
			symbol => 'VND',
		},
		'XXX' => {
			display_name => {
				'one' => q(\(unidad de moneda desconocida\)),
				'other' => q(\(moneda desconocida\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
					wide => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
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
				'stand-alone' => {
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

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					wide => {0 => '1.º trimestre',
						1 => '2.º trimestre',
						2 => '3.º trimestre',
						3 => '4.º trimestre'
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
			if ($_ eq 'coptic') {
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
			if ($_ eq 'hebrew') {
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
			if ($_ eq 'indian') {
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
			if ($_ eq 'islamic') {
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
			if ($_ eq 'roc') {
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
				'wide' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
			},
			'stand-alone' => {
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
		'coptic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'a.C.',
				'1' => 'd.C.'
			},
		},
		'hebrew' => {
		},
		'indian' => {
			abbreviated => {
				'0' => 'Saka'
			},
		},
		'islamic' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'antes de R.O.C.',
				'1' => 'R.O.C.'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'coptic' => {
		},
		'generic' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{d 'de' MMM 'de' y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'roc' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'coptic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'coptic' => {
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
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			GyMMM => q{MMM 'de' y G},
			GyMMMEd => q{E, d 'de' MMM 'de' y G},
			GyMMMd => q{d 'de' MMM 'de' y G},
			MMMEd => q{E, d 'de' MMM},
			MMMd => q{d 'de' MMM},
			yMEd => q{E d/M/y G},
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMMM => q{MMM 'de' y G},
			yyyyMMMEd => q{EEE, d 'de' MMM 'de' y G},
			yyyyMMMd => q{d 'de' MMM 'de' y G},
			yyyyQQQ => q{QQQ 'de' y G},
		},
		'gregorian' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			GyMMMd => q{d 'de' MMM 'de' y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmsvvvv => q{HH:mm:ss vvvv},
			Hmv => q{HH:mm v},
			MMMdd => q{dd-MMM},
			yMEd => q{E d/M/y},
			yMMMEd => q{E, d MMM y},
			yQQQ => q{QQQ 'de' y},
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
			Gy => {
				y => q{y–y G},
			},
			GyM => {
				y => q{MM/y – MM/y GGGGG},
			},
			MEd => {
				M => q{E, d/M–E, d/M},
				d => q{E, d/M–E, d/M},
			},
			MMMEd => {
				M => q{E, d 'de' MMM–E, d 'de' MMM},
				d => q{E, d 'de' MMM–E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM–d 'de' MMM},
			},
			Md => {
				M => q{d/M–d/M},
				d => q{d/M–d/M},
			},
			fallback => '{0}–{1}',
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
		},
		'gregorian' => {
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			GyMMMEd => {
				G => q{E d MMM 'de' y G – E d MMM 'de' y G},
				M => q{E d MMM – E d MMM 'de' y G},
				d => q{E d MMM – E d MMM 'de' y G},
				y => q{E d MMM 'de' y – E d MMM 'de' y G},
			},
			GyMMMd => {
				G => q{d MMM 'de' y G – d MMM 'de' y G},
				M => q{d MMM – d MMM 'de' y G},
				d => q{d–d MMM 'de' y G},
				y => q{d MMM 'de' y – d MMM 'de' y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			MEd => {
				M => q{E, d/M–E, d/M},
				d => q{E, d/M–E, d/M},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d – d 'de' MMM},
			},
			Md => {
				M => q{d/M–d/M},
				d => q{d/M–d/M},
			},
			h => {
				a => q{h a–h a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
			},
			hv => {
				a => q{h a–h a v},
			},
			yM => {
				M => q{M/y–M/y},
				y => q{M/y–M/y},
			},
			yMEd => {
				M => q{E, d/M/y–E, d/M/y},
				d => q{E, d/M/y–E, d/M/y},
				y => q{E, d/M/y–E, d/M/y},
			},
			yMMM => {
				y => q{MMM 'de' y – MMM 'de' y},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y},
			},
			yMMMM => {
				y => q{MMMM 'de' y–MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y},
				d => q{d – d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y},
			},
			yMd => {
				M => q{d/M/y–d/M/y},
				d => q{d/M/y–d/M/y},
				y => q{d/M/y–d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(hora de verano de {0}),
		regionFormat => q(hora estándar de {0}),
		'Africa/Conakry' => {
			exemplarCity => q#Conakry#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fuerte Nelson#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasáu#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Santo Tomás#,
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#hora de verano de la montaña#,
				'generic' => q#hora de la montaña#,
				'standard' => q#hora estándar de la montaña#,
			},
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Islas Canarias#,
		},
		'Cocos' => {
			long => {
				'standard' => q#hora de Islas Cocos#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#hora de verano media de las islas Cook#,
				'generic' => q#hora de las islas Cook#,
				'standard' => q#hora estándar de las islas Cook#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#hora de verano de la Isla de Pascua#,
				'generic' => q#hora de la Isla de Pascua#,
				'standard' => q#hora estándar de Isla de Pascua#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#hora universal coordinada#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ciudad desconocida#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#hora estándar de Irlanda#,
			},
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe_Central' => {
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#hora de verano de Europa del Este#,
				'generic' => q#hora de Europa del Este#,
				'standard' => q#hora estándar de Europa del Este#,
			},
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#horario del lejano este de Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#hora de verano de Europa del Oeste#,
				'generic' => q#hora de Europa del Oeste#,
				'standard' => q#hora estándar de Europa del Oeste#,
			},
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#hora de verano de las Islas Malvinas#,
				'generic' => q#hora de las Islas Malvinas#,
				'standard' => q#hora estándar de las Islas Malvinas#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#hora de las Tierras Australes y Antárticas Francesas#,
			},
		},
		'GMT' => {
			short => {
				'standard' => q#∅∅∅#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#hora de Islas Gilbert#,
			},
		},
		'India' => {
			long => {
				'standard' => q#hora de India#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#hora de la Isla Macquarie#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#hora de Islas Marshall#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#hora de Myanmar (Birmania)#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#hora de verano de la Isla Norfolk#,
				'generic' => q#hora de la Isla Norfolk#,
				'standard' => q#hora estándar de la Isla Norfolk#,
			},
		},
		'Pacific/Wake' => {
			exemplarCity => q#Isla Wake#,
		},
		'Pyongyang' => {
			long => {
				'standard' => q#hora de Pionyang#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#hora de Islas Salomón#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#hora de Isla Wake#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
