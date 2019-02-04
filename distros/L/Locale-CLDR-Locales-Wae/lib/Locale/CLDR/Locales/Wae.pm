=encoding utf8

=head1

Locale::CLDR::Locales::Wae - Package for language Walser

=cut

package Locale::CLDR::Locales::Wae;
# This file auto generated from Data\common\main\wae.xml
#	on Sun  3 Feb  2:26:09 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
				'ab' => 'Abčasiš',
 				'af' => 'Afrikáns',
 				'am' => 'Amhariš',
 				'ar' => 'Arabiš',
 				'as' => 'Assamesiš',
 				'ay' => 'Aymara',
 				'az' => 'Serbaidšaniš',
 				'be' => 'Wísrussiš',
 				'bg' => 'Bulgariš',
 				'bn' => 'Bengališ',
 				'bo' => 'Tibetiš',
 				'bs' => 'Bosniš',
 				'ca' => 'Katalaniš',
 				'cs' => 'Tšečiš',
 				'cy' => 'Walisiš',
 				'da' => 'Däniš',
 				'de' => 'Titš',
 				'de_AT' => 'Öštričišes Titš',
 				'de_CH' => 'Schwizer Hočtitš',
 				'dv' => 'Malediwiš',
 				'dz' => 'Butaniš',
 				'efi' => 'Efik',
 				'el' => 'Gričiš',
 				'en' => 'Engliš',
 				'en_AU' => 'Auštrališes Engliš',
 				'en_CA' => 'Kanadišes Engliš',
 				'en_GB' => 'Britišes Engliš',
 				'en_US' => 'Amerikanišes Engliš',
 				'es' => 'Schpaniš',
 				'es_419' => 'Latiamerikanišes Schpaniš',
 				'es_ES' => 'Iberišes Schpaniš',
 				'et' => 'Estniš',
 				'eu' => 'Baskiš',
 				'fa' => 'Persiš',
 				'fi' => 'Finiš',
 				'fil' => 'Filipiniš',
 				'fj' => 'Fidšianiš',
 				'fr' => 'Wälš',
 				'fr_CA' => 'Kanadišes Wälš',
 				'fr_CH' => 'Schwizer Wälš',
 				'ga' => 'Iriš',
 				'gl' => 'Galiziš',
 				'gn' => 'Guarani',
 				'gu' => 'Gujarati',
 				'ha' => 'Hausa',
 				'haw' => 'Hawaíaniš',
 				'he' => 'Hebräiš',
 				'hi' => 'Hindi',
 				'hr' => 'Kroatiš',
 				'ht' => 'Haitianiš',
 				'hu' => 'Ungariš',
 				'hy' => 'Armeniš',
 				'id' => 'Indonesiš',
 				'ig' => 'Igbo',
 				'is' => 'Iisländiš',
 				'it' => 'Italieniš',
 				'ja' => 'Japaniš',
 				'ka' => 'Georgiš',
 				'kk' => 'Kazačiš',
 				'km' => 'Kambodšaniš',
 				'kn' => 'Kannada',
 				'ko' => 'Koreaniš',
 				'ks' => 'Kašmiriš',
 				'ku' => 'Kurdiš',
 				'ky' => 'Kirgisiš',
 				'la' => 'Latiniš',
 				'lb' => 'Luxemburgiš',
 				'ln' => 'Lingala',
 				'lo' => 'Laotiš',
 				'lt' => 'Litauiš',
 				'lv' => 'Lettiš',
 				'mg' => 'Malagási',
 				'mi' => 'Maori',
 				'mk' => 'Mazedoniš',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongoliš',
 				'mr' => 'Marathi',
 				'ms' => 'Malaíš',
 				'mt' => 'Maltesiš',
 				'my' => 'Burmesiš',
 				'nb' => 'Norwegiš Bokmål',
 				'nd' => 'Nordndebele',
 				'ne' => 'Nepalesiš',
 				'nl' => 'Holändiš',
 				'nl_BE' => 'Flämiš',
 				'nn' => 'Norwegiš Nynorsk',
 				'nso' => 'Nordsotho',
 				'ny' => 'Nyanja',
 				'or' => 'Oriya',
 				'os' => 'Osétiš',
 				'pa' => 'Pandšabiš',
 				'pl' => 'Polniš',
 				'ps' => 'Paštu',
 				'pt' => 'Portugisiš',
 				'pt_BR' => 'Brasilianišes Portugisiš',
 				'pt_PT' => 'Iberišes Portugisiš',
 				'qu' => 'Quečua',
 				'rm' => 'Rätromaniš',
 				'rn' => 'Rundi',
 				'ro' => 'Rumäniš',
 				'ru' => 'Rusiš',
 				'rw' => 'Ruandiš',
 				'sa' => 'Sanskrit',
 				'sah' => 'Jakutiš',
 				'sd' => 'Sindhi',
 				'se' => 'Nordsamiš',
 				'sg' => 'Sango',
 				'si' => 'Singalesiš',
 				'sk' => 'Slowakiš',
 				'sl' => 'Sloweniš',
 				'sm' => 'Samoaniš',
 				'sn' => 'Shona',
 				'so' => 'Somališ',
 				'sq' => 'Albaniš',
 				'sr' => 'Serbiš',
 				'ss' => 'Swazi',
 				'st' => 'Südsotho',
 				'su' => 'Sundanesiš',
 				'sv' => 'Schwediš',
 				'sw' => 'Suaheliš',
 				'ta' => 'Tamiliš',
 				'te' => 'Telugu',
 				'tet' => 'Tetum',
 				'tg' => 'Tadšikiš',
 				'th' => 'Thailändiš',
 				'ti' => 'Tigrinja',
 				'tk' => 'Turkmeniš',
 				'tn' => 'Tswana',
 				'to' => 'Tonga',
 				'tpi' => 'Niwmelanesiš',
 				'tr' => 'Türkiš',
 				'ts' => 'Tsonga',
 				'ty' => 'Taitiš',
 				'ug' => 'Uiguriš',
 				'uk' => 'Ukrainiš',
 				'und' => 'Unbekannti Schprač',
 				'ur' => 'Urdu',
 				'uz' => 'Usbekiš',
 				've' => 'Venda',
 				'vi' => 'Vietnamesiš',
 				'wae' => 'Walser',
 				'wo' => 'Wolof',
 				'xh' => 'Xhosa',
 				'yo' => 'Yoruba',
 				'zh' => 'Chinesiš',
 				'zh_Hans' => 'Vereifačts Chinesiš',
 				'zh_Hant' => 'Traditionells Chinesiš',
 				'zu' => 'Zulu',

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
			'Arab' => 'Arabiš',
 			'Armn' => 'Armeniš',
 			'Beng' => 'Bengališ',
 			'Cyrl' => 'Kirilliš',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Ethiopiš',
 			'Geor' => 'Georgiš',
 			'Grek' => 'Gričiš',
 			'Gujr' => 'Gujarati',
 			'Hans' => 'Vereifačt',
 			'Hant' => 'Traditionell',
 			'Hebr' => 'Hebräiš',
 			'Jpan' => 'Japaniš',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korianiš',
 			'Laoo' => 'Laotiš',
 			'Latn' => 'Latiniš',
 			'Mlym' => 'Malaisiš',
 			'Mymr' => 'Burmesiš',
 			'Orya' => 'Oriya',
 			'Sinh' => 'Singalesiš',
 			'Taml' => 'Tamiliš',
 			'Telu' => 'Telugu',
 			'Thaa' => 'Thána',
 			'Thai' => 'Thai',
 			'Zxxx' => 'Schriftlos',
 			'Zzzz' => 'Unkodierti Schrift',

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
			'001' => 'Wäld',
 			'002' => 'Afrika',
 			'003' => 'Nordamerika',
 			'005' => 'Südamerika',
 			'009' => 'Ozeanie',
 			'011' => 'Weštafrika',
 			'013' => 'Zentralamerika',
 			'014' => 'Oštafrika',
 			'015' => 'Nordafrika',
 			'017' => 'Mittelafrika',
 			'018' => 'Südličs Afrika',
 			'019' => 'Amerikaniš Kontinänt',
 			'021' => 'Nördličs Amerika',
 			'029' => 'Karibik',
 			'030' => 'Oštasie',
 			'034' => 'Südasie',
 			'035' => 'Südoštasie',
 			'039' => 'Südeuropa',
 			'053' => 'Auštralie und Niwséland',
 			'054' => 'Melanesie',
 			'057' => 'Mikronesišes Inselgebiet',
 			'061' => 'Polinesie',
 			'142' => 'Asie',
 			'143' => 'Zentralasie',
 			'145' => 'Weštasie',
 			'150' => 'Europa',
 			'151' => 'Ošteuropa',
 			'154' => 'Nordeuropa',
 			'155' => 'Wešteuropa',
 			'419' => 'Latíamerika',
 			'AC' => 'Himmelfártsinsla',
 			'AD' => 'Andorra',
 			'AE' => 'Vereinigti Arabiše Emirat',
 			'AF' => 'Afganištan',
 			'AG' => 'Antigua und Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanie',
 			'AM' => 'Armenie',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentinie',
 			'AS' => 'Amerikaniš Samoa',
 			'AT' => 'Öštrič',
 			'AU' => 'Australie',
 			'AW' => 'Aruba',
 			'AX' => 'Alandinslä',
 			'AZ' => 'Aserbaidšan',
 			'BA' => 'Bosnie und Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeš',
 			'BE' => 'Belgie',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarie',
 			'BH' => 'Bačrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Bartholomäus-Insla',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Boliwie',
 			'BR' => 'Brasilie',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetinsla',
 			'BW' => 'Botswana',
 			'BY' => 'Wísrussland',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosinslä',
 			'CD' => 'Kongo-Kinshasa',
 			'CD@alt=variant' => 'Kongo (Demokratiši Rebublik)',
 			'CF' => 'Zentralafrikaniši Rebublik',
 			'CG' => 'Kongo Brazzaville',
 			'CG@alt=variant' => 'Kongo (Rebublik)',
 			'CH' => 'Schwiz',
 			'CI' => 'Elfebeiküšta',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Cookinslä',
 			'CL' => 'Tšile',
 			'CM' => 'Kamerun',
 			'CN' => 'China',
 			'CO' => 'Kolumbie',
 			'CP' => 'Clipperton Insla',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CX' => 'Wienäčtsinslä',
 			'CY' => 'Zypre',
 			'CZ' => 'Tšečie',
 			'DE' => 'Titšland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Dšibuti',
 			'DK' => 'Dänemark',
 			'DM' => 'Doninica',
 			'DO' => 'Dominikaniši Rebublik',
 			'DZ' => 'Algerie',
 			'EA' => 'Ceuta und Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Eštland',
 			'EG' => 'Egypte',
 			'EH' => 'Weštsahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Schpanie',
 			'ET' => 'Ethiopie',
 			'EU' => 'Europäiši Unio',
 			'FI' => 'Finnland',
 			'FJ' => 'Fidši',
 			'FK' => 'Falklandinslä',
 			'FK@alt=variant' => 'Falklandinslä (Malwine)',
 			'FM' => 'Mikronesie',
 			'FO' => 'Färöe',
 			'FR' => 'Frankrič',
 			'GA' => 'Gabon',
 			'GB' => 'England',
 			'GD' => 'Grenada',
 			'GE' => 'Georgie',
 			'GF' => 'Französiš Guiana',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönland',
 			'GM' => 'Gambia',
 			'GN' => 'Ginea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorialginea',
 			'GR' => 'Gričeland',
 			'GS' => 'Südgeorgie und d’südliče Senwičinslä',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Ginea Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Sonderverwaltigszona Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard- und McDonald-Inslä',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatie',
 			'HT' => 'Haiti',
 			'HU' => 'Ungare',
 			'IC' => 'Kanariše Inslä',
 			'ID' => 'Indonesie',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'Indie',
 			'IO' => 'Britišes Territorium em indiše Ozean',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italie',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordanie',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgištan',
 			'KH' => 'Kambodša',
 			'KI' => 'Kiribati',
 			'KM' => 'Komore',
 			'KN' => 'St. Kitts und Nevis',
 			'KP' => 'Nordkorea',
 			'KR' => 'Südkorea',
 			'KW' => 'Kuweit',
 			'KY' => 'Kaimaninslä',
 			'KZ' => 'Kasačstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liečteštei',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litaue',
 			'LU' => 'Luxeburg',
 			'LV' => 'Lettland',
 			'LY' => 'Lübie',
 			'MA' => 'Maroko',
 			'MC' => 'Monago',
 			'MD' => 'Moldau',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Maršalinslä',
 			'MK' => 'Mazedonie',
 			'MK@alt=variant' => 'Mazedonie (EJR)',
 			'ML' => 'Mali',
 			'MM' => 'Burma',
 			'MN' => 'Mongolei',
 			'MO' => 'Sonderverwaltigszona Makau',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Nördliči Mariane',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretanie',
 			'MS' => 'Monserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediwe',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Niwkaledonie',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkinsla',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Holand',
 			'NO' => 'Norwäge',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Niwséland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Französiš Polinesie',
 			'PG' => 'Papua Niwginea',
 			'PH' => 'Philippine',
 			'PK' => 'Pakištan',
 			'PL' => 'Pole',
 			'PM' => 'St. Pierre und Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Paleština',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Katar',
 			'QO' => 'Üssers Ozeanie',
 			'RE' => 'Réunion',
 			'RO' => 'Rumänie',
 			'RS' => 'Serbie',
 			'RU' => 'Russland',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi Arabie',
 			'SB' => 'Salomone',
 			'SC' => 'Sečelle',
 			'SD' => 'Sudan',
 			'SE' => 'Schwede',
 			'SG' => 'Singapur',
 			'SH' => 'St. Helena',
 			'SI' => 'Slowenie',
 			'SJ' => 'Svalbard und Jan Mayen',
 			'SK' => 'Slowakei',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'ST' => 'São Tomé and Príncipe',
 			'SV' => 'El Salvador',
 			'SY' => 'Sürie',
 			'SZ' => 'Swasiland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- und Caicosinslä',
 			'TD' => 'Tšad',
 			'TF' => 'Französiši Süd- und Antarktisgebiet',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadšikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Ošttimor',
 			'TL@alt=variant' => 'Wešttimor',
 			'TM' => 'Turkmeništan',
 			'TN' => 'Tunesie',
 			'TO' => 'Tonga',
 			'TR' => 'Türkei',
 			'TT' => 'Trinidad und Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'Amerikaniš Ozeanie',
 			'US' => 'Amerika',
 			'UY' => 'Urugauy',
 			'UZ' => 'Usbekištan',
 			'VA' => 'Vatikan',
 			'VC' => 'St. Vincent und d’Grenadine',
 			'VE' => 'Venezuela',
 			'VG' => 'Britiši Jungfröiwinslä',
 			'VI' => 'Amerikaniši Jungfröiwinslä',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis und Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Jéme',
 			'YT' => 'Moyette',
 			'ZA' => 'Südafrika',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Unbekannti Regio',

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
 				'gregorian' => q{Gregorianišä Kaländer},
 			},
 			'collation' => {
 				'ducet' => q{Standard Unicode Sortierreiefolg},
 				'search' => q{Allgmeini Süeč},
 			},
 			'numbers' => {
 				'latn' => q{Arabiši Zálä},
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
			'metric' => q{Metriš},
 			'UK' => q{Angelsä},
 			'US' => q{Angloamerikaniš},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Sprač: {0}',
 			'script' => 'Alfabét: {0}',
 			'region' => 'Regio: {0}',

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
			auxiliary => qr{[à ă â å ā æ ç è ĕ ê ë ē ì ĭ î ï ī ñ ò ŏ ô ø ō œ ß ù ŭ û ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á ä ã b c č d e é f g h i í j k l m n o ó ö õ p q r s š t u ú ü ũ v w x y z]},
			numbers => qr{[\- , ’ % ‰ + 0 1 2 3 4 5 6 7 8 9]},
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
	default		=> qq{‹},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{›},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(täg),
						'one' => q({0} täg),
						'other' => q({0} täg),
					},
					'hour' => {
						'name' => q(stunde),
						'one' => q({0} stund),
						'other' => q({0} stunde),
					},
					'minute' => {
						'name' => q(minüte),
						'one' => q({0} minüta),
						'other' => q({0} minüte),
					},
					'month' => {
						'name' => q(mánet),
						'one' => q({0} mánet),
						'other' => q({0} mánet),
					},
					'second' => {
						'name' => q(sekunde),
						'one' => q({0} sekund),
						'other' => q({0} sekunde),
					},
					'week' => {
						'name' => q(wučä),
						'one' => q({0} wuča),
						'other' => q({0} wučä),
					},
					'year' => {
						'name' => q(jár),
						'one' => q({0} jár),
						'other' => q({0} jár),
					},
				},
				'short' => {
					'day' => {
						'name' => q(täg),
					},
					'hour' => {
						'name' => q(stunde),
					},
					'minute' => {
						'name' => q(minüte),
					},
					'month' => {
						'name' => q(mánet),
					},
					'second' => {
						'name' => q(sekunde),
					},
					'week' => {
						'name' => q(wučä),
					},
					'year' => {
						'name' => q(jár),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nei|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} und {1}),
				2 => q({0} und {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(’),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(Brasilianiši Real),
				'one' => q(Brasilianišä Real),
				'other' => q(Brasilianiši Real),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinesiši Yuan),
				'one' => q(Chinesišä Yuan),
				'other' => q(Chinesiši Yuan),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(Euro),
				'other' => q(Euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pfund),
				'one' => q(Pfund),
				'other' => q(Pfund),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indiši Rupie),
				'one' => q(Indišä Rupie),
				'other' => q(Indiši Rupie),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen),
				'one' => q(Yen),
				'other' => q(Yen),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubel),
				'one' => q(Rubel),
				'other' => q(Rubel),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dollar),
				'one' => q(Dollar),
				'other' => q(Dollar),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Unbekannti Wãrig),
				'one' => q(Unbekannti Wãrig),
				'other' => q(Unbekannti Wãrig),
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
							'Jen',
							'Hor',
							'Mär',
							'Abr',
							'Mei',
							'Brá',
							'Hei',
							'Öig',
							'Her',
							'Wím',
							'Win',
							'Chr'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'H',
							'M',
							'A',
							'M',
							'B',
							'H',
							'Ö',
							'H',
							'W',
							'W',
							'C'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jenner',
							'Hornig',
							'Märze',
							'Abrille',
							'Meije',
							'Bráčet',
							'Heiwet',
							'Öigšte',
							'Herbštmánet',
							'Wímánet',
							'Wintermánet',
							'Chrištmánet'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jen',
							'Hor',
							'Mär',
							'Abr',
							'Mei',
							'Brá',
							'Hei',
							'Öig',
							'Her',
							'Wím',
							'Win',
							'Chr'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'H',
							'M',
							'A',
							'M',
							'B',
							'H',
							'Ö',
							'H',
							'W',
							'W',
							'C'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jenner',
							'Hornig',
							'Märze',
							'Abrille',
							'Meije',
							'Bráčet',
							'Heiwet',
							'Öigšte',
							'Herbštmánet',
							'Wímánet',
							'Wintermánet',
							'Chrištmánet'
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
						mon => 'Män',
						tue => 'Ziš',
						wed => 'Mit',
						thu => 'Fró',
						fri => 'Fri',
						sat => 'Sam',
						sun => 'Sun'
					},
					narrow => {
						mon => 'M',
						tue => 'Z',
						wed => 'M',
						thu => 'F',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					wide => {
						mon => 'Mäntag',
						tue => 'Zištag',
						wed => 'Mittwuč',
						thu => 'Fróntag',
						fri => 'Fritag',
						sat => 'Samštag',
						sun => 'Sunntag'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Män',
						tue => 'Ziš',
						wed => 'Mit',
						thu => 'Fró',
						fri => 'Fri',
						sat => 'Sam',
						sun => 'Sun'
					},
					narrow => {
						mon => 'M',
						tue => 'Z',
						wed => 'M',
						thu => 'F',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					wide => {
						mon => 'Mäntag',
						tue => 'Zištag',
						wed => 'Mittwuč',
						thu => 'Fróntag',
						fri => 'Fritag',
						sat => 'Samštag',
						sun => 'Sunntag'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. quartal',
						1 => '2. quartal',
						2 => '3. quartal',
						3 => '4. quartal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => '1. quartal',
						1 => '2. quartal',
						2 => '3. quartal',
						3 => '4. quartal'
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
				'0' => 'v. Chr.',
				'1' => 'n. Chr'
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
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM y G},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
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
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Ed => q{E d.},
			M => q{LLL},
			MEd => q{E, d. MMM},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			Md => q{d. MMM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMd => q{d. MMM y},
		},
		'generic' => {
			Ed => q{E d.},
			M => q{LLL},
			MEd => q{E, d. MMM},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			Md => q{d. MMM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMd => q{d. MMM y},
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
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{MMM – MMM},
			},
			MEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMMd => {
				M => q{d. – d. MMM},
				d => q{d. – d. MMM},
			},
			Md => {
				M => q{d. MMM – d. MMM},
				d => q{d. MMM – d. MMM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} - {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, d. MMM y – E, d. MMM y},
				d => q{E, d. MMM y – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d. – d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'generic' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{MMM – MMM},
			},
			MEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMMd => {
				M => q{d. – d. MMM},
				d => q{d. – d. MMM},
			},
			Md => {
				M => q{d. MMM – d. MMM},
				d => q{d. MMM – d. MMM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} - {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, d. MMM y – E, d. MMM y},
				d => q{E, d. MMM y – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d. – d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} zit),
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dšibuti#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartum#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadišu#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimaninsla#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Havana' => {
			exemplarCity => q#Hawanna#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Monserat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantiši Summerzit#,
				'generic' => q#Atlantiši Zit#,
				'standard' => q#Atlantiši Standardzit#,
			},
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rikjawik#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidnei#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#Unbekannti Stadt#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amšterdam#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarešt#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapešt#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopehage#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Konštantinopel#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Königsbärg#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Laibač#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Reval#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiran#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilna#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Waršau#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürič#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Mitteleuropäiši Summerzit#,
				'generic' => q#Mitteleuropäiši Zit#,
				'standard' => q#Mitteleuropäiši Standardzit#,
			},
			short => {
				'daylight' => q#MESZ#,
				'generic' => q#MEZ#,
				'standard' => q#MEZ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ošteuropäiši Summerzit#,
				'generic' => q#Ošteuropäiši Zit#,
				'standard' => q#Ošteuropäiši Standardzit#,
			},
			short => {
				'daylight' => q#OESZ#,
				'generic' => q#OEZ#,
				'standard' => q#OEZ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Wešteuropäiši Summerzit#,
				'generic' => q#Wešteuropäiši Zit#,
				'standard' => q#Wešteuropäiši Standardzit#,
			},
			short => {
				'daylight' => q#WESZ#,
				'generic' => q#WEZ#,
				'standard' => q#WEZ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
