=encoding utf8

=head1 NAME

Locale::CLDR::Locales::La - Package for language Latin

=cut

package Locale::CLDR::Locales::La;
# This file auto generated from Data\common\main\la.xml
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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'Afarica',
 				'ab' => 'Abasca',
 				'ae' => 'Avestana',
 				'af' => 'Africana',
 				'am' => 'Amharica',
 				'an' => 'Aragonensis',
 				'ar' => 'Arabica',
 				'as' => 'Assamica',
 				'ay' => 'Aymara',
 				'az' => 'Atropatenica',
 				'be' => 'Ruthenica Alba',
 				'bg' => 'Bulgarica',
 				'bh' => 'Bihari',
 				'bn' => 'Bengalica',
 				'bo' => 'Tibetana',
 				'br' => 'Britonica',
 				'bs' => 'Bosnica',
 				'ca' => 'Catalana',
 				'ch' => 'Chamoruana',
 				'co' => 'Corsa',
 				'cs' => 'Bohemica',
 				'cu' => 'Slavonica antiqua',
 				'cu@alt=variant' => 'Slavica Ecclesiastica',
 				'cv' => 'Chuvassica',
 				'cy' => 'Cambrica',
 				'da' => 'Danica',
 				'de' => 'Germanica',
 				'dv' => 'Dhivehi',
 				'dz' => 'Dzongkha',
 				'el' => 'Graeca',
 				'el@alt=variant' => 'Neograeca',
 				'en' => 'Anglica',
 				'eo' => 'Esperantica',
 				'es' => 'Hispanica',
 				'et' => 'Estonica',
 				'eu' => 'Vasconica',
 				'fa' => 'Persica',
 				'fi' => 'Finnica',
 				'fo' => 'Faroensis',
 				'fr' => 'Francogallica',
 				'ga' => 'Hibernica',
 				'gd' => 'Scotica',
 				'gl' => 'Gallaica',
 				'gn' => 'Guaranica',
 				'gu' => 'Gujaratensis',
 				'gv' => 'Monensis',
 				'hi' => 'Hindica',
 				'hr' => 'Croatica',
 				'ht' => 'Creolus Haitianus',
 				'hu' => 'Hungarica',
 				'hy' => 'Armenica',
 				'ia' => 'Interlingua',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbonica',
 				'in' => 'Indonesia',
 				'is' => 'Islandica',
 				'it' => 'Italiana',
 				'iw' => 'Hebraica',
 				'ja' => 'Iaponica',
 				'ji' => 'Iudaeogermanica',
 				'jv' => 'Iavensis',
 				'ka' => 'Georgiana',
 				'kk' => 'Cazachica',
 				'kl' => 'Groenlandica',
 				'km' => 'Chmerica',
 				'kn' => 'Cannadica',
 				'ko' => 'Coreana',
 				'ks' => 'Casmirica',
 				'ku' => 'Curdica',
 				'kw' => 'Cornubica',
 				'ky' => 'Chirgisica',
 				'la' => 'Latina',
 				'lb' => 'Luxemburgica',
 				'li' => 'Limburgica',
 				'lt' => 'Lithuanica',
 				'lv' => 'Lettonica',
 				'mg' => 'Malagasiana',
 				'mi' => 'Maoriana',
 				'mk' => 'Macedonica',
 				'ml' => 'Malabarica',
 				'mn' => 'Mongolica',
 				'mr' => 'Marathica',
 				'ms' => 'Malayana',
 				'mt' => 'Melitensis',
 				'my' => 'Birmanica',
 				'ne' => 'Nepalensis',
 				'nl' => 'Batava',
 				'no' => 'Norvegica',
 				'oc' => 'Occitana',
 				'oj' => 'Ojibwayensis',
 				'or' => 'Orissensis',
 				'os' => 'Ossetica',
 				'pa' => 'Panjabica',
 				'pi' => 'Palica',
 				'pl' => 'Polonica',
 				'ps' => 'Afganica',
 				'pt' => 'Lusitana',
 				'qu' => 'Quechuae',
 				'rm' => 'Rhaetica',
 				'ro' => 'Dacoromanica',
 				'ru' => 'Russica',
 				'sa' => 'Sanscrita',
 				'sc' => 'Sarda',
 				'sd' => 'Sindhuica',
 				'se' => 'Samica septentrionalis',
 				'si' => 'Singhalensis',
 				'sk' => 'Slovaca',
 				'sl' => 'Slovena',
 				'sm' => 'Samoana',
 				'so' => 'Somalica',
 				'sq' => 'Albanica',
 				'sr' => 'Serbica',
 				'sv' => 'Suecica',
 				'sw' => 'Suahili',
 				'ta' => 'Tamulica',
 				'te' => 'Telingana',
 				'tg' => 'Tadzikica',
 				'th' => 'Thai',
 				'ti' => 'Tigrinya',
 				'tk' => 'Turcomannica',
 				'tl' => 'Tagalog',
 				'to' => 'Tongana',
 				'tr' => 'Turcica',
 				'tt' => 'Tatarica',
 				'uk' => 'Ucrainica',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbecica',
 				'vi' => 'Vietnamica',
 				'zh' => 'Sinica',
 				'zu' => 'Zuluana',

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
			'Arab' => 'Alphabetum Arabicum',
 			'Armn' => 'Alphabetum Armenium',
 			'Brai' => 'Scriptura Braille',
 			'Cyrl' => 'Alphabetum Cyrillicum',
 			'Grek' => 'Alphabetum Graecum',
 			'Hang' => 'Alphabetum Coreanum',
 			'Hani' => 'Scriptura Sinica',
 			'Hebr' => 'Alphabetum Hebraicum',
 			'Latn' => 'Alphabetum Latinum',
 			'Tibt' => 'Alphabetum Tibetanum',
 			'Xsux' => 'Scriptura cuneiformis',

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
			'001' => 'Mundus',
 			'002' => 'Africa',
 			'003' => 'America Septentrionalis',
 			'005' => 'America Australis',
 			'009' => 'Oceania',
 			'011' => 'Africa Occidentalis',
 			'013' => 'America Centralis',
 			'014' => 'Africa Orientalis',
 			'015' => 'Africa Septentrionalis',
 			'018' => 'Africa Australis (regio)',
 			'019' => 'America',
 			'029' => 'Caribaeum',
 			'030' => 'Asia Orientalis',
 			'035' => 'Asia Meridiorientalis',
 			'039' => 'Europa Centralis',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Micronesia (regio)',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Media Asia',
 			'150' => 'Europa',
 			'151' => 'Europa Orientalis',
 			'154' => 'Europa Septentrionalis',
 			'155' => 'Europa Occidentalis',
 			'AD' => 'Andorra',
 			'AE' => 'Phylarchiarum Arabicarum Confoederatio',
 			'AF' => 'Afgania',
 			'AG' => 'Antiqua et Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angolia',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Alandia',
 			'AZ' => 'Atropatene',
 			'BA' => 'Bosnia et Herzegovina',
 			'BB' => 'Barbata',
 			'BD' => 'Bangladesha',
 			'BE' => 'Belgica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Baharina',
 			'BI' => 'Burundia',
 			'BJ' => 'Beninum',
 			'BL' => 'Insula Sancti Bartholomaei',
 			'BM' => 'Bermuda',
 			'BN' => 'Bruneium',
 			'BO' => 'Bolivia',
 			'BR' => 'Brasilia',
 			'BS' => 'Insulae Bahamenses',
 			'BT' => 'Butania',
 			'BU' => 'Birmania',
 			'BV' => 'Insula Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Ruthenia Alba',
 			'BZ' => 'Beliza',
 			'CA' => 'Canada',
 			'CC' => 'Insulae Cocos seu Keeling',
 			'CD' => 'Res publica Democratica Congensis',
 			'CF' => 'Res publica Africae Mediae',
 			'CG' => 'Res publica Congoliae',
 			'CH' => 'Helvetia',
 			'CI' => 'Litus Eburneum',
 			'CK' => 'Insulae Cook',
 			'CL' => 'Chilia',
 			'CM' => 'Cameronia',
 			'CN' => 'Res publica popularis Sinarum',
 			'CO' => 'Columbia',
 			'CR' => 'Costarica',
 			'CU' => 'Cuba',
 			'CV' => 'Res publica Capitis Viridis',
 			'CW' => 'Insula Curacensis',
 			'CX' => 'Insula Christi Natalis',
 			'CY' => 'Cyprus',
 			'CZ' => 'Cechia',
 			'DD' => 'Res publica Democratica Germanica',
 			'DE' => 'Germania',
 			'DJ' => 'Gibutum',
 			'DK' => 'Dania',
 			'DM' => 'Dominica',
 			'DO' => 'Res publica Dominicana',
 			'DZ' => 'Algerium',
 			'EC' => 'Aequatoria',
 			'EE' => 'Estonia',
 			'EG' => 'Aegyptus',
 			'EH' => 'Sahara Occidentalis',
 			'ER' => 'Erythraea',
 			'ES' => 'Hispania',
 			'ET' => 'Aethiopia',
 			'FI' => 'Finnia',
 			'FJ' => 'Viti',
 			'FK' => 'Insulae Malvinae',
 			'FM' => 'Micronesia',
 			'FO' => 'Faeroae insulae',
 			'FR' => 'Francia',
 			'GA' => 'Gabonia',
 			'GB' => 'Britanniarum Regnum',
 			'GD' => 'Granata',
 			'GE' => 'Georgia',
 			'GF' => 'Guiana Francica',
 			'GG' => 'Lisia',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupa',
 			'GQ' => 'Guinea Aequatorensis',
 			'GR' => 'Graecia',
 			'GT' => 'Guatimalia',
 			'GU' => 'Guama',
 			'GW' => 'Guinea Bissaviensis',
 			'GY' => 'Guiana',
 			'HK' => 'Hongcongum',
 			'HN' => 'Honduria',
 			'HR' => 'Croatia',
 			'HT' => 'Haitia',
 			'HU' => 'Hungaria',
 			'ID' => 'Indonesia',
 			'IE' => 'Hibernia',
 			'IL' => 'Israël',
 			'IM' => 'Monapia',
 			'IN' => 'India',
 			'IQ' => 'Iracum',
 			'IR' => 'Irania',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Caesarea Insula',
 			'JM' => 'Iamaica',
 			'JO' => 'Iordania',
 			'JP' => 'Iaponia',
 			'KE' => 'Kenia',
 			'KG' => 'Chirgisia',
 			'KH' => 'Cambosia',
 			'KI' => 'Kiribati',
 			'KM' => 'Insulae Comorianae',
 			'KN' => 'Sanctus Christophorus et Nevis',
 			'KP' => 'Res publica Popularis Democratica Coreana',
 			'KR' => 'Res publica Coreana',
 			'KW' => 'Cuvaitum',
 			'KY' => 'Insulae Caimanenses',
 			'KZ' => 'Kazachstania',
 			'LA' => 'Laotia',
 			'LB' => 'Libanus',
 			'LC' => 'Sancta Lucia',
 			'LI' => 'Lichtenstenum',
 			'LK' => 'Taprobane',
 			'LR' => 'Liberia',
 			'LS' => 'Lesothum',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburgum',
 			'LV' => 'Lettonia',
 			'LY' => 'Libya',
 			'MA' => 'Marocum',
 			'MC' => 'Monoecus',
 			'MD' => 'Res publica Moldavica',
 			'ME' => 'Mons Niger',
 			'MG' => 'Madagascaria',
 			'MH' => 'Insulae Marsalienses',
 			'MK' => 'Res publica Macedonica',
 			'ML' => 'Malium',
 			'MN' => 'Mongolia',
 			'MO' => 'Macaum',
 			'MP' => 'Insulae Marianae Septentrionales',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Melita',
 			'MU' => 'Mauritia',
 			'MV' => 'Insulae Maldivae',
 			'MW' => 'Malavium',
 			'MX' => 'Mexicum',
 			'MY' => 'Malaesia',
 			'MZ' => 'Mozambicum',
 			'NA' => 'Namibia',
 			'NC' => 'Nova Caledonia',
 			'NE' => 'Res publica Nigritana',
 			'NF' => 'Insula Norfolcia',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederlandia',
 			'NL@alt=variant' => 'Regnum Nederlandiae',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepalia',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelandia',
 			'OM' => 'Omania',
 			'PA' => 'Panama',
 			'PE' => 'Peruvia',
 			'PF' => 'Polynesia Francica',
 			'PG' => 'Papua Nova Guinea',
 			'PH' => 'Philippinae',
 			'PK' => 'Pakistania',
 			'PL' => 'Polonia',
 			'PM' => 'Insulae Sancti Petri et Miquelonensis',
 			'PN' => 'Insulae Pitcairn',
 			'PR' => 'Portus Dives',
 			'PS' => 'Territoria Palaestinensia',
 			'PT' => 'Portugallia',
 			'PW' => 'Belavia',
 			'PY' => 'Paraquaria',
 			'QA' => 'Quataria',
 			'RE' => 'Reunio',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudiana',
 			'SB' => 'Insulae Salomonis',
 			'SC' => 'Insulae Seisellenses',
 			'SD' => 'Sudania',
 			'SE' => 'Suecia',
 			'SG' => 'Singapura',
 			'SH' => 'Sancta Helena, Ascensio et Tristan da Cunha',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovacia',
 			'SL' => 'Mons Leoninus',
 			'SM' => 'Res publica Sancti Marini',
 			'SN' => 'Senegalia',
 			'SO' => 'Somalia',
 			'SR' => 'Surinamia',
 			'SS' => 'Sudania Australis',
 			'ST' => 'Insulae Sancti Thomae et Principis',
 			'SV' => 'Salvatoria',
 			'SY' => 'Syria',
 			'SZ' => 'Swazia',
 			'TC' => 'Insulae Turcenses et Caicenses',
 			'TD' => 'Tzadia',
 			'TG' => 'Togum',
 			'TH' => 'Thailandia',
 			'TJ' => 'Tadzikistania',
 			'TK' => 'Tokelau',
 			'TL' => 'Timoria Orientalis',
 			'TM' => 'Turcomannia',
 			'TN' => 'Tunesia',
 			'TO' => 'Tonga',
 			'TR' => 'Turcia',
 			'TT' => 'Trinitas et Tabacum',
 			'TV' => 'Tuvalu',
 			'TW' => 'Res publica Sinarum',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganda',
 			'US' => 'Civitates Foederatae Americae',
 			'UY' => 'Uraquaria',
 			'UZ' => 'Uzbecia',
 			'VA' => 'Civitas Vaticana',
 			'VC' => 'Sanctus Vincentius et Granatinae',
 			'VE' => 'Venetiola',
 			'VG' => 'Virginis Insulae Britannicae',
 			'VI' => 'Virginis Insulae Americanae',
 			'VN' => 'Vietnamia',
 			'VU' => 'Vanuatu',
 			'WF' => 'Vallis et Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovia',
 			'YE' => 'Iemenia',
 			'YT' => 'Maiotta',
 			'YU' => 'Iugoslavia',
 			'ZA' => 'Africa Australis',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabua',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ita|i|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:non|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} et {1}),
				2 => q({0} et {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
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
					'one' => '0 mille',
					'other' => '0 millia',
				},
				'10000' => {
					'one' => '00 millia',
					'other' => '00 millia',
				},
				'100000' => {
					'one' => '000 millia',
					'other' => '000 millia',
				},
				'1000000' => {
					'one' => '0 milio',
					'other' => '0 miliones',
				},
				'10000000' => {
					'one' => '00 miliones',
					'other' => '00 miliones',
				},
				'100000000' => {
					'one' => '000 miliones',
					'other' => '000 miliones',
				},
				'1000000000' => {
					'one' => '0 miliardum',
					'other' => '0 miliarda',
				},
				'10000000000' => {
					'one' => '00 miliarda',
					'other' => '00 miliarda',
				},
				'100000000000' => {
					'one' => '000 miliarda',
					'other' => '000 miliarda',
				},
				'1000000000000' => {
					'one' => '0 milies miliardum',
					'other' => '0 milies miliarda',
				},
				'10000000000000' => {
					'one' => '00 milies miliarda',
					'other' => '00 milies miliarda',
				},
				'100000000000000' => {
					'one' => '000 milies miliarda',
					'other' => '000 milies miliarda',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000' => {
					'one' => '0 Mn',
					'other' => '0 Mn',
				},
				'10000000' => {
					'one' => '00 Mn',
					'other' => '00 Mn',
				},
				'100000000' => {
					'one' => '000 Mn',
					'other' => '000 Mn',
				},
				'1000000000' => {
					'one' => '0 Md',
					'other' => '0 Md',
				},
				'10000000000' => {
					'one' => '00 Md',
					'other' => '00 Md',
				},
				'100000000000' => {
					'one' => '000 Md',
					'other' => '000 Md',
				},
				'1000000000000' => {
					'one' => '0 mil Md',
					'other' => '0 mil Md',
				},
				'10000000000000' => {
					'one' => '00 mil Md',
					'other' => '00 mil Md',
				},
				'100000000000000' => {
					'one' => '000 mil Md',
					'other' => '000 mil Md',
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
		'CHF' => {
			display_name => {
				'currency' => q(Francus Helveticus),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Marca Finniae),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Libra sterlingorum),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Drachma),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dollarium Hongkongense),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Lira Italiana),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Pensum Mexicanum),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Corona Norvegiae),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Nuevo Sol),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Rubelus Russicus),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dollarium Civitatum Foederatarum),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Argentum),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Aurum),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platinum),
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
							'Ian',
							'Feb',
							'Mar',
							'Apr',
							'Mai',
							'Iun',
							'Iul',
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
							'Ianuarii',
							'Februarii',
							'Martii',
							'Aprilis',
							'Maii',
							'Iunii',
							'Iulii',
							'Augusti',
							'Septembris',
							'Octobris',
							'Novembris',
							'Decembris'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'Ianuarius',
							'Februarius',
							'Martius',
							'Aprilis',
							'Maius',
							'Iunius',
							'Iulius',
							'Augustus',
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
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Mer',
						thu => 'Iov',
						fri => 'Ven',
						sat => 'Sab',
						sun => 'Dom'
					},
					wide => {
						mon => 'dies Lunae',
						tue => 'dies Martis',
						wed => 'dies Mercurii',
						thu => 'dies Iovis',
						fri => 'dies Veneris',
						sat => 'dies Sabbati',
						sun => 'Dominica'
					},
				},
				'stand-alone' => {
					wide => {
						sat => 'Sabbatum',
						sun => 'Dominica'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => 'prima quarta',
						1 => 'secunda quarta',
						2 => 'tertia quarta',
						3 => 'quarta quarta'
					},
				},
			},
	} },
);

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
			},
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			abbreviated => {
				'0' => 'a.C.n.',
				'1' => 'p.C.n.'
			},
			wide => {
				'0' => 'ante Christum natum',
				'1' => 'post Christum natum'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{EEEE, 'die' d MMMM y G},
			'long' => q{'die' d MMMM y G},
			'medium' => q{'die' d MMM y G},
			'short' => q{d M y G},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{{1} 'de' {0}},
			'long' => q{{1} 'de' {0}},
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
	} },
);

no Moo;

1;

# vim: tabstop=4
