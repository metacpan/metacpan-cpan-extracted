=encoding utf8

=head1 NAME

Locale::CLDR::Locales::An - Package for language Aragonese

=cut

package Locale::CLDR::Locales::An;
# This file auto generated from Data\common\main\an.xml
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
				'an' => 'aragonés',
 				'ar' => 'arabe',
 				'ar_001' => 'arabe standard moderno',
 				'bn' => 'bengalí',
 				'de' => 'alemán',
 				'de_AT' => 'alemán austriaco',
 				'de_CH' => 'alemán standard suizo',
 				'en' => 'anglés',
 				'en_AU' => 'anglés australiano',
 				'en_CA' => 'anglés canadiense',
 				'en_GB' => 'anglés britanico',
 				'en_GB@alt=short' => 'anglés (RU)',
 				'en_US' => 'anglés americano',
 				'en_US@alt=short' => 'anglés (EUA)',
 				'es' => 'espanyol',
 				'es_419' => 'espanyol latino-americano',
 				'es_ES' => 'espanyol europeu',
 				'es_MX' => 'espanyol mexicano',
 				'fr' => 'francés',
 				'fr_CA' => 'francés canadiense',
 				'fr_CH' => 'francés suizo',
 				'hi' => 'hindi',
 				'id' => 'indonesio',
 				'it' => 'italiano',
 				'ja' => 'chaponés',
 				'ko' => 'coreano',
 				'nl' => 'neerlandés',
 				'nl_BE' => 'flamenco',
 				'pl' => 'polaco',
 				'pt' => 'portugués',
 				'pt_BR' => 'portugués brasilenyo',
 				'pt_PT' => 'portugués europeu',
 				'ru' => 'ruso',
 				'th' => 'tai',
 				'tr' => 'turco',
 				'und' => 'idioma desconoixiu',
 				'zh' => 'chino',
 				'zh@alt=menu' => 'chino mandarín',
 				'zh_Hans' => 'chino simplificau',
 				'zh_Hans@alt=long' => 'chino mandarín (simplificau)',
 				'zh_Hant' => 'chino tradicional',
 				'zh_Hant@alt=long' => 'chino mandarín (tradicional)',

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
			'Arab' => 'arabe',
 			'Cyrl' => 'cirilico',
 			'Hans' => 'simplificau',
 			'Hans@alt=stand-alone' => 'han simplificau',
 			'Hant' => 'tradicional',
 			'Hant@alt=stand-alone' => 'han tradicional',
 			'Jpan' => 'chaponés',
 			'Kore' => 'coreano',
 			'Latn' => 'latín',
 			'Zxxx' => 'sin escritura',
 			'Zzzz' => 'escritura desconoixida',

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
			'001' => 'Mundo',
 			'002' => 'Africa',
 			'003' => 'America d’o Norte',
 			'005' => 'Sudamerica',
 			'009' => 'Oceanía',
 			'011' => 'Africa occidental',
 			'013' => 'America Central',
 			'014' => 'Africa oriental',
 			'015' => 'Africa septentrional',
 			'017' => 'Africa central',
 			'018' => 'Africa meridional',
 			'019' => 'America',
 			'021' => 'Norteamerica',
 			'029' => 'Caribe',
 			'030' => 'Asia oriental',
 			'034' => 'Asia meridional',
 			'035' => 'Asia sudoriental',
 			'039' => 'Europa meridional',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Rechión d’a Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia central',
 			'145' => 'Asia occidental',
 			'150' => 'Europa',
 			'151' => 'Europa oriental',
 			'154' => 'Europa septentrional',
 			'155' => 'Europa occidental',
 			'202' => 'Africa subsahariana',
 			'419' => 'Latino-america',
 			'AC' => 'Isla Ascensión',
 			'AD' => 'Andorra',
 			'AE' => 'Emiratos Arabes Unius',
 			'AF' => 'Afganistán',
 			'AG' => 'Antigua y Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antartida',
 			'AR' => 'Archentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Islas Åland',
 			'AZ' => 'Azerbaichán',
 			'BA' => 'Bosnia y Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belchica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benín',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribe neerlandés',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhután',
 			'BV' => 'Isla Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarrusia',
 			'BZ' => 'Belize',
 			'CA' => 'Canadá',
 			'CC' => 'Islas Cocos',
 			'CD' => 'Republica Democratica d’o Congo',
 			'CD@alt=variant' => 'Congo Kinshasa',
 			'CF' => 'Republica Centro-africana',
 			'CG' => 'Republica d’o Congo',
 			'CG@alt=variant' => 'Congo Brazzaville',
 			'CH' => 'Suiza',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Costa de Vori',
 			'CK' => 'Islas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerún',
 			'CN' => '¨China',
 			'CO' => 'Colombia',
 			'CP' => 'Isla Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Isla Chirstmas',
 			'CY' => 'Chipre',
 			'CZ' => 'Chequia',
 			'CZ@alt=variant' => 'Republica checa',
 			'DE' => 'Alemanya',
 			'DG' => 'Diego García',
 			'DJ' => 'Chibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'Republica Dominicana',
 			'DZ' => 'Alcheria',
 			'EA' => 'Ceuta y Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Echipto',
 			'EH' => 'Sahara occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'Espanya',
 			'ET' => 'Ethiopia',
 			'EU' => 'Unión Europea',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fichi',
 			'FK' => 'Islas Malvinas',
 			'FK@alt=variant' => 'Islas Malvinas (Islas Falkland)',
 			'FM' => 'Micronesia',
 			'FO' => 'Islas Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabón',
 			'GB' => 'Reino Uniu',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Grenada',
 			'GE' => 'Cheorchia',
 			'GF' => 'Guayana francesa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Chibraltar',
 			'GL' => 'Gronlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinea equatorial',
 			'GR' => 'Grecia',
 			'GS' => 'Islas Cheorchia d’o Sud y Sandwich d’o Sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong, RAS China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Islas Heard y McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croacia',
 			'HT' => 'Haití',
 			'HU' => 'Hongría',
 			'IC' => 'Islas Canarias',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Isla de Man',
 			'IN' => 'India',
 			'IO' => 'Territorio Britanico de l’Oceano Indico',
 			'IQ' => 'Iraq',
 			'IR' => 'Irán',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Chamaica',
 			'JO' => 'Chordania',
 			'JP' => 'Chapón',
 			'KE' => 'Kenya',
 			'KG' => 'Kirguistán',
 			'KH' => 'Cambocha',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'Sant Cristofo y Nieus',
 			'KP' => 'Corea d’o Norte',
 			'KR' => 'Corea d’o Sud',
 			'KW' => 'Kuwait',
 			'KY' => 'Islas Caimán',
 			'KZ' => 'Cazaquistán',
 			'LA' => 'Laos',
 			'LB' => 'Libano',
 			'LC' => 'Santa Lucía',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburgo',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Marruecos',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'Sant Martín',
 			'MG' => 'Madagascar',
 			'MH' => 'Islas Marshall',
 			'MK' => 'Macedonia d’o norte',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau, RAS China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Islas Marianas d’o Norte',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricio',
 			'MV' => 'Maldivas',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malasia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nueva Caledonia',
 			'NE' => 'Nicher',
 			'NF' => 'Isla Norfolk',
 			'NG' => 'Nicheria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Países Baixos',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nueva Zelanda',
 			'OM' => 'Omán',
 			'PA' => 'Panamá',
 			'PE' => 'Perú',
 			'PF' => 'Polinesa Francesa',
 			'PG' => 'Papúa Nueva Guinea',
 			'PH' => 'Filipinas',
 			'PK' => 'Paquistán',
 			'PL' => 'Polonia',
 			'PM' => 'Saint-Pierre y Miquelon',
 			'PN' => 'Islas Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Territorios Palestinos',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Territorios aleixaus d’Oceanía',
 			'RE' => 'Isla d’a Reunión',
 			'RO' => 'Rumanía',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudí',
 			'SB' => 'Islas Salomón',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudán',
 			'SE' => 'Suecia',
 			'SG' => 'Singapur',
 			'SH' => 'Santa Helena',
 			'SI' => 'Eslovenia',
 			'SJ' => 'Svalbard y Jan Mayen',
 			'SK' => 'Eslovaquia',
 			'SL' => 'Sierra Leona',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudán d’o Sud',
 			'ST' => 'Sant Tomé y Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swazilandia',
 			'TA' => 'Tristán da Cunha',
 			'TC' => 'Islas Turcas y Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Territorios australs franceses',
 			'TG' => 'Togo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Tayikistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor Oriental',
 			'TM' => 'Turkmenistán',
 			'TN' => 'Tunicia',
 			'TO' => 'Tonga',
 			'TR' => 'Turquía',
 			'TT' => 'Trinidad y Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwán',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucrainia',
 			'UG' => 'Uganda',
 			'UM' => 'Islas perifericas d’os EUA',
 			'UN' => 'Nacions Unidas',
 			'US' => 'Estaus Unius',
 			'US@alt=short' => 'EUA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbequistán',
 			'VA' => 'Ciudat d’o Vaticano',
 			'VC' => 'Sant Vicent y las Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Islas Virchens Britanicas',
 			'VI' => 'Islas Virchens Norte-americanas',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis y Fortuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudoaccentos',
 			'XB' => 'Pseudobidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Republica de Sudafrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabue',
 			'ZZ' => 'Rechión desconoixida',

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
 				'gregorian' => q{calendario gregoriano},
 				'iso8601' => q{calendario ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{ordenación standard},
 			},
 			'numbers' => {
 				'latn' => q{dichitos occidentals},
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
			'metric' => q{metrico},
 			'UK' => q{RU},
 			'US' => q{EUA},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Idioma: {0}',
 			'script' => 'Escritura: {0}',
 			'region' => 'Rechión: {0}',

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
			auxiliary => qr{[· àâä ç èêë ìîï ñ òôö ùû]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aá b c d eé f g h ií j k l m n oó p q r s t uúü v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ¡ ? ¿ . … '‘’ "“” « » ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
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
	default		=> qq{”},
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
					'' => {
						'name' => q(punto cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto cardinal),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(minutos d’arco),
						'one' => q({0} minutos d’arco),
						'other' => q({0} minutos d’arco),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minutos d’arco),
						'one' => q({0} minutos d’arco),
						'other' => q({0} minutos d’arco),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(segundos d’arco),
						'one' => q({0} segundo d’arco),
						'other' => q({0} segundos d’arco),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(segundos d’arco),
						'one' => q({0} segundo d’arco),
						'other' => q({0} segundos d’arco),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(graus),
						'one' => q({0} grau),
						'other' => q({0} graus),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(graus),
						'one' => q({0} grau),
						'other' => q({0} graus),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radians),
						'one' => q({0} radián),
						'other' => q({0} radians),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radians),
						'one' => q({0} radián),
						'other' => q({0} radians),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(revolución),
						'one' => q({0} revolución),
						'other' => q({0} revolucions),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(revolución),
						'one' => q({0} revolución),
						'other' => q({0} revolucions),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(quiratz),
						'one' => q({0} quirat),
						'other' => q({0} quiratz),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(quiratz),
						'one' => q({0} quirat),
						'other' => q({0} quiratz),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(per cient),
						'one' => q({0} per cient),
						'other' => q({0} per cient),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(per cient),
						'one' => q({0} per cient),
						'other' => q({0} per cient),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(per mil),
						'one' => q({0} per mil),
						'other' => q({0} per mil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(per mil),
						'one' => q({0} per mil),
						'other' => q({0} per mil),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(per miriada),
						'one' => q({0} per miriada),
						'other' => q({0} per miriada),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(per miriada),
						'one' => q({0} per miriada),
						'other' => q({0} per miriada),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} este),
						'north' => q({0} norte),
						'south' => q({0} sud),
						'west' => q({0} ueste),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} este),
						'north' => q({0} norte),
						'south' => q({0} sud),
						'west' => q({0} ueste),
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
					'length-centimeter' => {
						'name' => q(centimetros),
						'one' => q({0} centimetro),
						'other' => q({0} centimetros),
						'per' => q({0} per centimetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimetros),
						'one' => q({0} centimetro),
						'other' => q({0} centimetros),
						'per' => q({0} per centimetro),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(quiratz),
						'one' => q({0} quirat),
						'other' => q({0} quiratz),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(quiratz),
						'one' => q({0} quirat),
						'other' => q({0} quiratz),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masas d’a Tierra),
						'one' => q({0} masa d’a Tierra),
						'other' => q({0} masas d’a Tierra),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masas d’a Tierra),
						'one' => q({0} masa d’a Tierra),
						'other' => q({0} masas d’a Tierra),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramos),
						'one' => q({0} gramo),
						'other' => q({0} gramos),
						'per' => q({0} per gramo),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramos),
						'one' => q({0} gramo),
						'other' => q({0} gramos),
						'per' => q({0} per gramo),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramos),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramos),
						'per' => q({0} per kilogramo),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramos),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramos),
						'per' => q({0} per kilogramo),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masas solars),
						'one' => q({0} masa solar),
						'other' => q({0} masas solars),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masas solars),
						'one' => q({0} masa solar),
						'other' => q({0} masas solars),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonas),
						'one' => q({0} tona),
						'other' => q({0} tonas),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonas),
						'one' => q({0} tona),
						'other' => q({0} tonas),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonas metricas),
						'one' => q({0} tona metrica),
						'other' => q({0} tonas metricas),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonas metricas),
						'one' => q({0} tona metrica),
						'other' => q({0} tonas metricas),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(caballos de vapor),
						'one' => q({0} caballo de vapor),
						'other' => q({0} caballos de vapor),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(caballos de vapor),
						'one' => q({0} caballo de vapor),
						'other' => q({0} caballos de vapor),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(graus Celsius),
						'one' => q({0} grau Celsius),
						'other' => q({0} graus Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(graus Celsius),
						'one' => q({0} grau Celsius),
						'other' => q({0} graus Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(graus Farenheit),
						'one' => q({0} grau Farenheit),
						'other' => q({0} graus Farenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(graus Farenheit),
						'one' => q({0} grau Farenheit),
						'other' => q({0} graus Farenheit),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(º),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(º),
					},
					# Long Unit Identifier
					'coordinate' => {
						'west' => q({0}U),
					},
					# Core Unit Identifier
					'coordinate' => {
						'west' => q({0}U),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tm),
						'one' => q({0} tm),
						'other' => q({0} tm),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tm),
						'one' => q({0} tm),
						'other' => q({0} tm),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:sí|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} y {1}),
				2 => q({0} y {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
		},
	} }
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '#,##0.00 ¤',
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
		'BRL' => {
			display_name => {
				'currency' => q(real brasilenyo),
				'one' => q(real brasilenyo),
				'other' => q(reals brasilenyos),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan chino),
				'one' => q(yuan chino),
				'other' => q(yuans chinos),
			},
		},
		'EUR' => {
			symbol => 'r',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(libra britanica),
				'one' => q(libra britanica),
				'other' => q(libras britanicas),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupia india),
				'one' => q(rupia india),
				'other' => q(rupias indias),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(yen chaponés),
				'one' => q(yen chaponés),
				'other' => q(yens chaponeses),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit de Malasia),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(piso filipino),
				'one' => q(piso filipino),
				'other' => q(pisos filipinos),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rublo ruso),
				'one' => q(rublo ruso),
				'other' => q(rublos rusos),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dólar de Singapur),
				'one' => q(dolar de Singapur),
				'other' => q(dolars de Singapur),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandés),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dolar d’os Estaus Unius),
				'one' => q(dolar d’os Estaus Unius),
				'other' => q(dolars d’os Estaus Unius),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(moneda desconoixida),
				'one' => q(\(moneda desconoixida\)),
				'other' => q(\(moneda desconoixida\)),
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
							'chi.',
							'feb.',
							'mar.',
							'abr.',
							'may.',
							'chn.',
							'chl.',
							'ago.',
							'set.',
							'oct.',
							'nov.',
							'avi.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'de chinero',
							'de febrero',
							'de marzo',
							'd’abril',
							'de mayo',
							'de chunyo',
							'de chuliol',
							'd’agosto',
							'de setiembre',
							'd’octubre',
							'de noviembre',
							'd’aviento'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'chinero',
							'febrero',
							'marzo',
							'abril',
							'mayo',
							'chunyo',
							'chuliol',
							'agosto',
							'setiembre',
							'octubre',
							'noviembre',
							'aviento'
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
						mon => 'lun',
						tue => 'mar',
						wed => 'mie',
						thu => 'chu',
						fri => 'vie',
						sat => 'sab',
						sun => 'dom'
					},
					wide => {
						mon => 'luns',
						tue => 'martz',
						wed => 'miercres',
						thu => 'chueves',
						fri => 'viernes',
						sat => 'sabado',
						sun => 'dominche'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'Ma',
						wed => 'Mi',
						thu => 'Ch',
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
					abbreviated => {0 => '1T',
						1 => '2T',
						2 => '3T',
						3 => '4T'
					},
					wide => {0 => '1r trimestre',
						1 => '2o trimestre',
						2 => '3r trimestre',
						3 => '4o trimestre'
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'a.C.',
				'1' => 'd.C.'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, d MMMM 'de' y G},
			'long' => q{d MMMM 'de' y G},
			'medium' => q{d MMM 'de' y G},
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM 'de' y},
			'long' => q{d MMMM 'de' y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
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
			'full' => q{H:mm:ss zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} 'a' 'las' {0}},
			'long' => q{{1} 'a' 'las' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'a' 'las' {0}},
			'long' => q{{1} 'a' 'las' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E, d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMW => q{'semana' W 'de' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ 'de' y},
			yQQQQ => q{QQQQ y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{LLL y G – LLL y G},
				M => q{LLL–LLL y G},
				y => q{LLL y – LLL y G},
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
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{LLL–LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E, d MMM y – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{LLL y G – LLL y G},
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
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
				d => q{d–d LLL y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/Y – E, d/M/Y},
			},
			yMMM => {
				M => q{LLL–LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM y – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
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
		regionFormat => q(Hora de {0}),
		regionFormat => q(Hora de verano de {0}),
		regionFormat => q(Hora standard de {0}),
		'America_Central' => {
			long => {
				'daylight' => q#hora de verano central d’America d’o Norte#,
				'generic' => q#hora central d’America d’o Norte#,
				'standard' => q#hora standard central d’America d’o Norte#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#hora de verano oriental d’America d’o Norte#,
				'generic' => q#hora oriental d’America d’o Norte#,
				'standard' => q#hora standard oriental d’America d’o Norte#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#hora de verano de montanya d’America d’o Norte#,
				'generic' => q#hora de montanya d’America d’o Norte#,
				'standard' => q#hora standard de montanya d’America d’o Norte#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#hora de verano d’o Pacifico d’America d’o Norte#,
				'generic' => q#hora d’o Pacifico d’America d’o Norte#,
				'standard' => q#hora standard d’o Pacifico d’America d’o Norte#,
			},
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#hora de verano de l’Atlantico#,
				'generic' => q#hora de l’Atlantico#,
				'standard' => q#hora standard de l’Atlantico#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#tiempo universal coordenado#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ciudat desconoixida#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#hora de verano d’o centro d’Europa#,
				'generic' => q#hora d’o centro d’Europa#,
				'standard' => q#hora standard d’o centro d’Europa#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#hora de verano de l’este d’Europa#,
				'generic' => q#hora de l’este d’Europa#,
				'standard' => q#hora standard de l’este d’Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#hora de verano de l’ueste d’Europa#,
				'generic' => q#hora de l’ueste d’Europa#,
				'standard' => q#hora standard de l’ueste d’Europa#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#hora d’o meridiano de Greenwich#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
