=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fr::Latn::Ca - Package for language French

=cut

package Locale::CLDR::Locales::Fr::Latn::Ca;
# This file auto generated from Data\common\main\fr_CA.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Fr::Latn');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ady' => 'adygué',
 				'ang' => 'vieil anglais',
 				'asa' => 'asou',
 				'bbj' => 'ghomala',
 				'bik' => 'bicol',
 				'byn' => 'bilen',
 				'byv' => 'medumba',
 				'chg' => 'tchagatay',
 				'chn' => 'chinook',
 				'ckb' => 'kurde central',
 				'ckb@alt=menu' => 'kurde central',
 				'ckb@alt=variant' => 'sorani',
 				'cr' => 'cri',
 				'crg' => 'michif',
 				'crl' => 'cri du Nord-Est',
 				'crr' => 'algonquin de la Caroline',
 				'den' => 'slave',
 				'dgr' => 'tlicho',
 				'ebu' => 'embou',
 				'en_GB@alt=short' => 'anglais (R.-U.)',
 				'en_US@alt=short' => 'anglais (É.-U.)',
 				'esu' => 'yupik central',
 				'ewo' => 'ewondo',
 				'frc' => 'cajun',
 				'frp' => 'franco-provençal',
 				'goh' => 'vieux haut-allemand',
 				'gu' => 'gujarati',
 				'ii' => 'yi de Sichuan',
 				'ken' => 'kenyang',
 				'kl' => 'kalaallisut',
 				'ks' => 'kashmiri',
 				'ksb' => 'chambala',
 				'liv' => 'live',
 				'lu' => 'luba-katanga',
 				'lzh' => 'chinois classique',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mwr' => 'marwari',
 				'mwv' => 'mentawai',
 				'nds_NL' => 'bas saxon',
 				'njo' => 'ao naga',
 				'nmg' => 'kwasio',
 				'nwc' => 'newari classique',
 				'nyn' => 'nkole',
 				'oka' => 'okanagan',
 				'pau' => 'palauan',
 				'pdc' => 'allemand de Pennsylvanie',
 				'pdt' => 'bas allemand mennonite',
 				'peo' => 'vieux perse',
 				'pfl' => 'palatin',
 				'pis' => 'pidgin',
 				'pro' => 'ancien occitan',
 				'quc' => 'k’iche’',
 				'rar' => 'rarotonga',
 				'sbp' => 'sangu',
 				'sdh' => 'kurde méridional',
 				'sei' => 'seri',
 				'sga' => 'vieil irlandais',
 				'sly' => 'selayar',
 				'smn' => 'sami d’Inari',
 				'stq' => 'frison de Saterland',
 				'sus' => 'sosso',
 				'sw_CD' => 'swahili congolais',
 				'tru' => 'turoyo',
 				'tzm' => 'tamazight',
 				'ug@alt=variant' => 'ouïghour',
 				'yue@alt=menu' => 'chinois, cantonais',
 				'zh@alt=menu' => 'chinois, mandarin',
 				'zh_Hans@alt=long' => 'chinois, mandarin simplifié',
 				'zh_Hant@alt=long' => 'chinois, mandarin traditionnel',

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
 			'Hans' => 'idéogrammes han simplifiés',
 			'Hans@alt=stand-alone' => 'caractères chinois simplifiés',
 			'Hant' => 'idéogrammes han traditionnels',
 			'Hant@alt=stand-alone' => 'caractères chinois traditionnels',
 			'Hrkt' => 'syllabaires japonais',
 			'Olck' => 'ol chiki',
 			'Zsye' => 'émoji',

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
			'030' => 'Asie orientale',
 			'039' => 'Europe méridionale',
 			'145' => 'Asie occidentale',
 			'151' => 'Europe orientale',
 			'154' => 'Europe septentrionale',
 			'155' => 'Europe occidentale',
 			'AC' => 'île de l’Ascension',
 			'AX' => 'îles d’Åland',
 			'BN' => 'Brunéi',
 			'BV' => 'île Bouvet',
 			'BY' => 'Bélarus',
 			'BZ' => 'Bélize',
 			'CC' => 'îles Cocos (Keeling)',
 			'CK' => 'îles Cook',
 			'CP' => 'île Clipperton',
 			'CX' => 'île Christmas',
 			'FK' => 'îles Malouines',
 			'FK@alt=variant' => 'îles Falkland (Malouines)',
 			'FO' => 'îles Féroé',
 			'HM' => 'îles Heard et McDonald',
 			'IC' => 'îles Canaries',
 			'IM' => 'île de Man',
 			'IO@alt=biot' => 'territoire britannique de l’océan Indien',
 			'IO@alt=chagos' => 'archipel Chagos',
 			'KG' => 'Kirghizistan',
 			'KN' => 'Saint‑Kitts‑et‑Nevis',
 			'LR' => 'Libéria',
 			'MF' => 'Saint-Martin (France)',
 			'MM' => 'Myanmar',
 			'MP' => 'Mariannes du Nord',
 			'NF' => 'île Norfolk',
 			'NG' => 'Nigéria',
 			'PN' => 'îles Pitcairn',
 			'QO' => 'Océanie lointaine',
 			'RE' => 'la Réunion',
 			'SX' => 'Saint-Martin (Pays-Bas)',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor oriental',
 			'UM' => 'îles mineures éloignées des États-Unis',
 			'VA' => 'Cité du Vatican',
 			'VE' => 'Vénézuéla',
 			'VG' => 'îles Vierges britanniques',
 			'VI' => 'îles Vierges américaines',
 			'VN' => 'Vietnam',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'collation' => {
 				'big5han' => q{ordre de tri chinois traditionnel - Big5},
 				'dictionary' => q{ordre de tri du dictionnaire},
 				'eor' => q{ordre multilingue européen},
 				'gb2312han' => q{ordre de tri chinois simplifié - GB2312},
 				'phonebook' => q{ordre de tri de l’annuaire},
 				'pinyin' => q{ordre de tri pinyin},
 				'searchjl' => q{Rechercher par consonne initiale en hangeul},
 				'stroke' => q{ordre de tri des traits},
 				'traditional' => q{ordre de tri traditionnel},
 				'zhuyin' => q{ordre de tri zhuyin},
 			},
 			'd0' => {
 				'fwidth' => q{pleine chasse},
 				'hwidth' => q{demi-chasse},
 			},
 			'm0' => {
 				'bgn' => q{BGN (commission de toponymie des États-Unis)},
 				'ungegn' => q{GENUNG},
 			},
 			'numbers' => {
 				'gujr' => q{chiffres gujaratis},
 				'mong' => q{Chiffres mongols},
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
			'language' => 'langue : {0}',
 			'script' => 'écriture : {0}',
 			'region' => 'région : {0}',

		}
	},
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[áåäãā ē íìī ñ óòöø úǔ]},
		};
	},
EOT
: sub {
		return {};
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
					# Long Unit Identifier
					'' => {
						'name' => q(point cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(point cardinal),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(force g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(force g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q({0} mètre par seconde carrée),
						'other' => q({0} mètres par seconde carrée),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0} mètre par seconde carrée),
						'other' => q({0} mètres par seconde carrée),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} degré),
						'other' => q({0} degrés),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} degré),
						'other' => q({0} degrés),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} radian),
						'other' => q({0} radians),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} radian),
						'other' => q({0} radians),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0} centimètre carré),
						'other' => q({0} centimètres carrés),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0} centimètre carré),
						'other' => q({0} centimètres carrés),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} pied carré),
						'other' => q({0} pieds carrés),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} pied carré),
						'other' => q({0} pieds carrés),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0} pouce carré),
						'other' => q({0} pouces carrés),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0} pouce carré),
						'other' => q({0} pouces carrés),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} kilomètre carré),
						'other' => q({0} kilomètres carrés),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} kilomètre carré),
						'other' => q({0} kilomètres carrés),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} mètre carré),
						'other' => q({0} mètres carrés),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} mètre carré),
						'other' => q({0} mètres carrés),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mille carré),
						'other' => q({0} milles carrés),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mille carré),
						'other' => q({0} milles carrés),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(verges carrées),
						'one' => q({0} verge carrée),
						'other' => q({0} verges carrées),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(verges carrées),
						'one' => q({0} verge carrée),
						'other' => q({0} verges carrées),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} pour mille),
						'other' => q({0} pour mille),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} pour mille),
						'other' => q({0} pour mille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parties par million),
						'one' => q({0} partie par million),
						'other' => q({0} parties par million),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parties par million),
						'one' => q({0} partie par million),
						'other' => q({0} parties par million),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(parties par milliard),
						'one' => q({0} partie par milliard),
						'other' => q({0} parties par milliard),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(parties par milliard),
						'one' => q({0} partie par milliard),
						'other' => q({0} parties par milliard),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litres aux 100 kilomètres),
						'one' => q({0} litre aux 100 kilomètres),
						'other' => q({0} litres aux 100 kilomètres),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litres aux 100 kilomètres),
						'one' => q({0} litre aux 100 kilomètres),
						'other' => q({0} litres aux 100 kilomètres),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milles au gallon),
						'one' => q({0} mille au gallon),
						'other' => q({0} milles au gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milles au gallon),
						'one' => q({0} mille au gallon),
						'other' => q({0} milles au gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milles au gallon impérial),
						'one' => q({0} mille au gallon impérial),
						'other' => q({0} milles au gallon impérial),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milles au gallon impérial),
						'one' => q({0} mille au gallon impérial),
						'other' => q({0} milles au gallon impérial),
					},
					# Long Unit Identifier
					'coordinate' => {
						'west' => q({0} ouest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'west' => q({0} ouest),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} octet),
						'other' => q({0} octets),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} octet),
						'other' => q({0} octets),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0} gigaoctet),
						'other' => q({0} gigaoctets),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0} gigaoctet),
						'other' => q({0} gigaoctets),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0} kilooctet),
						'other' => q({0} kilooctets),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0} kilooctet),
						'other' => q({0} kilooctets),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q({0} mégabit),
						'other' => q({0} mégabits),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q({0} mégabit),
						'other' => q({0} mégabits),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0} mégaoctet),
						'other' => q({0} mégaoctets),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0} mégaoctet),
						'other' => q({0} mégaoctets),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0} térabit),
						'other' => q({0} térabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0} térabit),
						'other' => q({0} térabits),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0} téraoctet),
						'other' => q({0} téraoctets),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0} téraoctet),
						'other' => q({0} téraoctets),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} jour),
						'other' => q({0} jours),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} jour),
						'other' => q({0} jours),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} heure),
						'other' => q({0} heures),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} heure),
						'other' => q({0} heures),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0} microseconde),
						'other' => q({0} microsecondes),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0} microseconde),
						'other' => q({0} microsecondes),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} milliseconde),
						'other' => q({0} millisecondes),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} milliseconde),
						'other' => q({0} millisecondes),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} mois),
						'other' => q({0} mois),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} mois),
						'other' => q({0} mois),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0} nanoseconde),
						'other' => q({0} nanosecondes),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0} nanoseconde),
						'other' => q({0} nanosecondes),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} seconde),
						'other' => q({0} secondes),
						'per' => q({0} à la seconde),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} seconde),
						'other' => q({0} secondes),
						'per' => q({0} à la seconde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} semaine),
						'other' => q({0} semaines),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} semaine),
						'other' => q({0} semaines),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0} ampère),
						'other' => q({0} ampères),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0} ampère),
						'other' => q({0} ampères),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0} milliampère),
						'other' => q({0} milliampères),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0} milliampère),
						'other' => q({0} milliampères),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unités thermiques britanniques),
						'one' => q({0} unité thermique britannique),
						'other' => q({0} unités thermiques britanniques),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unités thermiques britanniques),
						'one' => q({0} unité thermique britannique),
						'other' => q({0} unités thermiques britanniques),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0} calorie),
						'other' => q({0} calories),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0} calorie),
						'other' => q({0} calories),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowattheures),
						'one' => q({0} kilowattheure),
						'other' => q({0} kilowattheures),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowattheures),
						'one' => q({0} kilowattheure),
						'other' => q({0} kilowattheures),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(therms américains),
						'one' => q({0} therm américain),
						'other' => q({0} therms américains),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therms américains),
						'one' => q({0} therm américain),
						'other' => q({0} therms américains),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0} mégahertz),
						'other' => q({0} mégahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0} mégahertz),
						'other' => q({0} mégahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(point),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(point),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0} unité astronomique),
						'other' => q({0} unités astronomiques),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0} unité astronomique),
						'other' => q({0} unités astronomiques),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0} centimètre),
						'other' => q({0} centimètres),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0} centimètre),
						'other' => q({0} centimètres),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0} décimètre),
						'other' => q({0} décimètres),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0} décimètre),
						'other' => q({0} décimètres),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} pied),
						'other' => q({0} pieds),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} pied),
						'other' => q({0} pieds),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} pouce),
						'other' => q({0} pouces),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} pouce),
						'other' => q({0} pouces),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0} kilomètre),
						'other' => q({0} kilomètres),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0} kilomètre),
						'other' => q({0} kilomètres),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} année-lumière),
						'other' => q({0} années-lumière),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} année-lumière),
						'other' => q({0} années-lumière),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} mètre),
						'other' => q({0} mètres),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} mètre),
						'other' => q({0} mètres),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0} micromètre),
						'other' => q({0} micromètres),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0} micromètre),
						'other' => q({0} micromètres),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mille),
						'one' => q({0} mille),
						'other' => q({0} milles),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mille),
						'one' => q({0} mille),
						'other' => q({0} milles),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0} millimètre),
						'other' => q({0} millimètres),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0} millimètre),
						'other' => q({0} millimètres),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0} nanomètre),
						'other' => q({0} nanomètres),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0} nanomètre),
						'other' => q({0} nanomètres),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0} mille marin),
						'other' => q({0} milles marins),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0} mille marin),
						'other' => q({0} milles marins),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} picomètre),
						'other' => q({0} picomètres),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} picomètre),
						'other' => q({0} picomètres),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(feminine),
						'name' => q(verges),
						'one' => q({0} verge),
						'other' => q({0} verges),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(feminine),
						'name' => q(verges),
						'one' => q({0} verge),
						'other' => q({0} verges),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grain),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grain),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gramme),
						'other' => q({0} grammes),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gramme),
						'other' => q({0} grammes),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0} kilogramme),
						'other' => q({0} kilogrammes),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0} kilogramme),
						'other' => q({0} kilogrammes),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0} milligramme),
						'other' => q({0} milligrammes),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0} milligramme),
						'other' => q({0} milligrammes),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} once),
						'other' => q({0} onces),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} once),
						'other' => q({0} onces),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0} once troy),
						'other' => q({0} onces troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0} once troy),
						'other' => q({0} onces troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} livre),
						'other' => q({0} livres),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} livre),
						'other' => q({0} livres),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} tonne courte),
						'other' => q({0} tonnes courtes),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} tonne courte),
						'other' => q({0} tonnes courtes),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} cheval-vapeur),
						'other' => q({0} chevaux-vapeur),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} cheval-vapeur),
						'other' => q({0} chevaux-vapeur),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q({0} mégawatt),
						'other' => q({0} mégawatts),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0} mégawatt),
						'other' => q({0} mégawatts),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0} atmosphère),
						'other' => q({0} atmosphères),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0} atmosphère),
						'other' => q({0} atmosphères),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} pouce de mercure),
						'other' => q({0} pouces de mercure),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} pouce de mercure),
						'other' => q({0} pouces de mercure),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} millibar),
						'other' => q({0} millibars),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} millibar),
						'other' => q({0} millibars),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilomètres à l’heure),
						'one' => q({0} kilomètre par heure),
						'other' => q({0} kilomètres par heure),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilomètres à l’heure),
						'one' => q({0} kilomètre par heure),
						'other' => q({0} kilomètres par heure),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} mètre par seconde),
						'other' => q({0} mètres par seconde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} mètre par seconde),
						'other' => q({0} mètres par seconde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milles à l’heure),
						'one' => q({0} mille à l’heure),
						'other' => q({0} milles à l’heure),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milles à l’heure),
						'one' => q({0} mille à l’heure),
						'other' => q({0} milles à l’heure),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} degré Celsius),
						'other' => q({0} degrés Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} degré Celsius),
						'other' => q({0} degrés Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} degré Fahrenheit),
						'other' => q({0} degrés Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} degré Fahrenheit),
						'other' => q({0} degrés Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0} centimètre cube),
						'other' => q({0} centimètres cubes),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0} centimètre cube),
						'other' => q({0} centimètres cubes),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q({0} pied cube),
						'other' => q({0} pieds cubes),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0} pied cube),
						'other' => q({0} pieds cubes),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0} pouce cube),
						'other' => q({0} pouces cubes),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0} pouce cube),
						'other' => q({0} pouces cubes),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} kilomètre cube),
						'other' => q({0} kilomètres cubes),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} kilomètre cube),
						'other' => q({0} kilomètres cubes),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q({0} mètre cube),
						'other' => q({0} mètres cubes),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q({0} mètre cube),
						'other' => q({0} mètres cubes),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mille cube),
						'other' => q({0} milles cubes),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mille cube),
						'other' => q({0} milles cubes),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(verges cubes),
						'one' => q({0} verge cube),
						'other' => q({0} verges cubes),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(verges cubes),
						'one' => q({0} verge cube),
						'other' => q({0} verges cubes),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cuillère à dessert),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cuillère à dessert),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(goutte),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(goutte),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gallon impérial),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gallon impérial),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(gobelet doseur),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(gobelet doseur),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} litre),
						'other' => q({0} litres),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} litre),
						'other' => q({0} litres),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0} mégalitre),
						'other' => q({0} mégalitres),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0} mégalitre),
						'other' => q({0} mégalitres),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pincée),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pincée),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(chopine),
						'one' => q({0} chopine),
						'other' => q({0} chopines),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(chopine),
						'one' => q({0} chopine),
						'other' => q({0} chopines),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(feminine),
						'name' => q(pintes),
						'one' => q({0} pinte),
						'other' => q({0} pintes),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(feminine),
						'name' => q(pintes),
						'one' => q({0} pinte),
						'other' => q({0} pintes),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(feminine),
						'name' => q(pinte impériale),
						'one' => q({0} pinte impériale),
						'other' => q({0} pintes impériales),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(feminine),
						'name' => q(pinte impériale),
						'one' => q({0} pinte impériale),
						'other' => q({0} pintes impériales),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cuillères à thé),
						'one' => q({0} cuillère à thé),
						'other' => q({0} cuillères à thé),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cuillères à thé),
						'one' => q({0} cuillère à thé),
						'other' => q({0} cuillères à thé),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0}vg²),
						'other' => q({0}vg²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0}vg²),
						'other' => q({0}vg²),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(p.p. 10⁹),
						'one' => q({0}pp10⁹),
						'other' => q({0}pp10⁹),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(p.p. 10⁹),
						'one' => q({0}pp10⁹),
						'other' => q({0}pp10⁹),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(déc),
						'one' => q({0}déc),
						'other' => q({0}déc),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(déc),
						'one' => q({0}déc),
						'other' => q({0}déc),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem),
						'one' => q({0}sem),
						'other' => q({0}sem),
						'per' => q({0}/sem),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem),
						'one' => q({0}sem),
						'other' => q({0}sem),
						'per' => q({0}/sem),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0}BTU),
						'other' => q({0}BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}BTU),
						'other' => q({0}BTU),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0}therm US),
						'other' => q({0}therm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}therm US),
						'other' => q({0}therm US),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0}fm),
						'other' => q({0}fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}fm),
						'other' => q({0}fm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}pi),
						'other' => q({0}pi),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}pi),
						'other' => q({0}pi),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}po),
						'other' => q({0}po),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}po),
						'other' => q({0}po),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0}al),
						'other' => q({0}al),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}al),
						'other' => q({0}al),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}NM),
						'other' => q({0}NM),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}NM),
						'other' => q({0}NM),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0}vg),
						'other' => q({0}vg),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0}vg),
						'other' => q({0}vg),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}tc),
						'other' => q({0}tc),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}tc),
						'other' => q({0}tc),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(poHg),
						'one' => q({0}poHg),
						'other' => q({0}poHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(poHg),
						'one' => q({0}poHg),
						'other' => q({0}poHg),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Bf),
						'one' => q({0} Bf),
						'other' => q({0} Bf),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Bf),
						'one' => q({0} Bf),
						'other' => q({0} Bf),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0}nd),
						'other' => q({0}nd),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}nd),
						'other' => q({0}nd),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lb-pi),
						'other' => q({0}lb-pi),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lb-pi),
						'other' => q({0}lb-pi),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ac pi),
						'one' => q({0}ac pi),
						'other' => q({0}ac pi),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ac pi),
						'one' => q({0}ac pi),
						'other' => q({0}ac pi),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0}vg³),
						'other' => q({0}vg³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0}vg³),
						'other' => q({0}vg³),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(c. à d.),
						'one' => q({0}c. à d.),
						'other' => q({0}c. à d.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(c. à d.),
						'one' => q({0}c. à d.),
						'other' => q({0}c. à d.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(c. à. d. imp.),
						'one' => q({0}c. à. d. imp.),
						'other' => q({0} c. à. d. imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(c. à. d. imp.),
						'one' => q({0}c. à. d. imp.),
						'other' => q({0} c. à. d. imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dr. liq),
						'one' => q({0}dr. liq),
						'other' => q({0}dr. liq),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dr. liq),
						'one' => q({0}dr. liq),
						'other' => q({0}dr. liq),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gtt.),
						'one' => q({0}gtt.),
						'other' => q({0}gtt.),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gtt.),
						'one' => q({0}gtt.),
						'other' => q({0}gtt.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q({0}oz liq.),
						'other' => q({0}oz liq.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q({0}oz liq.),
						'other' => q({0}oz liq.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0}oz liq imp.),
						'other' => q({0}oz liq imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}oz liq imp.),
						'other' => q({0}oz liq imp.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal imp),
						'one' => q({0}/gal imp),
						'other' => q({0}/gal imp),
						'per' => q({0}/gal imp),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal imp),
						'one' => q({0}/gal imp),
						'other' => q({0}/gal imp),
						'per' => q({0}/gal imp),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(gob. doseur),
						'one' => q({0}gob. doseur),
						'other' => q({0}gob. doseurs),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(gob. doseur),
						'one' => q({0}gob. doseur),
						'other' => q({0}gob. doseurs),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q({0}pincée),
						'other' => q({0}pincées),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0}pincée),
						'other' => q({0}pincées),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0}chop),
						'other' => q({0}chop),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0}chop),
						'other' => q({0}chop),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0}pte),
						'other' => q({0}pte),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0}pte),
						'other' => q({0}pte),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0}pte imp),
						'other' => q({0}pte imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}pte imp),
						'other' => q({0}pte imp),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(c. à s.),
						'one' => q({0}c. à s.),
						'other' => q({0}c. à s.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(c. à s.),
						'one' => q({0}c. à s.),
						'other' => q({0}c. à s.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(c. à t.),
						'one' => q({0}c. à t.),
						'other' => q({0}c. à t.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(c. à t.),
						'one' => q({0}c. à t.),
						'other' => q({0}c. à t.),
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
					'acceleration-meter-per-square-second' => {
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} pi²),
						'other' => q({0} pi²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} pi²),
						'other' => q({0} pi²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0} po²),
						'other' => q({0} po²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0} po²),
						'other' => q({0} po²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(vg²),
						'one' => q({0} vg²),
						'other' => q({0} vg²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(vg²),
						'one' => q({0} vg²),
						'other' => q({0} vg²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q({0} item),
						'other' => q({0} items),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0} item),
						'other' => q({0} items),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(carats),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(carats),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(p.p. 10⁹),
						'one' => q({0} p.p. 10⁹),
						'other' => q({0} p.p. 10⁹),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(p.p. 10⁹),
						'one' => q({0} p.p. 10⁹),
						'other' => q({0} p.p. 10⁹),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E.),
						'north' => q({0} N.),
						'south' => q({0} S.),
						'west' => q({0} O.),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E.),
						'north' => q({0} N.),
						'south' => q({0} S.),
						'west' => q({0} O.),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} octet),
						'other' => q({0} octet),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} octet),
						'other' => q({0} octet),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0} Go),
						'other' => q({0} Go),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0} Go),
						'other' => q({0} Go),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0} ko),
						'other' => q({0} ko),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0} ko),
						'other' => q({0} ko),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0} Mo),
						'other' => q({0} Mo),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0} Mo),
						'other' => q({0} Mo),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0} To),
						'other' => q({0} To),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0} To),
						'other' => q({0} To),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} j),
						'other' => q({0} j),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} j),
						'other' => q({0} j),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} sem.),
						'other' => q({0} sem.),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} sem.),
						'other' => q({0} sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} an),
						'other' => q({0} ans),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} an),
						'other' => q({0} ans),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0} pt/cm),
						'other' => q({0} pt/cm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0} pt/cm),
						'other' => q({0} pt/cm),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} pi),
						'other' => q({0} pi),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} pi),
						'other' => q({0} pi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} po),
						'other' => q({0} po),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} po),
						'other' => q({0} po),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} al),
						'other' => q({0} al),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} al),
						'other' => q({0} al),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(vg),
						'one' => q({0} vg),
						'other' => q({0} vg),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(vg),
						'one' => q({0} vg),
						'other' => q({0} vg),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
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
					'mass-gram' => {
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tc),
						'one' => q({0} tc),
						'other' => q({0} tc),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tc),
						'one' => q({0} tc),
						'other' => q({0} tc),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} ch),
						'other' => q({0} ch),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} ch),
						'other' => q({0} ch),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(po Hg),
						'one' => q({0} po Hg),
						'other' => q({0} po Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(po Hg),
						'one' => q({0} po Hg),
						'other' => q({0} po Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbar),
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
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q({0} Bf),
						'other' => q({0} Bf),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q({0} Bf),
						'other' => q({0} Bf),
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
					'speed-meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lb-pi),
						'one' => q({0} lb-pi),
						'other' => q({0} lb-pi),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lb-pi),
						'one' => q({0} lb-pi),
						'other' => q({0} lb-pi),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q({0} pi³),
						'other' => q({0} pi³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0} pi³),
						'other' => q({0} pi³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0} po³),
						'other' => q({0} po³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0} po³),
						'other' => q({0} po³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q({0} m³),
						'other' => q({0} m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q({0} m³),
						'other' => q({0} m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(vg³),
						'one' => q({0} vg³),
						'other' => q({0} vg³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(vg³),
						'one' => q({0} vg³),
						'other' => q({0} vg³),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cuill. à d.),
						'one' => q({0} cuill. à d.),
						'other' => q({0} cuill. à d.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cuill. à d.),
						'one' => q({0} cuill. à d.),
						'other' => q({0} cuill. à d.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(cuill. à d. imp.),
						'one' => q({0} cuill. à d. imp.),
						'other' => q({0} cuill. à d. imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(cuill. à d. imp.),
						'one' => q({0} cuill. à d. imp.),
						'other' => q({0} cuill. à d. imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram liquide),
						'one' => q({0} dram liq),
						'other' => q({0} dram liq),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram liquide),
						'one' => q({0} dram liq),
						'other' => q({0} dram liq),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(goutte),
						'one' => q({0} goutte),
						'other' => q({0} gouttes),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(goutte),
						'one' => q({0} goutte),
						'other' => q({0} gouttes),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(oz liq.),
						'one' => q({0} oz liq.),
						'other' => q({0} oz liq.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(oz liq.),
						'one' => q({0} oz liq.),
						'other' => q({0} oz liq.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(oz liq imp.),
						'one' => q({0} oz liq imp.),
						'other' => q({0} oz liq imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(oz liq imp.),
						'one' => q({0} oz liq imp.),
						'other' => q({0} oz liq imp.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal Imp),
						'one' => q({0} gal Imp),
						'other' => q({0} gal Imp),
						'per' => q({0}/gal Imp),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal Imp),
						'one' => q({0} gal Imp),
						'other' => q({0} gal Imp),
						'per' => q({0}/gal Imp),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(gobelet doseur),
						'one' => q({0} gobelet doseur),
						'other' => q({0} gobelets doseurs),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(gobelet doseur),
						'one' => q({0} gobelet doseur),
						'other' => q({0} gobelets doseurs),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(chop),
						'one' => q({0} chop),
						'other' => q({0} chop),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(chop),
						'one' => q({0} chop),
						'other' => q({0} chop),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(pte),
						'one' => q({0} pte),
						'other' => q({0} pte),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(pte),
						'one' => q({0} pte),
						'other' => q({0} pte),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(pte imp),
						'one' => q({0} pte imp),
						'other' => q({0} pte imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(pte imp),
						'one' => q({0} pte imp),
						'other' => q({0} pte imp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(c. à t.),
						'one' => q({0} c. à t.),
						'other' => q({0} c. à t.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(c. à t.),
						'one' => q({0} c. à t.),
						'other' => q({0} c. à t.),
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
			'group' => q( ),
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
					'1' => '0 mille',
					'one' => '0 mille',
					'other' => '0 mille',
				},
				'10000' => {
					'one' => '00 mille',
					'other' => '00 mille',
				},
				'100000' => {
					'one' => '000 mille',
					'other' => '000 mille',
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
		'AFN' => {
			display_name => {
				'one' => q(afghani afghan),
				'other' => q(afghanis afghans),
			},
		},
		'ARS' => {
			symbol => 'ARS',
		},
		'AUD' => {
			symbol => '$ AU',
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azerbaïdjanais),
				'one' => q(manat azerbaïdjanais),
				'other' => q(manats azerbaïdjanais),
			},
		},
		'BMD' => {
			symbol => 'BMD',
		},
		'BND' => {
			symbol => 'BND',
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
		'CVE' => {
			display_name => {
				'currency' => q(escudo cap-verdien),
				'one' => q(escudo cap-verdien),
				'other' => q(escudos cap-verdiens),
			},
		},
		'FJD' => {
			symbol => 'FJD',
		},
		'FKP' => {
			symbol => 'FKP',
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
		'GYD' => {
			display_name => {
				'one' => q(dollar guyanien),
				'other' => q(dollars guyaniens),
			},
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
		'PEN' => {
			display_name => {
				'currency' => q(nouveau sol péruvien),
				'one' => q(nouveau sol péruvien),
				'other' => q(nouveaux sols péruviens),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina papou-néo-guinéen),
				'one' => q(kina papou-néo-guinéen),
				'other' => q(kinas papou-néo-guinéens),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(riyal du Qatar),
				'one' => q(riyal du Qatar),
				'other' => q(riyals du Qatar),
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
			display_name => {
				'currency' => q(dollar du Suriname),
				'one' => q(dollar du Suriname),
				'other' => q(dollars du Suriname),
			},
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
		'VUV' => {
			display_name => {
				'currency' => q(vatu),
				'one' => q(vatu),
				'other' => q(vatus),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(tala),
				'one' => q(tala),
				'other' => q(talas),
			},
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
					wide => {
						nonleap => [
							'tout',
							'bâbâ',
							'hâtour',
							'kyakh',
							'toubah',
							'amshîr',
							'barmahât',
							'barmoudah',
							'bashans',
							'ba’ounah',
							'abîb',
							'misra',
							'al-nasi'
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
				},
			},
			'ethiopic' => {
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
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'tis.',
							'hes.',
							'kis.',
							'téb.',
							'sché.',
							'ad.I',
							'adar',
							'nis.',
							'iyar',
							'siv.',
							'tam.',
							'av',
							'ell.'
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
				'stand-alone' => {
					narrow => {
						nonleap => [
							'T',
							'H',
							'K',
							'T',
							'S',
							'A',
							'A',
							'N',
							'I',
							'S',
							'T',
							'A',
							'E'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
					'afternoon1' => q{après-midi},
					'am' => q{a.m.},
					'evening1' => q{du soir},
					'midnight' => q{minuit},
					'morning1' => q{du mat.},
					'night1' => q{du mat.},
					'noon' => q{midi},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'afternoon1' => q{après-midi},
					'am' => q{a},
					'evening1' => q{du soir},
					'midnight' => q{minuit},
					'morning1' => q{mat.},
					'night1' => q{mat.},
					'noon' => q{midi},
					'pm' => q{p},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{après-midi},
					'evening1' => q{du soir},
					'morning1' => q{mat.},
					'night1' => q{du mat.},
				},
				'narrow' => {
					'afternoon1' => q{après-midi},
					'evening1' => q{du soir},
					'morning1' => q{mat.},
					'night1' => q{mat.},
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
		'buddhist' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
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
		'japanese' => {
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
			wide => {
				'0' => 'AP'
			},
		},
		'roc' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{yy-MM-dd GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{y-MM-dd},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{y-MM-dd GGGGG},
		},
		'japanese' => {
		},
		'persian' => {
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
		'buddhist' => {
		},
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
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
		'buddhist' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
		'buddhist' => {
			GyMd => q{y-MM-dd GGGGG},
		},
		'generic' => {
			Bh => q{h 'h' B},
			Bhm => q{h 'h' mm B},
			Bhms => q{h 'h' mm 'min' ss 's' B},
			EBhm => q{E h 'h' mm B},
			EBhms => q{E h 'h' mm 'min' ss 's' B},
			EHm => q{E HH 'h' mm},
			EHms => q{E HH 'h' mm 'min' ss 's'},
			Ehm => q{E h 'h' mm a},
			Ehms => q{E h 'h' mm 'min' ss 's' a},
			GyMd => q{y-MM-dd GGGGG},
			H => q{HH 'h'},
			Hm => q{HH 'h' mm},
			Hms => q{HH 'h' mm 'min' ss 's'},
			MEd => q{E M-d},
			MMd => q{MM-d},
			MMdd => q{MM-dd},
			Md => q{M-d},
			h => q{h 'h' a},
			hm => q{h 'h' mm a},
			hms => q{h 'h' mm 'min' ss 's' a},
			ms => q{mm 'min' ss 's'},
			yyyyM => q{y-MM G},
			yyyyMEd => q{E y-MM-dd G},
			yyyyMM => q{y-MM G},
			yyyyMd => q{y-MM-dd G},
		},
		'gregorian' => {
			Bh => q{h 'h' B},
			Bhm => q{h 'h' mm B},
			Bhms => q{h 'h' mm 'min' ss 's' B},
			EBhm => q{E h 'h' mm B},
			EBhms => q{E h 'h' mm 'min' ss 's' B},
			EHm => q{E HH 'h' mm},
			EHms => q{E HH 'h' mm 'min' ss 's'},
			Ehm => q{E h 'h' mm a},
			Ehms => q{E h 'h' mm 'min' ss 's' a},
			GyMd => q{y-MM-dd GGGGG},
			Hm => q{HH 'h' mm},
			Hms => q{HH 'h' mm 'min' ss 's'},
			Hmsv => q{HH 'h' mm 'min' ss 's' v},
			Hmv => q{HH 'h' mm v},
			MEd => q{E MM-dd},
			MMd => q{MM-dd},
			MMdd => q{MM-dd},
			Md => q{MM-dd},
			h => q{h 'h' a},
			hm => q{h 'h' mm a},
			hms => q{h 'h' mm 'min' ss 's' a},
			hmsv => q{h 'h' mm 'min' ss 's' a v},
			hmv => q{h 'h' mm a v},
			ms => q{mm 'min' ss 's'},
			yM => q{y-MM},
			yMEd => q{E y-MM-dd},
			yMM => q{y-MM},
			yMd => q{y-MM-dd},
		},
		'islamic' => {
			MEd => q{E d MMM},
			Md => q{MM-dd},
			yyyyM => q{y-MM GGGGG},
			yyyyMEd => q{E y-MM-dd GGGGG},
			yyyyMd => q{y-MM-dd GGGGG},
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
		'coptic' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
			},
		},
		'ethiopic' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
			},
		},
		'generic' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
				h => q{h – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
				h => q{h 'h' mm – h 'h' mm B},
				m => q{h 'h' mm – h 'h' mm B},
			},
			Gy => {
				G => q{y G – y G},
			},
			GyM => {
				G => q{y-MM GGGGG – y-MM GGGGG},
				M => q{y-MM – y-MM GGGGG},
				y => q{y-MM – y-MM GGGGG},
			},
			GyMEd => {
				G => q{E y-MM-dd GGGGG – E y-MM-dd GGGGG},
				M => q{E y-MM-dd GGGGG – E y-MM-dd GGGGG},
				d => q{E y-MM-dd – E y-MM-dd GGGGG},
				y => q{E y-MM-dd – E y-MM-dd GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM y – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{y-MM-dd GGGGG – y-MM-dd GGGGG},
				M => q{y-MM-dd – y-MM-dd GGGGG},
				d => q{y-MM-dd – y-MM-dd GGGGG},
				y => q{y-MM-dd – y-MM-dd GGGGG},
			},
			MEd => {
				M => q{E MM-dd – E MM-dd},
				d => q{E MM-dd – E MM-dd},
			},
			MMMEd => {
				d => q{E d – E d MMM},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			yM => {
				M => q{y-MM – y-MM G},
				y => q{y-MM – y-MM G},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd G},
				d => q{E y-MM-dd – E y-MM-dd G},
				y => q{E y-MM-dd – E y-MM-dd G},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd G},
				d => q{y-MM-dd – y-MM-dd G},
				y => q{y-MM-dd – y-MM-dd G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
				h => q{h – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
				h => q{h 'h' mm – h 'h' mm B},
				m => q{h 'h' mm – h 'h' mm B},
			},
			Gy => {
				G => q{y G – y G},
			},
			GyM => {
				G => q{y-MM GGGGG – y-MM GGGGG},
				M => q{y-MM – y-MM GGGGG},
				y => q{y-MM – y-MM GGGGG},
			},
			GyMEd => {
				G => q{E y-MM-dd GGGGG – E y-MM-dd GGGGG},
				M => q{E y-MM-dd – E y-MM-dd GGGGG},
				d => q{E y-MM-dd – E y-MM-dd GGGGG},
				y => q{E y-MM-dd – E y-MM-dd GGGGG},
			},
			GyMMM => {
				M => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				d => q{E d MMM – E d MMM y G},
			},
			GyMd => {
				G => q{y-MM-dd GGGGG – y-MM-dd GGGGG},
				M => q{y-MM-dd – y-MM-dd GGGGG},
				d => q{y-MM-dd – y-MM-dd GGGGG},
				y => q{y-MM-dd – y-MM-dd GGGGG},
			},
			H => {
				H => q{H 'h' – H 'h'},
			},
			Hm => {
				H => q{H 'h' mm – H 'h' mm},
				m => q{H 'h' mm – H 'h' mm},
			},
			Hmv => {
				H => q{H 'h' mm – H 'h' mm v},
				m => q{H 'h' mm – H 'h' mm v},
			},
			Hv => {
				H => q{H 'h' – H 'h' v},
			},
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{E MM-dd – E MM-dd},
				d => q{E MM-dd – E MM-dd},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				d => q{d – d MMM},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h 'h' a – h 'h' a},
				h => q{h 'h' – h 'h' a},
			},
			hm => {
				a => q{h 'h' mm a – h 'h' mm a},
				h => q{h 'h' mm – h 'h' mm a},
				m => q{h 'h' mm – h 'h' mm a},
			},
			hmv => {
				a => q{h 'h' mm a – h 'h' mm a v},
				h => q{h 'h' mm – h 'h' mm a v},
				m => q{h 'h' mm – h 'h' mm a v},
			},
			hv => {
				a => q{h 'h' a – h 'h' a v},
				h => q{h 'h' – h 'h' a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd},
				d => q{E y-MM-dd – E y-MM-dd},
				y => q{E y-MM-dd – E y-MM-dd},
			},
			yMMM => {
				M => q{MMM – MMM y},
			},
			yMMMEd => {
				d => q{E d MMM – E d MMM y},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'hebrew' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
			},
		},
		'indian' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
			},
		},
		'islamic' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
			},
		},
		'japanese' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
			},
		},
		'persian' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
			},
		},
		'roc' => {
			Bh => {
				B => q{h 'h' B – h 'h' B},
			},
			Bhm => {
				B => q{h 'h' mm B – h 'h' mm B},
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
			exemplarCity => q#New Salem [Dakota du Nord]#,
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
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
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
		'Asia/Dhaka' => {
			exemplarCity => q#Dacca#,
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
		'Brunei' => {
			long => {
				'standard' => q#heure du Brunéi#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#heure avancée du Cap-Vert#,
				'generic' => q#heure du Cap-Vert#,
				'standard' => q#heure normale du Cap-Vert#,
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
				'daylight' => q#heure avancée de l’Europe centrale#,
				'generic' => q#heure de l’Europe centrale#,
				'standard' => q#heure normale de l’Europe centrale#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#heure avancée de l’Europe de l’Est#,
				'generic' => q#heure de l’Europe de l’Est#,
				'standard' => q#heure normale de l’Europe de l’Est#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#heure avancée de l’Europe de l’Ouest#,
				'generic' => q#heure de l’Europe de l’Ouest#,
				'standard' => q#heure normale de l’Europe de l’Ouest#,
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
		'Indian_Ocean' => {
			long => {
				'standard' => q#heure de l’océan Indien#,
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
		'Niue' => {
			long => {
				'standard' => q#heure de Nioué#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#heure avancée de l’île Norfolk#,
				'generic' => q#heure de l’île Norfolk#,
				'standard' => q#heure normale de l’île Norfolk#,
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
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
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
