=head1

Locale::CLDR::Locales::Fr::Any::Ca - Package for language French

=cut

package Locale::CLDR::Locales::Fr::Any::Ca;
# This file auto generated from Data\common\main\fr_CA.xml
#	on Fri 13 Apr  7:10:51 am GMT

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

extends('Locale::CLDR::Locales::Fr::Any');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ady' => 'adygué',
 				'ang' => 'vieil anglais',
 				'az' => 'azerbaïdjanais',
 				'bez' => 'bena',
 				'bik' => 'bicol',
 				'byn' => 'bilen',
 				'byv' => 'medumba',
 				'chg' => 'tchagatay',
 				'chn' => 'chinook',
 				'ckb' => 'kurde central',
 				'cr' => 'cri',
 				'den' => 'slave',
 				'dgr' => 'tlicho',
 				'esu' => 'yupik central',
 				'ewo' => 'ewondo',
 				'frc' => 'cajun',
 				'frp' => 'franco-provençal',
 				'gbz' => 'dari',
 				'goh' => 'vieux haut-allemand',
 				'gu' => 'gujarati',
 				'ii' => 'yi de Sichuan',
 				'ilo' => 'ilocano',
 				'kbd' => 'kabarde',
 				'ken' => 'kenyang',
 				'kj' => 'kuanyama',
 				'kl' => 'kalaallisut',
 				'ksh' => 'kölsch',
 				'liv' => 'live',
 				'luo' => 'luo',
 				'lzh' => 'chinois classique',
 				'mgo' => 'meta’',
 				'mwr' => 'marwari',
 				'mwv' => 'mentawai',
 				'nds' => 'bas allemand',
 				'nds_NL' => 'bas saxon',
 				'njo' => 'ao naga',
 				'nwc' => 'newari classique',
 				'nyn' => 'nkole',
 				'or' => 'odia',
 				'pau' => 'palauan',
 				'pdc' => 'allemand de Pennsylvanie',
 				'pdt' => 'bas allemand mennonite',
 				'peo' => 'vieux perse',
 				'pfl' => 'palatin',
 				'pro' => 'ancien occitan',
 				'rar' => 'rarotonga',
 				'rup' => 'aroumain',
 				'sat' => 'santali',
 				'sdh' => 'kurde méridional',
 				'se' => 'same du Nord',
 				'sei' => 'seri',
 				'sg' => 'sango',
 				'sga' => 'vieil irlandais',
 				'sly' => 'selayar',
 				'sma' => 'same du Sud',
 				'smj' => 'same de Lule',
 				'sms' => 'same skolt',
 				'stq' => 'frison de Saterland',
 				'sus' => 'sosso',
 				'sw_CD' => 'swahili congolais',
 				'tru' => 'turoyo',
 				'tzm' => 'tamazight',
 				'vo' => 'volapük',

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
			'Deva' => 'devanagari',
 			'Gujr' => 'gujarati',
 			'Hanb' => 'hanb',
 			'Hans@alt=stand-alone' => 'caractères chinois simplifiés',
 			'Hant@alt=stand-alone' => 'caractères chinois traditionnels',
 			'Hrkt' => 'syllabaires japonais',
 			'Orya' => 'odia',
 			'Zsye' => 'zsye',

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
			'151' => 'Europe orientale',
 			'AC' => 'île de l’Ascension',
 			'AX' => 'îles d’Åland',
 			'BN' => 'Brunei',
 			'BV' => 'île Bouvet',
 			'BY' => 'Bélarus',
 			'CC' => 'îles Cocos (Keeling)',
 			'CI@alt=variant' => 'République de Côte d’Ivoire',
 			'CK' => 'îles Cook',
 			'CX' => 'île Christmas',
 			'FK' => 'îles Malouines',
 			'FK@alt=variant' => 'îles Falkland (Malouines)',
 			'FM' => 'Micronésie',
 			'FO' => 'îles Féroé',
 			'HM' => 'îles Heard et McDonald',
 			'IC' => 'îles Canaries',
 			'IM' => 'île de Man',
 			'IO' => 'territoire britannique de l’océan Indien',
 			'MF' => 'Saint-Martin (France)',
 			'MM' => 'Myanmar',
 			'MP' => 'Mariannes du Nord',
 			'NF' => 'île Norfolk',
 			'PN' => 'îles Pitcairn',
 			'QO' => 'Océanie lointaine',
 			'RE' => 'la Réunion',
 			'SX' => 'Saint-Martin (Pays-Bas)',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor oriental',
 			'UM' => 'îles mineures éloignées des États-Unis',
 			'VA' => 'Cité du Vatican',
 			'VC' => 'Saint-Vincent-et-les Grenadines',
 			'VG' => 'îles Vierges britanniques',
 			'VI' => 'îles Vierges américaines',

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
 				'ethiopic-amete-alem' => q{Calendrier éthiopien de l’An de grâce},
 				'islamic-umalqura' => q{calendrier musulman (calculé, Umm al-Qura)},
 			},
 			'collation' => {
 				'dictionary' => q{Ordre de tri du dictionnaire},
 				'eor' => q{ordre multilingue européen},
 				'reformed' => q{Ordre de tri réformé},
 				'searchjl' => q{Rechercher par consonne initiale en hangeul},
 			},
 			'm0' => {
 				'bgn' => q{BGN (commission de toponymie des États-Unis)},
 				'ungegn' => q{GENUNG},
 			},
 			'numbers' => {
 				'gujr' => q{chiffres gujaratis},
 				'mong' => q{Chiffres mongols},
 				'taml' => q{chiffres tamouls traditionnels},
 			},

		}
	},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'arc-second' => {
						'one' => q({0} seconde d’angle),
						'other' => q({0} secondes d’angle),
					},
					'cubic-yard' => {
						'name' => q(verges cubes),
						'one' => q({0} verge cube),
						'other' => q({0} verges cubes),
					},
					'g-force' => {
						'name' => q(force G),
					},
					'gallon-imperial' => {
						'name' => q(gallon impérial),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'kilogram' => {
						'per' => q({0} par kilogramme),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomètres à l’heure),
					},
					'liter-per-100kilometers' => {
						'name' => q(litres aux 100 kilomètres),
						'one' => q({0} litre aux 100 kilomètres),
						'other' => q({0} litres aux 100 kilomètres),
					},
					'microgram' => {
						'one' => q({0} microgramme),
						'other' => q({0} microgrammes),
					},
					'mile' => {
						'name' => q(mille),
						'one' => q({0} mille),
						'other' => q({0} milles),
					},
					'mile-per-gallon' => {
						'name' => q(milles au gallon),
						'one' => q({0} mille au gallon),
						'other' => q({0} milles au gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(milles au gallon impérial),
						'one' => q({0} mille au gallon impérial),
						'other' => q({0} milles au gallon impérial),
					},
					'mile-per-hour' => {
						'name' => q(milles à l’heure),
						'one' => q({0} mille à l’heure),
						'other' => q({0} milles à l’heure),
					},
					'part-per-million' => {
						'name' => q(parties par million),
						'one' => q({0} partie par million),
						'other' => q({0} parties par million),
					},
					'pint' => {
						'name' => q(chopine),
						'one' => q({0} chopine),
						'other' => q({0} chopines),
					},
					'quart' => {
						'name' => q(pintes),
						'one' => q({0} pinte),
						'other' => q({0} pintes),
					},
					'second' => {
						'per' => q({0} à la seconde),
					},
					'square-mile' => {
						'per' => q({0} par mille carré),
					},
					'square-yard' => {
						'name' => q(verges carrées),
						'one' => q({0} verge carrée),
						'other' => q({0} verges carrées),
					},
					'stone' => {
						'other' => q({0} stone),
					},
					'teaspoon' => {
						'name' => q(cuillères à thé),
						'one' => q({0} cuillère à thé),
						'other' => q({0} cuillères à thé),
					},
					'yard' => {
						'name' => q(verges),
						'one' => q({0} verge),
						'other' => q({0} verges),
					},
				},
				'narrow' => {
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'century' => {
						'one' => q(´{0}s.),
						'other' => q(´{0}s.),
					},
					'decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					'foot' => {
						'one' => q({0}pi),
						'other' => q({0}pi),
					},
					'inch' => {
						'one' => q({0}po),
						'other' => q({0}po),
					},
					'inch-hg' => {
						'name' => q(inHg),
					},
					'kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'knot' => {
						'one' => q({0}nd),
						'other' => q({0}nd),
					},
					'light-year' => {
						'one' => q({0}al),
						'other' => q({0}al),
					},
					'liter' => {
						'name' => q(L),
						'one' => q({0}L),
						'other' => q({0}L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'meter-per-second-squared' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					'metric-ton' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					'microgram' => {
						'one' => q({0}µg),
						'other' => q({0}µg),
					},
					'micrometer' => {
						'one' => q({0}µm),
						'other' => q({0}µm),
					},
					'microsecond' => {
						'one' => q({0}µs),
						'other' => q({0}µs),
					},
					'mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					'millimeter-of-mercury' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					'minute' => {
						'per' => q({0}/m),
					},
					'month' => {
						'per' => q({0}/m),
					},
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					'nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					'nautical-mile' => {
						'name' => q(NM),
						'one' => q({0}NM),
						'other' => q({0}NM),
					},
					'parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					'point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					'stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					'ton' => {
						'name' => q(tc),
						'one' => q({0}tc),
						'other' => q({0}tc),
					},
					'week' => {
						'per' => q({0}/sem),
					},
					'yard' => {
						'name' => q(vg),
						'one' => q({0}vg),
						'other' => q({0}vg),
					},
				},
				'short' => {
					'astronomical-unit' => {
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'cubic-foot' => {
						'one' => q({0} pi³),
						'other' => q({0} pi³),
					},
					'cubic-yard' => {
						'name' => q(vg³),
						'one' => q({0} vg³),
						'other' => q({0} vg³),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'fluid-ounce' => {
						'name' => q(oz liq.),
						'one' => q({0} oz liq.),
						'other' => q({0} oz liq.),
					},
					'foot' => {
						'one' => q({0} pi),
						'other' => q({0} pi),
					},
					'gallon-imperial' => {
						'name' => q(gal Imp),
						'one' => q({0} gal Imp),
						'other' => q({0} gal Imp),
						'per' => q({0}/gal Imp),
					},
					'generic' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'karat' => {
						'name' => q(carats),
					},
					'kilobit' => {
						'name' => q(kb),
					},
					'liter' => {
						'name' => q(L),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'megabit' => {
						'name' => q(Mb),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gal Imp),
						'one' => q({0} mi/gal Imp),
						'other' => q({0} mi/gal Imp),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'nautical-mile' => {
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
					},
					'pint' => {
						'name' => q(chop),
						'one' => q({0} chop),
						'other' => q({0} chop),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(pte),
						'one' => q({0} pte),
						'other' => q({0} pte),
					},
					'square-foot' => {
						'one' => q({0} pi²),
						'other' => q({0} pi²),
					},
					'square-yard' => {
						'name' => q(vg²),
						'one' => q({0} vg²),
						'other' => q({0} vg²),
					},
					'teaspoon' => {
						'name' => q(c. à t.),
						'one' => q({0} c. à t.),
						'other' => q({0} c. à t.),
					},
					'ton' => {
						'name' => q(tc),
						'one' => q({0} tc),
						'other' => q({0} tc),
					},
					'yard' => {
						'name' => q(vg),
						'one' => q({0} vg),
						'other' => q({0} vg),
					},
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
				'1000' => {
					'one' => '0 mille',
					'other' => '0 mille',
				},
			},
			'short' => {
				'1000000000' => {
					'one' => '0 G',
					'other' => '0 G',
				},
				'10000000000' => {
					'one' => '00 G',
					'other' => '00 G',
				},
				'100000000000' => {
					'one' => '000 G',
					'other' => '000 G',
				},
				'1000000000000' => {
					'one' => '0 T',
					'other' => '0 T',
				},
				'10000000000000' => {
					'one' => '00 T',
					'other' => '00 T',
				},
				'100000000000000' => {
					'one' => '000 T',
					'other' => '000 T',
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
		'ARS' => {
			symbol => 'ARS',
		},
		'AUD' => {
			symbol => '$ AU',
		},
		'BMD' => {
			symbol => 'BMD',
		},
		'BND' => {
			symbol => 'BND',
		},
		'BSD' => {
			symbol => 'BSD',
		},
		'BYN' => {
			symbol => 'Br',
		},
		'BZD' => {
			symbol => 'BZD',
		},
		'CAD' => {
			symbol => '$',
		},
		'CLP' => {
			symbol => 'CLP',
		},
		'CNY' => {
			symbol => 'CN¥',
		},
		'COP' => {
			symbol => 'COP',
		},
		'FJD' => {
			symbol => 'FJD',
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(livre des Îles Malouines),
				'one' => q(livre des Îles Malouines),
				'other' => q(livres des Îles Malouines),
			},
		},
		'GBP' => {
			symbol => '£',
		},
		'GEL' => {
			symbol => 'GEL',
		},
		'GIP' => {
			symbol => 'GIP',
		},
		'HKD' => {
			symbol => '$ HK',
		},
		'ILS' => {
			symbol => 'ILS',
		},
		'INR' => {
			symbol => 'INR',
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iranien),
				'one' => q(rial iranien),
				'other' => q(rials iraniens),
			},
		},
		'JPY' => {
			symbol => '¥',
		},
		'KMF' => {
			symbol => 'CF',
		},
		'KRW' => {
			symbol => 'KRW',
		},
		'LBP' => {
			symbol => 'LBP',
		},
		'MXN' => {
			symbol => 'MXN',
		},
		'NAD' => {
			symbol => 'NAD',
		},
		'NIO' => {
			symbol => 'C$',
		},
		'NZD' => {
			symbol => '$ NZ',
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omanais),
				'one' => q(rial omanais),
				'other' => q(rials omanis),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rial saoudien),
				'one' => q(rial saoudien),
				'other' => q(rials saoudiens),
			},
		},
		'SBD' => {
			symbol => 'SBD',
		},
		'SGD' => {
			symbol => '$ SG',
		},
		'SRD' => {
			symbol => 'SRD',
		},
		'TOP' => {
			display_name => {
				'currency' => q(pa’anga),
				'one' => q(pa’anga),
				'other' => q(pa’angas),
			},
		},
		'TRY' => {
			symbol => 'TL',
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(dollar de Trinité-et-Tobago),
			},
		},
		'USD' => {
			symbol => '$ US',
		},
		'UYU' => {
			symbol => 'UYU',
		},
		'VND' => {
			symbol => 'VND',
		},
		'XAF' => {
			symbol => 'XAF',
		},
		'XOF' => {
			symbol => 'XOF',
		},
		'XPF' => {
			symbol => 'XPF',
		},
		'XXX' => {
			display_name => {
				'currency' => q(Devise inconnue),
				'one' => q(\(devise inconnue\)),
				'other' => q(\(devise inconnue\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial yéménite),
				'one' => q(rial yéménite),
				'other' => q(rials yéménites),
			},
		},
		'ZMW' => {
			symbol => 'ZK',
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
					narrow => {
						nonleap => [
							'T',
							'B',
							'H',
							'K',
							'T',
							'A',
							'B',
							'B',
							'B',
							'B',
							'A',
							'M',
							'N'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'',
							'',
							'',
							'kyakh'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'T',
							'B',
							'H',
							'K',
							'T',
							'A',
							'B',
							'B',
							'B',
							'B',
							'A',
							'M',
							'N'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'',
							'',
							'',
							'kyakh'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					narrow => {
						nonleap => [
							'M',
							'T',
							'H',
							'T',
							'T',
							'Y',
							'M',
							'M',
							'G',
							'S',
							'H',
							'N',
							'P'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'M',
							'T',
							'H',
							'T',
							'T',
							'Y',
							'M',
							'M',
							'G',
							'S',
							'H',
							'N',
							'P'
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
							'janv.',
							'févr.',
							'mars',
							'avr.',
							'mai',
							'juin',
							'juill.',
							'août',
							'sept.',
							'oct.',
							'nov.',
							'déc.'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'janv.',
							'févr.',
							'mars',
							'avr.',
							'mai',
							'juin',
							'juill.',
							'août',
							'sept.',
							'oct.',
							'nov.',
							'déc.'
						],
						leap => [
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
					narrow => {
						nonleap => [
							'C',
							'V',
							'J',
							'Ā',
							'S',
							'B',
							'Ā',
							'K',
							'M',
							'P',
							'M',
							'P'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'C',
							'V',
							'J',
							'Ā',
							'S',
							'B',
							'Ā',
							'K',
							'M',
							'P',
							'M',
							'P'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Far.',
							'Ord.',
							'Kho.',
							'Tir',
							'Mor.',
							'Šah.',
							'Mehr',
							'Âbâ.',
							'Âzar',
							'Dey',
							'Bah.',
							'Esf.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Farvardin',
							'Ordibehešt',
							'Khordâd',
							'Tir',
							'Mordâd',
							'Šahrivar',
							'Mehr',
							'Âbân',
							'Âzar',
							'Dey',
							'Bahman',
							'Esfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Far.',
							'Ord.',
							'Kho.',
							'Tir',
							'Mor.',
							'Šah.',
							'Mehr',
							'Âbâ.',
							'Âzar',
							'Dey',
							'Bah.',
							'Esf.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Farvardin',
							'Ordibehešt',
							'Khordâd',
							'Tir',
							'Mordâd',
							'Šahrivar',
							'Mehr',
							'Âbân',
							'Âzar',
							'Dey',
							'Bahman',
							'Esfand'
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
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
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
				'wide' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'night1' => q{mat.},
					'noon' => q{midi},
					'morning1' => q{mat.},
					'afternoon1' => q{après-midi},
					'pm' => q{p},
					'midnight' => q{minuit},
					'am' => q{a},
					'evening1' => q{soir},
				},
				'abbreviated' => {
					'am' => q{a.m.},
					'evening1' => q{du soir},
					'midnight' => q{minuit},
					'pm' => q{p.m.},
					'noon' => q{midi},
					'night1' => q{du mat.},
					'afternoon1' => q{après-midi},
					'morning1' => q{du mat.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'morning1' => q{mat.},
					'afternoon1' => q{après-midi},
					'night1' => q{nuit},
					'evening1' => q{soir},
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'wide' => {
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'night1' => q{nuit},
				},
				'narrow' => {
					'morning1' => q{mat.},
					'afternoon1' => q{après-midi},
					'night1' => q{mat.},
					'evening1' => q{soir},
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'indian' => {
			wide => {
				'0' => 'Saka'
			},
		},
		'islamic' => {
			narrow => {
				'0' => 'AH'
			},
			wide => {
				'0' => 'Anno Hegirae'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
			wide => {
				'0' => 'AP'
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
		'ethiopic' => {
		},
		'generic' => {
			'short' => q{yy-MM-dd GGGGG},
		},
		'gregorian' => {
			'short' => q{yy-MM-dd},
		},
		'indian' => {
		},
		'islamic' => {
			'short' => q{y-MM-dd GGGGG},
		},
		'persian' => {
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
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH 'h' mm 'min' ss 's' zzzz},
			'long' => q{HH 'h' mm 'min' ss 's' z},
			'medium' => q{HH 'h' mm 'min' ss 's'},
			'short' => q{HH 'h' mm},
		},
		'indian' => {
		},
		'islamic' => {
		},
		'persian' => {
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
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'medium' => q{{1} {0}},
		},
		'indian' => {
		},
		'islamic' => {
		},
		'persian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'islamic' => {
			MEd => q{E d MMM},
			Md => q{MM-dd},
			yyyyM => q{y-MM GGGGG},
			yyyyMEd => q{E y-MM-dd GGGGG},
			yyyyMd => q{y-MM-dd GGGGG},
		},
		'gregorian' => {
			Bh => q{h 'h' B},
			Bhm => q{h 'h' mm B},
			Bhms => q{h 'h' mm 'min' ss 's' B},
			EBhm => q{E h 'h' mm B},
			EBhms => q{E h 'h' mm 'min' ss 's' B},
			EHm => q{E HH 'h' mm},
			EHms => q{E HH 'h' mm 'min' ss 's'},
			Ehm => q{E h 'h' mm a},
			Ehms => q{E h 'h' mm 'min' ss 's' a},
			Hm => q{HH 'h' mm},
			Hms => q{HH 'h' mm 'min' ss 's'},
			Hmsv => q{HH 'h' mm 'min' ss 's' v},
			Hmv => q{HH 'h' mm v},
			MEd => q{E M-d},
			MMd => q{MM-d},
			MMdd => q{MM-dd},
			Md => q{M-d},
			h => q{h 'h' a},
			hm => q{h 'h' mm a},
			hms => q{h 'h' mm 'min' ss 's' a},
			hmsv => q{h 'h' mm 'min' ss 's' a v},
			hmv => q{h 'h' mm a v},
			ms => q{mm 'min' ss 's'},
			yM => q{y-MM},
			yMEd => q{E y-MM-dd},
			yMM => q{y-MM},
			yMd => q{y-MM-dd},
		},
		'generic' => {
			Bh => q{h 'h' B},
			Bhm => q{h 'h' mm B},
			Bhms => q{h 'h' mm 'min' ss 's' B},
			EBhm => q{E h 'h' mm B},
			EBhms => q{E h 'h' mm 'min' ss 's' B},
			EHm => q{E HH 'h' mm},
			EHms => q{E HH 'h' mm 'min' ss 's'},
			Ehm => q{E h 'h' mm a},
			Ehms => q{E h 'h' mm 'min' ss 's' a},
			H => q{HH 'h'},
			Hm => q{HH 'h' mm},
			Hms => q{HH 'h' mm 'min' ss 's'},
			MEd => q{E M-d},
			MMd => q{MM-d},
			MMdd => q{MM-dd},
			Md => q{M-d},
			h => q{h 'h' a},
			hm => q{h 'h' mm a},
			hms => q{h 'h' mm 'min' ss 's' a},
			ms => q{mm 'min' ss 's'},
			yyyyM => q{y-MM G},
			yyyyMEd => q{E y-MM-dd G},
			yyyyMM => q{y-MM G},
			yyyyMd => q{y-MM-dd G},
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
		'gregorian' => {
			H => {
				H => q{H 'h' – H 'h'},
			},
			Hm => {
				H => q{H 'h' mm – H 'h' mm},
				m => q{H 'h' mm – H 'h' mm},
			},
			Hmv => {
				H => q{H 'h' mm – H 'h' mm v},
				m => q{H 'h' mm – H 'h' mm v},
			},
			Hv => {
				H => q{H 'h' – H 'h' v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E MM-dd – E MM-dd},
				d => q{E MM-dd – E MM-dd},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMd => {
				d => q{d – d MMM},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h 'h' a – h 'h' a},
				h => q{h 'h' – h 'h' a},
			},
			hm => {
				a => q{h 'h' mm a – h 'h' mm a},
				h => q{h 'h' mm – h 'h' mm a},
				m => q{h 'h' mm – h 'h' mm a},
			},
			hmv => {
				a => q{h 'h' mm a – h 'h' mm a v},
				h => q{h 'h' mm – h 'h' mm a v},
				m => q{h 'h' mm – h 'h' mm a v},
			},
			hv => {
				a => q{h 'h' a – h 'h' a v},
				h => q{h 'h' – h 'h' a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd},
				d => q{E y-MM-dd – E y-MM-dd},
				y => q{E y-MM-dd – E y-MM-dd},
			},
			yMMM => {
				M => q{MMM – MMM y},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'generic' => {
			MEd => {
				M => q{E MM-dd – E MM-dd},
				d => q{E MM-dd – E MM-dd},
			},
			MMMEd => {
				d => q{E d – E d MMM},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			yM => {
				M => q{y-MM – y-MM G},
				y => q{y-MM – y-MM G},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd G},
				d => q{E y-MM-dd – E y-MM-dd G},
				y => q{E y-MM-dd – E y-MM-dd G},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd G},
				d => q{y-MM-dd – y-MM-dd G},
				y => q{y-MM-dd – y-MM-dd G},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} (heure avancée)),
		regionFormat => q({0} (heure normale)),
		'Acre' => {
			long => {
				'daylight' => q#heure avancée de l’Acre#,
				'generic' => q#heure de l’Acre#,
				'standard' => q#heure normale de l’Acre#,
			},
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli [Libye]#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#heure d’Afrique centrale#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#heure d’Afrique orientale#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#heure normale d’Afrique du Sud#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#heure avancée d’Afrique de l’Ouest#,
				'generic' => q#heure d’Afrique de l’Ouest#,
				'standard' => q#heure normale d’Afrique de l’Ouest#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#heure avancée de l’Alaska#,
				'generic' => q#heure de l’Alaska#,
				'standard' => q#heure normale de l’Alaska#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#heure avancée d’Alma Ata#,
				'generic' => q#heure d’Alma Ata#,
				'standard' => q#heure normale d’Alma Ata#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#heure avancée de l’Amazonie#,
				'generic' => q#heure de l’Amazonie#,
				'standard' => q#heure normale de l’Amazonie#,
			},
		},
		'America/Barbados' => {
			exemplarCity => q#Barbade (La)#,
		},
		'America/Cayman' => {
			exemplarCity => q#îles Caïmans#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah [Dakota du Nord]#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center [Dakota du Nord]#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota du Nord#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint-Christophe-et-Niévès#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#heure avancée du Centre#,
				'generic' => q#heure du Centre#,
				'standard' => q#heure normale du Centre#,
			},
			short => {
				'daylight' => q#HAC#,
				'generic' => q#HC#,
				'standard' => q#HNC#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#heure avancée de l’Est#,
				'generic' => q#heure de l’Est#,
				'standard' => q#heure normale de l’Est#,
			},
			short => {
				'daylight' => q#HAE#,
				'generic' => q#HE#,
				'standard' => q#HNE#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#heure avancée des Rocheuses#,
				'generic' => q#heure des Rocheuses#,
				'standard' => q#heure normale des Rocheuses#,
			},
			short => {
				'daylight' => q#HAR#,
				'generic' => q#HR#,
				'standard' => q#HNR#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#heure avancée du Pacifique#,
				'generic' => q#heure du Pacifique#,
				'standard' => q#heure normale du Pacifique#,
			},
			short => {
				'daylight' => q#HAP#,
				'generic' => q#HP#,
				'standard' => q#HNP#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#heure avancée d’Anadyr#,
				'generic' => q#heure d’Anadyr#,
				'standard' => q#heure normale d’Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#heure avancée d’Apia#,
				'generic' => q#heure d’Apia#,
				'standard' => q#heure normale d’Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#heure avancée d’Aktaou#,
				'generic' => q#heure d’Aktaou#,
				'standard' => q#heure normale d’Aktaou#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#heure avancée d’Aqtöbe#,
				'generic' => q#heure d’Aqtöbe#,
				'standard' => q#heure normale d’Aqtöbe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#heure avancée de l’Arabie#,
				'generic' => q#heure de l’Arabie#,
				'standard' => q#heure normale de l’Arabie#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#heure avancée de l’Argentine#,
				'generic' => q#heure de l’Argentine#,
				'standard' => q#heure normale d’Argentine#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#heure avancée de l’Ouest argentin#,
				'generic' => q#heure de l’Ouest argentin#,
				'standard' => q#heure normale de l’Ouest argentin#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#heure avancée d’Arménie#,
				'generic' => q#heure de l’Arménie#,
				'standard' => q#heure normale de l’Arménie#,
			},
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphou#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#heure avancée de l’Atlantique#,
				'generic' => q#heure de l’Atlantique#,
				'standard' => q#heure normale de l’Atlantique#,
			},
		},
		'Atlantic/Canary' => {
			exemplarCity => q#îles Canaries#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#îles Féroé#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#heure avancée du centre de l’Australie#,
				'generic' => q#heure du centre de l’Australie#,
				'standard' => q#heure normale du centre de l’Australie#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#heure avancée du centre-ouest de l’Australie#,
				'generic' => q#heure du centre-ouest de l’Australie#,
				'standard' => q#heure normale du centre-ouest de l’Australie#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#heure avancée de l’Est de l’Australie#,
				'generic' => q#heure de l’Est de l’Australie#,
				'standard' => q#heure normale de l’Est de l’Australie#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#heure avancée de l’Ouest de l’Australie#,
				'generic' => q#heure de l’Ouest de l’Australie#,
				'standard' => q#heure normale de l’Ouest de l’Australie#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#heure avancée d’Azerbaïdjan#,
				'generic' => q#heure de l’Azerbaïdjan#,
				'standard' => q#heure normale de l’Azerbaïdjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#heure avancée des Açores#,
				'generic' => q#heure des Açores#,
				'standard' => q#heure normale des Açores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#heure avancée du Bangladesh#,
				'generic' => q#heure du Bangladesh#,
				'standard' => q#heure normale du Bangladesh#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#heure avancée de Brasilia#,
				'generic' => q#heure de Brasilia#,
				'standard' => q#heure normale de Brasilia#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#heure avancée du Cap-Vert#,
				'generic' => q#heure du Cap-Vert#,
				'standard' => q#heure normale du Cap-Vert#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#heure avancée des Îles Chatham#,
				'generic' => q#heure des îles Chatham#,
				'standard' => q#heure normale des Îles Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#heure avancée du Chili#,
				'generic' => q#heure du Chili#,
				'standard' => q#heure normale du Chili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#heure avancée de Chine#,
				'generic' => q#heure de Chine#,
				'standard' => q#heure normale de Chine#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#heure avancée de Choibalsan#,
				'generic' => q#heure de Choibalsan#,
				'standard' => q#heure normale de Choibalsan#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#heure avancée de Colombie#,
				'generic' => q#heure de Colombie#,
				'standard' => q#heure normale de Colombie#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#heure avancée des îles Cook#,
				'generic' => q#heure des îles Cook#,
				'standard' => q#heure normale des îles Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#heure avancée de Cuba#,
				'generic' => q#heure de Cuba#,
				'standard' => q#heure normale de Cuba#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#heure avancée de l’île de Pâques#,
				'generic' => q#heure de l’île de Pâques#,
				'standard' => q#heure normale de l’île de Pâques#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#temps universel coordonné#,
			},
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#heure avancée irlandaise#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#île de Man#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#heure avancée britannique#,
			},
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatican#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#heure avancée d’Europe centrale#,
				'generic' => q#heure d’Europe centrale#,
				'standard' => q#heure normale d’Europe centrale#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#heure avancée d’Europe de l’Est#,
				'generic' => q#heure d’Europe de l’Est#,
				'standard' => q#heure normale d’Europe de l’Est#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#heure avancée d’Europe de l’Ouest#,
				'generic' => q#heure d’Europe de l’Ouest#,
				'standard' => q#heure normale d’Europe de l’Ouest#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#heure avancée des îles Malouines#,
				'generic' => q#heure des îles Malouines#,
				'standard' => q#heure normale des îles Malouines#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#heure avancée des îles Fidji#,
				'generic' => q#heure des îles Fidji#,
				'standard' => q#heure normale des îles Fidji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#heure de Guyane française#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#heure avancée de Géorgie#,
				'generic' => q#heure de la Géorgie#,
				'standard' => q#heure normale de la Géorgie#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#heure avancée de l’Est du Groenland#,
				'generic' => q#heure de l’Est du Groenland#,
				'standard' => q#heure normale de l’Est du Groenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#heure avancée de l’Ouest du Groenland#,
				'generic' => q#heure de l’Ouest du Groenland#,
				'standard' => q#heure normale de l’Ouest du Groenland#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#heure avancée d’Hawaï-Aléoutiennes#,
				'generic' => q#heure d’Hawaï-Aléoutiennes#,
				'standard' => q#heure normale d’Hawaï-Aléoutiennes#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#heure avancée de Hong Kong#,
				'generic' => q#heure de Hong Kong#,
				'standard' => q#heure normale de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#heure avancée de Hovd#,
				'generic' => q#heure de Hovd#,
				'standard' => q#heure normale de Hovd#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#heure avancée d’Iran#,
				'generic' => q#heure de l’Iran#,
				'standard' => q#heure normale d’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#heure avancée d’Irkoutsk#,
				'generic' => q#heure d’Irkoutsk#,
				'standard' => q#heure normale d’Irkoutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#heure avancée d’Israël#,
				'generic' => q#heure d’Israël#,
				'standard' => q#heure normale d’Israël#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#heure avancée du Japon#,
				'generic' => q#heure du Japon#,
				'standard' => q#heure normale du Japon#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#heure avancée de Petropavlovsk-Kamchatski#,
				'generic' => q#heure de Petropavlovsk-Kamchatski#,
				'standard' => q#heure normale de Petropavlovsk-Kamchatski#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#heure avancée de Corée#,
				'generic' => q#heure de la Corée#,
				'standard' => q#heure normale de la Corée#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#heure avancée de Krasnoïarsk#,
				'generic' => q#heure de Krasnoïarsk#,
				'standard' => q#heure normale de Krasnoïarsk#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#heure avancée de Lord Howe#,
				'generic' => q#heure de Lord Howe#,
				'standard' => q#heure normale de Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#heure avancée de Macao#,
				'generic' => q#heure de Macao#,
				'standard' => q#heure normale de Macao#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#heure avancée de Magadan#,
				'generic' => q#heure de Magadan#,
				'standard' => q#heure normale de Magadan#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#heure avancée de Maurice#,
				'generic' => q#heure de Maurice#,
				'standard' => q#heure normale de Maurice#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#heure avancée du Nord-Ouest du Mexique#,
				'generic' => q#heure du Nord-Ouest du Mexique#,
				'standard' => q#heure normale du Nord-Ouest du Mexique#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#heure avancée du Pacifique mexicain#,
				'generic' => q#heure du Pacifique mexicain#,
				'standard' => q#heure normale du Pacifique mexicain#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#heure avancée d’Oulan-Bator#,
				'generic' => q#heure d’Oulan-Bator#,
				'standard' => q#heure normale d’Oulan-Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#heure avancée de Moscou#,
				'generic' => q#heure de Moscou#,
				'standard' => q#heure normale de Moscou#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#heure avancée de Nouvelle-Calédonie#,
				'generic' => q#heure de la Nouvelle-Calédonie#,
				'standard' => q#heure normale de la Nouvelle-Calédonie#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#heure avancée de la Nouvelle-Zélande#,
				'generic' => q#heure de la Nouvelle-Zélande#,
				'standard' => q#heure normale de la Nouvelle-Zélande#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#heure avancée de Terre-Neuve#,
				'generic' => q#heure de Terre-Neuve#,
				'standard' => q#heure normale de Terre-Neuve#,
			},
			short => {
				'daylight' => q#HAT#,
				'generic' => q#HT#,
				'standard' => q#HNT#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#heure avancée de Fernando de Noronha#,
				'generic' => q#heure de Fernando de Noronha#,
				'standard' => q#heure normale de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#heure avancée de Novossibirsk#,
				'generic' => q#heure de Novossibirsk#,
				'standard' => q#heure normale de Novossibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#heure avancée d’Omsk#,
				'generic' => q#heure d’Omsk#,
				'standard' => q#heure normale d’Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#île de Pâques#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#heure avancée du Pakistan#,
				'generic' => q#heure du Pakistan#,
				'standard' => q#heure normale du Pakistan#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#heure avancée du Paraguay#,
				'generic' => q#heure du Paraguay#,
				'standard' => q#heure normale du Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#heure avancée du Pérou#,
				'generic' => q#heure du Pérou#,
				'standard' => q#heure normale du Pérou#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#heure avancée des Philippines#,
				'generic' => q#heure des Philippines#,
				'standard' => q#heure normale des Philippines#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#heure avancée de Saint-Pierre-et-Miquelon#,
				'generic' => q#heure de Saint-Pierre-et-Miquelon#,
				'standard' => q#heure normale de Saint-Pierre-et-Miquelon#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#heure de la Réunion#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#heure avancée de Sakhaline#,
				'generic' => q#heure de Sakhaline#,
				'standard' => q#heure normale de Sakhaline#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#heure avancée des Samoa#,
				'generic' => q#heure des Samoa#,
				'standard' => q#heure normale des Samoa#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#heure avancée de Taipei#,
				'generic' => q#heure de Taipei#,
				'standard' => q#heure normale de Taipei#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#heure avancée de Tonga#,
				'generic' => q#heure des Tonga#,
				'standard' => q#heure normale des Tonga#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#heure avancée du Turkménistan#,
				'generic' => q#heure du Turkménistan#,
				'standard' => q#heure normale du Turkménistan#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#heure avancée de l’Uruguay#,
				'generic' => q#heure de l’Uruguay#,
				'standard' => q#heure normale de l’Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#heure avancée de l’Ouzbékistan#,
				'generic' => q#heure de l’Ouzbékistan#,
				'standard' => q#heure normale de l’Ouzbékistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#heure avancée de Vanuatu#,
				'generic' => q#heure du Vanuatu#,
				'standard' => q#heure normale du Vanuatu#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#heure avancée de Vladivostok#,
				'generic' => q#heure de Vladivostok#,
				'standard' => q#heure normale de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#heure avancée de Volgograd#,
				'generic' => q#heure de Volgograd#,
				'standard' => q#heure normale de Volgograd#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#heure avancée de Iakoutsk#,
				'generic' => q#heure de Iakoutsk#,
				'standard' => q#heure normale de Iakoutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#heure avancée d’Ekaterinbourg#,
				'generic' => q#heure d’Ekaterinbourg#,
				'standard' => q#heure normale d’Ekaterinbourg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
