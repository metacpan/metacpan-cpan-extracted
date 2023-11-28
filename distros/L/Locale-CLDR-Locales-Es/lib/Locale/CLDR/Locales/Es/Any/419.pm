=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Any::419 - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::419;
# This file auto generated from Data\common\main\es_419.xml
#	on Sat  4 Nov  6:00:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Es::Any');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'digits-ordinal-masculine-adjective','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal' ]},
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
				'ace' => 'achenés',
 				'ady' => 'adigeo',
 				'alt' => 'altái del sur',
 				'arp' => 'arapajó',
 				'ars' => 'árabe de Néyed',
 				'bla' => 'siksiká',
 				'en_GB@alt=short' => 'inglés (R.U.)',
 				'eu' => 'vasco',
 				'fon' => 'fon',
 				'goh' => 'alemán de la alta edad antigua',
 				'grc' => 'griego clásico',
 				'gu' => 'gujarati',
 				'ht' => 'haitiano',
 				'kbd' => 'cabardiano',
 				'krc' => 'karachái-bálkaro',
 				'lo' => 'laosiano',
 				'luo' => 'luo',
 				'nr' => 'ndebele del sur',
 				'nso' => 'sesotho del norte',
 				'prg' => 'prusiano antiguo',
 				'ps@alt=variant' => 'pashtún',
 				'rm' => 'retorrománico',
 				'shu' => 'árabe (Chad)',
 				'sma' => 'sami del sur',
 				'st' => 'sesotho del sur',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili (Congo)',
 				'syr' => 'siríaco',
 				'tet' => 'tetun',
 				'tyv' => 'tuvano',
 				'tzm' => 'tamazight del Marruecos Central',
 				'ug@alt=variant' => 'uighur',
 				'vai' => 'vai',
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
			'Hanb' => 'han con bopomofo',
 			'Hrkt' => 'katakana o hiragana',
 			'Laoo' => 'lao',
 			'Latn' => 'latín',
 			'Mlym' => 'malayalam',

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
			'011' => 'África del Oeste',
 			'014' => 'África del Este',
 			'015' => 'África del Norte',
 			'018' => 'África del Sur',
 			'030' => 'Asia del Este',
 			'034' => 'Asia del Sur',
 			'035' => 'Asia sudoriental',
 			'039' => 'Europa del Sur',
 			'057' => 'región de Micronesia',
 			'145' => 'Asia del Oeste',
 			'151' => 'Europa del Este',
 			'154' => 'Europa del Norte',
 			'155' => 'Europa del Oeste',
 			'AC' => 'Isla Ascensión',
 			'BA' => 'Bosnia-Herzegovina',
 			'CD@alt=variant' => 'Congo (República Democrática del Congo)',
 			'CG' => 'República del Congo',
 			'CI' => 'Costa de Marfil',
 			'EZ' => 'Eurozona',
 			'GB@alt=short' => 'R. U.',
 			'GG' => 'Guernesey',
 			'IC' => 'Islas Canarias',
 			'QO' => 'Islas Ultramarinas',
 			'TA' => 'Tristán da Cunha',
 			'TL' => 'Timor Oriental',
 			'UM' => 'Islas Ultramarinas de EE.UU.',
 			'VI' => 'Islas Vírgenes de los Estados Unidos',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'colalternate' => 'orden ignorando símbolos',
 			'colbackwards' => 'orden de acentos con inversión',
 			'colcasefirst' => 'orden de mayúsculas/minúsculas',
 			'colcaselevel' => 'orden con distinción entre mayúsculas y minúsculas',
 			'lb' => 'salto de línea',
 			'ms' => 'sm',

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
 				'islamic-umalqura' => q{islamic-umalqura},
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
 				'compat' => q{orden anterior, para compatibilidad},
 				'eor' => q{reglas de orden europeas},
 				'phonebook' => q{orden de agenda telefónica},
 			},
 			'lb' => {
 				'loose' => q{salto de línea flexible},
 				'strict' => q{salto de línea estricto},
 			},
 			'ms' => {
 				'metric' => q{Sistema Métrico de Unidades},
 				'uksystem' => q{sistema inglés},
 				'ussystem' => q{Sistema Anglosajón de Unidades},
 			},
 			'numbers' => {
 				'tirh' => q{dígitos en tirh},
 				'traditional' => q{números traducionales},
 				'wara' => q{dígitos en Warang Citi},
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
			'US' => q{anglosajón},

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

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre-foot' => {
						'name' => q(acre-pies),
						'one' => q({0} acre pie),
						'other' => q({0} acres pies),
					},
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					'gigahertz' => {
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(caballos de fuerza),
						'one' => q(caballo de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					'kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojule),
						'other' => q({0} kilojules),
					},
					'kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatts-hora),
						'one' => q({0} kilowatt-hora),
						'other' => q({0} kilowatts-hora),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					'mile-scandinavian' => {
						'name' => q(milla escandinava),
					},
					'milliampere' => {
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'milliwatt' => {
						'name' => q(miliwatts),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatts),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'revolution' => {
						'name' => q(revolución),
					},
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
				},
				'narrow' => {
					'astronomical-unit' => {
						'name' => q(ua),
					},
					'carat' => {
						'name' => q(ct),
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					'cup' => {
						'one' => q({0} tza.),
					},
					'day' => {
						'name' => q(d.),
						'one' => q({0}d.),
						'other' => q({0}dd.),
						'per' => q({0}/d.),
					},
					'g-force' => {
						'name' => q(G),
					},
					'knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					'light-year' => {
						'name' => q(aa. l.),
						'one' => q({0}a. l.),
						'other' => q({0}a.a. l.),
					},
					'meter-per-second-squared' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
					},
					'microgram' => {
						'one' => q({0}µg),
						'other' => q({0}µg),
					},
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					'month' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}mm.),
						'per' => q({0}/m.),
					},
					'ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0}ozt),
						'other' => q({0}ozt),
					},
					'parsec' => {
						'name' => q(parsec),
					},
					'ton' => {
						'name' => q(ton),
						'one' => q({0}ton),
						'other' => q({0}ton),
					},
					'week' => {
						'name' => q(sem.),
						'one' => q({0}sem.),
						'other' => q({0}sems.),
						'per' => q({0}/sem.),
					},
					'year' => {
						'name' => q(a.),
						'one' => q({0}a.),
						'other' => q({0}aa.),
					},
				},
				'short' => {
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'day' => {
						'name' => q(dd.),
						'one' => q({0} d.),
						'other' => q({0} dd.),
						'per' => q({0}/d.),
					},
					'degree' => {
						'name' => q(grados),
					},
					'g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon-imperial' => {
						'per' => q({0}/gal Imp.),
					},
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'karat' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'light-year' => {
						'name' => q(aa. l.),
						'one' => q({0} a. l.),
						'other' => q({0} aa. l.),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'mile-per-gallon-imperial' => {
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					'month' => {
						'name' => q(mm.),
						'one' => q({0} m.),
						'other' => q({0} mm.),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
					},
					'parsec' => {
						'name' => q(parsecs),
					},
					'pint' => {
						'name' => q(pintas),
					},
					'point' => {
						'name' => q(pto.),
					},
					'stone' => {
						'name' => q(stones),
					},
					'tablespoon' => {
						'name' => q(cdas.),
						'one' => q({0} cda.),
						'other' => q({0} cdas.),
					},
					'teaspoon' => {
						'name' => q(cdtas.),
						'one' => q({0} cdta.),
						'other' => q({0} cdtas.),
					},
					'ton' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					'volt' => {
						'name' => q(volts),
					},
					'watt' => {
						'name' => q(watts),
					},
					'week' => {
						'name' => q(sems.),
						'one' => q({0} sem.),
						'other' => q({0} sems.),
					},
					'yard' => {
						'name' => q(yardas),
					},
					'year' => {
						'name' => q(aa.),
						'one' => q({0} a.),
						'other' => q({0} aa.),
						'per' => q({0}/a.),
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
				'1000000000' => {
					'one' => '0k M',
					'other' => '0k M',
				},
				'10000000000' => {
					'one' => '00k M',
					'other' => '00k M',
				},
				'100000000000' => {
					'one' => '000k M',
					'other' => '000k M',
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
					'accounting' => {
						'positive' => '¤#,##0.00',
					},
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
		'AMD' => {
			display_name => {
				'currency' => q(dram armenio),
			},
		},
		'BGN' => {
			display_name => {
				'one' => q(lev búlgaro),
				'other' => q(leva búlgaros),
			},
		},
		'CAD' => {
			symbol => 'CAD',
		},
		'EGP' => {
			symbol => 'E£',
		},
		'ERN' => {
			display_name => {
				'currency' => q(nafka),
			},
		},
		'EUR' => {
			symbol => 'EUR',
		},
		'FKP' => {
			symbol => 'FK£',
		},
		'LVL' => {
			display_name => {
				'one' => q(lats letón),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit malayo),
				'one' => q(ringgit malayo),
				'other' => q(ringgits malayos),
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
			display_name => {
				'currency' => q(bolívar venezolano),
				'one' => q(bolívar venezolano),
				'other' => q(bolívares venezolanos),
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
		},
		'XAF' => {
			display_name => {
				'currency' => q(franco CFA BEAC),
				'one' => q(franco CFA BEAC),
				'other' => q(francos CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franco CFA BCEAO),
				'one' => q(franco CFA BCEAO),
				'other' => q(francos CFA BCEAO),
			},
		},
		'XXX' => {
			display_name => {
				'one' => q(\(unidad de moneda desconocida\)),
				'other' => q(\(moneda desconocida\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kuacha zambiano),
				'one' => q(kuacha zambiano),
				'other' => q(kuachas zambianos),
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
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'ene.',
							'feb.',
							'mar.',
							'abr.',
							'may.',
							'jun.',
							'jul.',
							'ago.',
							'sep.',
							'oct.',
							'nov.',
							'dic.'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'ene.',
							'feb.',
							'mar.',
							'abr.',
							'may.',
							'jun.',
							'jul.',
							'ago.',
							'sep.',
							'oct.',
							'nov.',
							'dic.'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
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
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
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
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
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
							'Tamuz'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
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
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
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
						mon => 'l',
						tue => 'm',
						wed => 'm',
						thu => 'j',
						fri => 'v',
						sat => 's',
						sun => 'd'
					},
				},
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
				'stand-alone' => {
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
				'abbreviated' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
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
		'coptic' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'hebrew' => {
		},
		'indian' => {
			abbreviated => {
				'0' => 'Saka'
			},
			narrow => {
				'0' => 'Saka'
			},
			wide => {
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
			narrow => {
				'0' => 'antes de R.O.C.',
				'1' => 'R.O.C.'
			},
			wide => {
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
			'medium' => q{d 'de' MMM 'de' y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
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
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		},
		'gregorian' => {
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
			MMMdd => q{dd-MMM},
			yMEd => q{E d/M/y},
			yMMM => q{MMMM 'de' y},
			yMMMEd => q{E, d 'de' MMM 'de' y},
			yMMMd => q{d 'de' MMMM 'de' y},
			yQQQ => q{QQQ 'de' y},
			yw => q{'semana' w 'de' Y},
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
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			MEd => {
				M => q{E, d/M–E, d/M},
				d => q{E, d/M–E, d/M},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d – d 'de' MMM},
			},
			h => {
				a => q{h a–h a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
			},
			hv => {
				a => q{h a–h a v},
			},
			yMEd => {
				M => q{E, d/M/y–E, d/M/y},
				d => q{E, d/M/y–E, d/M/y},
				y => q{E, d/M/y–E, d/M/y},
			},
			yMMM => {
				y => q{MMM 'de' y – MMM 'de' y},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y},
			},
			yMMMM => {
				y => q{MMMM 'de' y–MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y},
				d => q{d – d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y},
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
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fuerte Nelson#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasáu#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Pablo#,
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
		'Asia/Dushanbe' => {
			exemplarCity => q#Duchanbé#,
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
				'standard' => q#Hora Universal Coordinada#,
			},
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
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
		'Norfolk' => {
			long => {
				'standard' => q#hora de la Isla Norfolk#,
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
