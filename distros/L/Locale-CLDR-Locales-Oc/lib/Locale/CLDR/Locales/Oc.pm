=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Oc - Package for language Occitan

=cut

package Locale::CLDR::Locales::Oc;
# This file auto generated from Data\common\main\oc.xml
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
				'aa' => 'afar',
 				'af' => 'afrikaans',
 				'ain' => 'aino',
 				'ale' => 'aleut',
 				'am' => 'amaric',
 				'an' => 'aragonés',
 				'ar' => 'arabi',
 				'arn' => 'mapoche',
 				'ast' => 'asturian',
 				'ay' => 'aimara',
 				'az' => 'azerbaijani',
 				'az@alt=short' => 'azeri',
 				'ban' => 'balinés',
 				'be' => 'belarús',
 				'bg' => 'bulgar',
 				'bi' => 'bislama',
 				'bm' => 'bambara',
 				'bn' => 'bengalin',
 				'bo' => 'tibetan',
 				'br' => 'breton',
 				'bs' => 'bosniac',
 				'bug' => 'buginés',
 				'ca' => 'catalan',
 				'ce' => 'chechen',
 				'ceb' => 'cebuan',
 				'chr' => 'cheroqui',
 				'ckb' => 'kurd central',
 				'co' => 'còrs',
 				'cs' => 'chèc',
 				'cu' => 'eslavon',
 				'cv' => 'chovash',
 				'da' => 'danés',
 				'de' => 'alemand',
 				'el' => 'grèc',
 				'en' => 'anglés',
 				'eo' => 'esperanto',
 				'es' => 'espanhòl',
 				'et' => 'estonian',
 				'eu' => 'basc',
 				'fa' => 'perse',
 				'fi' => 'finlandés',
 				'fil' => 'filipino',
 				'fj' => 'fijian',
 				'fo' => 'feroés',
 				'fon' => 'fòn',
 				'fr' => 'francés',
 				'frm' => 'francés mejan',
 				'fur' => 'friolan',
 				'ga' => 'irlandés',
 				'gd' => 'gaelic escossés',
 				'gez' => 'gueèz',
 				'gl' => 'galician',
 				'gn' => 'guaraní',
 				'grc' => 'grec ancian',
 				'gsw' => 'aleman de Soïssa',
 				'gu' => 'gujarati',
 				'he' => 'ebrèu',
 				'hi' => 'Indi',
 				'hi_Latn@alt=variant' => 'inglish',
 				'hr' => 'croat',
 				'hsb' => 'naut sorab',
 				'hu' => 'ongrés',
 				'hy' => 'armèni',
 				'ia' => 'interlingua',
 				'id' => 'indonesian',
 				'io' => 'ido',
 				'is' => 'islandés',
 				'it' => 'italian',
 				'iu' => 'inuktitut',
 				'ja' => 'japonés',
 				'jv' => 'javanés',
 				'ka' => 'georgian',
 				'kab' => 'cabil',
 				'kk' => 'cazac',
 				'km' => 'cambojian',
 				'kn' => 'kannada',
 				'ko' => 'corean',
 				'krl' => 'carelian',
 				'ks' => 'cashmiri',
 				'ku' => 'curd',
 				'kw' => 'cornic',
 				'la' => 'latin',
 				'lad' => 'ladin',
 				'lb' => 'luxemborgés',
 				'lo' => 'laosian',
 				'lt' => 'lituan',
 				'lv' => 'leton',
 				'mg' => 'malgash',
 				'mi' => 'maòri',
 				'mk' => 'macedonian',
 				'mn' => 'mongòl',
 				'mt' => 'maltés',
 				'mul' => 'lengas multiplas',
 				'mwl' => 'mirandés',
 				'my' => 'birman',
 				'na' => 'nauru',
 				'nb' => 'norvegian bokmål',
 				'ne' => 'nepalés',
 				'nl' => 'neerlandés',
 				'nl_BE' => 'flamenc',
 				'nn' => 'norvegian nynorsk',
 				'oc' => 'occitan',
 				'os' => 'osseta',
 				'pa' => 'punjabi',
 				'phn' => 'fenician',
 				'pl' => 'polonés',
 				'pro' => 'occitan ancian',
 				'ps' => 'pashto',
 				'pt' => 'portugués',
 				'qu' => 'quechua',
 				'rm' => 'romanch',
 				'ro' => 'romanés',
 				'ru' => 'rus',
 				'sa' => 'sanscrit',
 				'sc' => 'sard',
 				'scn' => 'sicilian',
 				'sco' => 'escossés',
 				'sk' => 'eslovac',
 				'sl' => 'eslovèn',
 				'sm' => 'samoan',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sq' => 'albanés',
 				'sr' => 'serbi',
 				'st' => 'soto del sud',
 				'sv' => 'suedés',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili de Congo',
 				'swb' => 'comorian',
 				'syr' => 'siriac',
 				'ta' => 'tamol',
 				'te' => 'telogó',
 				'tg' => 'tajic',
 				'th' => 'tai',
 				'tig' => 'tigré',
 				'tk' => 'turcmèn',
 				'tr' => 'turc',
 				'tt' => 'tatar',
 				'ty' => 'tahician',
 				'ug' => 'oigor',
 				'uk' => 'ucrainés',
 				'und' => 'lenga desconeguda',
 				'ur' => 'ordó',
 				'uz' => 'ozbèc',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamian',
 				'vo' => 'volapuc',
 				'xal' => 'kalmoc',
 				'xh' => 'xhòsa',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yue' => 'cantonés',
 				'zh' => 'chinés',
 				'zh@alt=menu' => 'chinés, mandarin',
 				'zh_Hans' => 'chinés simplificat',
 				'zh_Hans@alt=long' => 'chinés mandarin simplificat',
 				'zh_Hant' => 'chinés tradicional',
 				'zh_Hant@alt=long' => 'chinés mandarin tradicional',
 				'zu' => 'zólo',
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
			'Armn' => 'armèni',
 			'Bopo' => 'bopomofó',
 			'Brai' => 'Bralha',
 			'Cyrl' => 'cirilic',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etiopian',
 			'Geor' => 'georgian',
 			'Grek' => 'grec',
 			'Gujr' => 'gojrati',
 			'Hang' => 'hangol',
 			'Hani' => 'chinés',
 			'Hans' => 'simplificat',
 			'Hans@alt=stand-alone' => 'chinés simplificat',
 			'Hant' => 'tradicional',
 			'Hant@alt=stand-alone' => 'chinés tradicional',
 			'Hebr' => 'ebrèu',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'sillabaris japoneses',
 			'Jpan' => 'japonés',
 			'Kana' => 'katakana',
 			'Khmr' => 'kmèr',
 			'Kore' => 'corean',
 			'Laoo' => 'lao',
 			'Latn' => 'latin',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongòl',
 			'Mymr' => 'birman',
 			'Phnx' => 'fenician',
 			'Syre' => 'siriac estranguelo',
 			'Syrj' => 'siriac occidental',
 			'Syrn' => 'siriac oriental',
 			'Taml' => 'tamol',
 			'Zmth' => 'notacion matematica',
 			'Zxxx' => 'pas escricha',
 			'Zzzz' => 'escritura desconeguda',

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
			'001' => 'Monde',
 			'002' => 'Africa',
 			'003' => 'America del Nòrd',
 			'005' => 'America del Sud',
 			'009' => 'Oceania',
 			'011' => 'Africa occidentala',
 			'013' => 'America centrala',
 			'014' => 'Africa orientala',
 			'015' => 'Africa septentrionala',
 			'017' => 'Africa centrala',
 			'018' => 'Africa australa',
 			'019' => 'Americas',
 			'021' => 'Nòrd American',
 			'029' => 'Carib',
 			'030' => 'Asia de l’èst',
 			'034' => 'Asia del Sud',
 			'035' => 'Asia del Sud-èst',
 			'039' => 'Euròpa del Sud',
 			'053' => 'Austràlia e Nòva Zelanda',
 			'054' => 'Melanesia',
 			'057' => 'region micronesiana',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia centrala',
 			'145' => 'Asia de l’oèst',
 			'150' => 'Euròpa',
 			'151' => 'Euròpa de l’èst',
 			'154' => 'Euròpa del Nòrd',
 			'155' => 'Euròpa de l’oèst',
 			'202' => 'Africa subsahariana',
 			'419' => 'America latina',
 			'AC' => 'Isla Ascension',
 			'AD' => 'Andòrra',
 			'AE' => 'Emirats Arabs Units',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angòla',
 			'AQ' => 'Antartica',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa americana',
 			'AT' => 'Àustria',
 			'AU' => 'Austràlia',
 			'AW' => 'Aruba',
 			'AX' => 'llas Åland',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bòsnia e Ercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bolgària',
 			'BH' => 'Barain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sant Bertomiu',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolívia',
 			'BQ' => 'Païses Basses caribèus',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Botan',
 			'BV' => 'Isla Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorussia',
 			'BZ' => 'Belize',
 			'CA' => 'Canadà',
 			'CC' => 'Illas Còcos',
 			'CD' => 'Còngo de Kinshasa',
 			'CD@alt=variant' => 'Republica Democratica de Còngo',
 			'CF' => 'Republica Centraficana',
 			'CG' => 'Còngo de Brazzavila',
 			'CG@alt=variant' => 'Republica de Còngo',
 			'CH' => 'Soïssa',
 			'CI' => 'Còsta d’Evòri',
 			'CK' => 'Illas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Cameron',
 			'CN' => 'China',
 			'CO' => 'Colómbia',
 			'CP' => 'Iscla Clipperton',
 			'CR' => 'Còsta Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cap Verd',
 			'CW' => 'Curaçao',
 			'CX' => 'Illa Christmas',
 			'CY' => 'Chipre',
 			'CZ' => 'Chequia',
 			'CZ@alt=variant' => 'Republica chèca',
 			'DE' => 'Alemanha',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Jiboti',
 			'DK' => 'Danemarc',
 			'DM' => 'Dominica',
 			'DO' => 'Republica dominicana',
 			'DZ' => 'Argeria',
 			'EA' => 'Ceuta e Melilha',
 			'EC' => 'Eqüator',
 			'EE' => 'Estònia',
 			'EG' => 'Egipte',
 			'EH' => 'Saharà occidental',
 			'ER' => 'Eritrèa',
 			'ES' => 'Espanha',
 			'ET' => 'Etiopia',
 			'EU' => 'Union Europèa',
 			'EZ' => 'Zòna euro',
 			'FI' => 'Finlàndia',
 			'FJ' => 'Fiji',
 			'FK' => 'Isclas Falkland',
 			'FK@alt=variant' => 'Malvinas',
 			'FM' => 'Micronesia',
 			'FO' => 'Illas Feròe',
 			'FR' => 'França',
 			'GA' => 'Gabon',
 			'GB' => 'Reiaume Unit',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Grenada',
 			'GE' => 'Geòrgia',
 			'GF' => 'Guiana francesa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ganà',
 			'GI' => 'Gibartar',
 			'GL' => 'Groenlàndia',
 			'GM' => 'Gàmbia',
 			'GN' => 'Guinèa',
 			'GP' => 'Guadalope',
 			'GQ' => 'Guinèa Eqüatoriala',
 			'GR' => 'Grècia',
 			'GS' => 'Georgie del Sud e les Illes Sandwich del Sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinèa-Bissau',
 			'GY' => 'Guianà',
 			'HK' => 'Hong Kong',
 			'HM' => 'Illas Heard e McDonald',
 			'HN' => 'Onduras',
 			'HR' => 'Croàcia',
 			'HT' => 'Haití',
 			'HU' => 'Ongria',
 			'IC' => 'Isclas Canàrias',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israèl',
 			'IM' => 'Illa de Man',
 			'IN' => 'Índia',
 			'IO' => 'Territòri Britanic de l’Ocean Indian',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Islàndia',
 			'IT' => 'Itàlia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaïca',
 			'JO' => 'Jordania',
 			'JP' => 'Japon',
 			'KE' => 'Kenya',
 			'KG' => 'Kirguizstan',
 			'KH' => 'Cambòja',
 			'KI' => 'Kiribatí',
 			'KM' => 'Comòras',
 			'KN' => 'Sant Kitts e Nevis',
 			'KP' => 'Corèa del Nòrd',
 			'KR' => 'Corèa del Sud',
 			'KW' => 'Kowait',
 			'KY' => 'Islas Caiman',
 			'KZ' => 'Cazacstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Santa Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberià',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituània',
 			'LU' => 'Luxemborg',
 			'LV' => 'Letònia',
 			'LY' => 'Libia',
 			'MA' => 'Marròc',
 			'MC' => 'Mónegue',
 			'MD' => 'Moldàvia',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Illas Marshall',
 			'MK' => 'Macedónia del Nòrd',
 			'ML' => 'Mali',
 			'MM' => 'Birmania',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau',
 			'MP' => 'Illas Mariannas del Nòrd',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritània',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurici',
 			'MV' => 'Maldivas',
 			'MW' => 'Malavi',
 			'MX' => 'Mexic',
 			'MY' => 'Malàisia',
 			'MZ' => 'Moçambic',
 			'NA' => 'Namibia',
 			'NC' => 'Nòva Caledonia',
 			'NE' => 'Nigèr',
 			'NF' => 'Illas Norfòlk',
 			'NG' => 'Nigèria',
 			'NI' => 'Nicaragüa',
 			'NL' => 'Païses Basses',
 			'NO' => 'Norvègia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nòva Zelanda',
 			'OM' => 'Òman',
 			'PA' => 'Panamà',
 			'PE' => 'Peró',
 			'PF' => 'Polinesia francesa',
 			'PG' => 'Papoa-Nòva Guinèa',
 			'PH' => 'Filipinas',
 			'PK' => 'Paquistan',
 			'PL' => 'Polonha',
 			'PM' => 'Sant Pèire e Miquelon',
 			'PN' => 'Iscla Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Territòris palestinians',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Belau',
 			'PY' => 'Paraguai',
 			'QA' => 'Catar',
 			'QO' => 'Oceania exteriora',
 			'RE' => 'Reünion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Roanda',
 			'SA' => 'Arabia Saudita',
 			'SB' => 'Illas Salamon',
 			'SC' => 'Seissèlas',
 			'SD' => 'Sodan',
 			'SE' => 'Suècia',
 			'SG' => 'Singapor',
 			'SH' => 'Santa Elena',
 			'SI' => 'Eslovènia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Eslovaquia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'Sant Marin',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sodan del Sud',
 			'ST' => 'Sant Tomàs e Prince',
 			'SV' => 'Lo Salvador',
 			'SX' => 'Sant Martin',
 			'SY' => 'Súria',
 			'SZ' => 'Eswatini',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Illas Turcas e Caïcas',
 			'TD' => 'Chad',
 			'TF' => 'Territòris del Sud franceses',
 			'TG' => 'Tògo',
 			'TH' => 'Tailàndia',
 			'TJ' => 'Tatgiquistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timòr Èst',
 			'TM' => 'Turcmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tònga',
 			'TR' => 'Turquia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraïna',
 			'UG' => 'Oganda',
 			'UN' => 'Nacions Unidas',
 			'US' => 'Estats Units',
 			'US@alt=short' => 'EU',
 			'UY' => 'Uruguai',
 			'UZ' => 'Ozbequistan',
 			'VA' => 'Ciutat del Vatican',
 			'VC' => 'St Vincent e Granadinas',
 			'VE' => 'Veneçuèla',
 			'VG' => 'Illas Verges britanicas',
 			'VI' => 'Illas Verges estatsunidencas',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatú',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Lenga-artificiala-accentuada',
 			'XB' => 'Lenga-artificiala-bidireccionala',
 			'XK' => 'Kosova',
 			'YE' => 'Iémen',
 			'YT' => 'Maiòta',
 			'ZA' => 'Africa del Sud',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Region indeterminada',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'calendier',
 			'collation' => 'òrde alfabetic',
 			'currency' => 'moneda',

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
 				'gregorian' => q{calendièr gregorian},
 				'iso8601' => q{calendièr ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{òrdre per defaut},
 			},
 			'numbers' => {
 				'latn' => q{chifras occidentalas},
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
			'UK' => q{anglosajon},
 			'US' => q{estadounidenc},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lenga : {0}',
 			'script' => 'Escritura : {0}',
 			'region' => 'Region : {0}',

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
			auxiliary => qr{[ăâåäãā æ ĕêëē ìĭîī ñ ŏôöøō œ ùŭûū ÿ]},
			index => ['A', 'B', 'CÇ', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y'],
			main => qr{[aáà b cç d eéè f g h iíï j k l m n oóò p q r s t uúü v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … ’ "“” « » ( ) \[ \] § @ * / \& # † ‡ ⋅]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'CÇ', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0}… {1}',
		};
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
	default		=> qq{«},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direccion cardinala),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direccion cardinala),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ecto{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(quilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(quilo{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G d’acceleracion),
						'other' => q({0} G d'acceleracion),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G d’acceleracion),
						'other' => q({0} G d'acceleracion),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mètres per segonda al cairat),
						'other' => q({0} mètres per segonda al cairat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mètres per segonda al cairat),
						'other' => q({0} mètres per segonda al cairat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(minutas d’arc),
						'other' => q({0} minutas d’arc),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minutas d’arc),
						'other' => q({0} minutas d’arc),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(segondas d’arc),
						'other' => q({0} segondas d'arc),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(segondas d’arc),
						'other' => q({0} segondas d'arc),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gra),
						'other' => q({0} grases),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gra),
						'other' => q({0} grases),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radians),
						'other' => q({0} radians),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radians),
						'other' => q({0} radians),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(revolucion),
						'other' => q({0} revolucion),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(revolucion),
						'other' => q({0} revolucion),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ectaras),
						'other' => q({0} ectaras),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ectaras),
						'other' => q({0} ectaras),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(centimètres cairats),
						'other' => q({0} centimètres cairats),
						'per' => q({0} per centimètres cairats),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(centimètres cairats),
						'other' => q({0} centimètres cairats),
						'per' => q({0} per centimètres cairats),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(quilomètres cairats),
						'other' => q({0} quilomètres cairats),
						'per' => q({0} per quilomètre cairat),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(quilomètres cairats),
						'other' => q({0} quilomètres cairats),
						'per' => q({0} per quilomètre cairat),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mètres cairats),
						'other' => q({0} mètres cairats),
						'per' => q({0} per mètres cairats),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mètres cairats),
						'other' => q({0} mètres cairats),
						'per' => q({0} per mètres cairats),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramas per decilitre),
						'other' => q({0} miligramas per decilitre),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramas per decilitre),
						'other' => q({0} miligramas per decilitre),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimòls per litres),
						'other' => q({0} milimòls per litres),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimòls per litres),
						'other' => q({0} milimòls per litres),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mòls),
						'other' => q({0} mòls),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mòls),
						'other' => q({0} mòls),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q({0} de cent),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q({0} de cent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(de mila),
						'other' => q({0} de mila),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(de mila),
						'other' => q({0} de mila),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partidas per milions),
						'other' => q({0} partidas per milions),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partidas per milions),
						'other' => q({0} partidas per milions),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litres per 100 quilomètres),
						'other' => q({0} litres per 100 quilomètres),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litres per 100 quilomètres),
						'other' => q({0} litres per 100 quilomètres),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litres per quilomètres),
						'other' => q({0} litres per quilomètres),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litres per quilomètres),
						'other' => q({0} litres per quilomètres),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} èst),
						'north' => q({0} nòrd),
						'south' => q({0} sud),
						'west' => q({0} oèst),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} èst),
						'north' => q({0} nòrd),
						'south' => q({0} sud),
						'west' => q({0} oèst),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(octets),
						'other' => q({0} octets),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(octets),
						'other' => q({0} octets),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigaoctets),
						'other' => q({0} gigaoctets),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigaoctets),
						'other' => q({0} gigaoctets),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(quilooctets),
						'other' => q({0} quilooctets),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(quilooctets),
						'other' => q({0} quilooctets),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megaoctets),
						'other' => q({0} megaoctets),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megaoctets),
						'other' => q({0} megaoctets),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petaoctets),
						'other' => q({0} petaoctets),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petaoctets),
						'other' => q({0} petaoctets),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(teraoctets),
						'other' => q({0} teraoctets),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(teraoctets),
						'other' => q({0} teraoctets),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sègles),
						'other' => q({0} sègles),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sègles),
						'other' => q({0} sègles),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0} jorns),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0} jorns),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(decennia),
						'other' => q({0} decennia),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(decennia),
						'other' => q({0} decennia),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} oras),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} oras),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutas),
						'other' => q({0} minutas),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutas),
						'other' => q({0} minutas),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meses),
						'other' => q({0} mes),
						'per' => q({0} per mes),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meses),
						'other' => q({0} mes),
						'per' => q({0} per mes),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segondas),
						'other' => q({0} segondas),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segondas),
						'other' => q({0} segondas),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} setmanas),
						'per' => q({0} per setmana),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} setmanas),
						'per' => q({0} per setmana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} annadas),
						'per' => q({0} per annada),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} annadas),
						'per' => q({0} per annada),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampèrs),
						'other' => q({0} ampèrs),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampèrs),
						'other' => q({0} ampèrs),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliampèrs),
						'other' => q({0} miliampèrs),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliampèrs),
						'other' => q({0} miliampèrs),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0} vòlts),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0} vòlts),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(calorias),
						'other' => q({0} calorias),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(calorias),
						'other' => q({0} calorias),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electronvòlts),
						'other' => q({0} electronvòlts),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronvòlts),
						'other' => q({0} electronvòlts),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Calorias),
						'other' => q({0} Calorias),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Calorias),
						'other' => q({0} Calorias),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joules),
						'other' => q({0} joules),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joules),
						'other' => q({0} joules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(quilocalorias),
						'other' => q({0} quilocalorias),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(quilocalorias),
						'other' => q({0} quilocalorias),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(quilojoules),
						'other' => q({0} quilojoules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(quilojoules),
						'other' => q({0} quilojoules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(quilowatt-oras),
						'other' => q({0} quilowatt-oras),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(quilowatt-oras),
						'other' => q({0} quilowatt-oras),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(quilohertz),
						'other' => q({0} quilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(quilohertz),
						'other' => q({0} quilohertz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(punts per centimètre),
						'other' => q({0} punts per centimètre),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(punts per centimètre),
						'other' => q({0} punts per centimètre),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centimètres),
						'per' => q({0} per centimètres),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimètres),
						'per' => q({0} per centimètres),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decimètres),
						'other' => q({0} decimètres),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decimètres),
						'other' => q({0} decimètres),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(quilomètres),
						'other' => q({0} quilomètres),
						'per' => q({0} per quilomètre),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(quilomètres),
						'other' => q({0} quilomètres),
						'per' => q({0} per quilomètre),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mètres),
						'other' => q({0} mètres),
						'per' => q({0} per mètre),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mètres),
						'other' => q({0} mètres),
						'per' => q({0} per mètre),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micromètres),
						'other' => q({0} micromètres),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micromètres),
						'other' => q({0} micromètres),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimètres),
						'other' => q({0} milimètres),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimètres),
						'other' => q({0} milimètres),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomètres),
						'other' => q({0} nanomètres),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomètres),
						'other' => q({0} nanomètres),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picomètres),
						'other' => q({0} picomètres),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picomètres),
						'other' => q({0} picomètres),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punts),
						'other' => q({0} punts),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punts),
						'other' => q({0} punts),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminositats solaras),
						'other' => q({0} luminositats solaras),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminositats solaras),
						'other' => q({0} luminositats solaras),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(massas de Tèrra),
						'other' => q({0} massas de Tèrra),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(massas de Tèrra),
						'other' => q({0} massas de Tèrra),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} gramas),
						'per' => q({0} per gramas),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} gramas),
						'per' => q({0} per gramas),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(quilogramas),
						'other' => q({0} quilogramas),
						'per' => q({0} per quilogramas),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(quilogramas),
						'other' => q({0} quilogramas),
						'per' => q({0} per quilogramas),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(microgramas),
						'other' => q({0} microgramas),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(microgramas),
						'other' => q({0} microgramas),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligramas),
						'other' => q({0} miligramas),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligramas),
						'other' => q({0} miligramas),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(massas de Solelh),
						'other' => q({0} massa de Solelh),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(massas de Solelh),
						'other' => q({0} massa de Solelh),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonas),
						'other' => q({0} tonas),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonas),
						'other' => q({0} tonas),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonas metricas),
						'other' => q({0} tonas metricas),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonas metricas),
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
						'name' => q(cavals vapor),
						'other' => q({0} cavals vapor),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cavals vapor),
						'other' => q({0} cavals vapor),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(quilowatts),
						'other' => q({0} quilowatts),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(quilowatts),
						'other' => q({0} quilowatts),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watts),
						'other' => q({0} watts),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watts),
						'other' => q({0} watts),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} cairat),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} cairat),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q({0} cubic),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q({0} cubic),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfèras),
						'other' => q({0} atmosfèras),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfèras),
						'other' => q({0} atmosfèras),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ectopascals),
						'other' => q({0} ectopascals),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ectopascals),
						'other' => q({0} ectopascals),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(quilopascals),
						'other' => q({0} quilopascals),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(quilopascals),
						'other' => q({0} quilopascals),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibars),
						'other' => q({0} milibars),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibars),
						'other' => q({0} milibars),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimètres de mercuri),
						'other' => q({0} milimètres de mercuri),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimètres de mercuri),
						'other' => q({0} milimètres de mercuri),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(quilomètres per ora),
						'other' => q({0} quilomètres per ora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(quilomètres per ora),
						'other' => q({0} quilomètres per ora),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(noses),
						'other' => q({0} noses),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(noses),
						'other' => q({0} noses),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mètres per segonda),
						'other' => q({0} mètres per segonda),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mètres per segonda),
						'other' => q({0} mètres per segonda),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(grases Celsius),
						'other' => q({0} grases Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(grases Celsius),
						'other' => q({0} grases Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(grases Fahrenheit),
						'other' => q({0} grases Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(grases Fahrenheit),
						'other' => q({0} grases Fahrenheit),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton-mètres),
						'other' => q({0} newton-mètres),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-mètres),
						'other' => q({0} newton-mètres),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(centilitres),
						'other' => q({0} centilitres),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(centilitres),
						'other' => q({0} centilitres),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(centimètres cubics),
						'other' => q({0} centimètres cubics),
						'per' => q({0} per centimètres cubics),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(centimètres cubics),
						'other' => q({0} centimètres cubics),
						'per' => q({0} per centimètres cubics),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(quilomètres cubics),
						'other' => q({0} quilomètres cubics),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(quilomètres cubics),
						'other' => q({0} quilomètres cubics),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mètres cubics),
						'other' => q({0} mètres cubics),
						'per' => q({0} per mètres cubics),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mètres cubics),
						'other' => q({0} mètres cubics),
						'per' => q({0} per mètres cubics),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(decilitres),
						'other' => q({0} decilitres),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(decilitres),
						'other' => q({0} decilitres),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(culhièr de cafè),
						'other' => q({0} culhièr de cafè),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(culhièr de cafè),
						'other' => q({0} culhièr de cafè),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(culhièr de cafè imperial),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(culhièr de cafè imperial),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ectolitres),
						'other' => q({0} ectolitres),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ectolitres),
						'other' => q({0} ectolitres),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} litres),
						'per' => q({0} per litre),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} litres),
						'per' => q({0} per litre),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitres),
						'other' => q({0} megalitres),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitres),
						'other' => q({0} megalitres),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitres),
						'other' => q({0} mililitres),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitres),
						'other' => q({0} mililitres),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(jorn),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(jorn),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ora),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ora),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(an.),
						'other' => q({0} an.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(an.),
						'other' => q({0} an.),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grama),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grama),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direccion),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direccion),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G d’acc.),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G d’acc.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(de cent),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(de cent),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(octet),
						'other' => q({0} octet),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(octet),
						'other' => q({0} octet),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(Go),
						'other' => q({0} Go),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(Go),
						'other' => q({0} Go),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ko),
						'other' => q({0} ko),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ko),
						'other' => q({0} ko),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(Mo),
						'other' => q({0} Mo),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(Mo),
						'other' => q({0} Mo),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(Po),
						'other' => q({0} Po),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(Po),
						'other' => q({0} Po),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(To),
						'other' => q({0} To),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(To),
						'other' => q({0} To),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(s.),
						'other' => q({0} s.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(s.),
						'other' => q({0} s.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(jorns),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(jorns),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(oras),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(oras),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mes),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mes),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(setm.),
						'other' => q({0} setm.),
						'per' => q({0}/setm.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(setm.),
						'other' => q({0} setm.),
						'per' => q({0}/setm.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(annadas),
						'other' => q({0} ans),
						'per' => q({0}/an.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(annadas),
						'other' => q({0} ans),
						'per' => q({0}/an.),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(vòlts),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(vòlts),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punt),
						'other' => q({0} punt),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punt),
						'other' => q({0} punt),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mètre),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mètre),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gran),
						'other' => q({0} gran),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gran),
						'other' => q({0} gran),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramas),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramas),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cv),
						'other' => q({0} cv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cv),
						'other' => q({0} cv),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mètres/seg.),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mètres/seg.),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gr. C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gr. C),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(culh. cafè),
						'other' => q({0} culh. cafè),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(culh. cafè),
						'other' => q({0} culh. cafè),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(culh. cafè imp.),
						'other' => q({0} culh. cafè imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(culh. cafè imp.),
						'other' => q({0} culh. cafè imp.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gota),
						'other' => q({0} gota),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gota),
						'other' => q({0} gota),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litres),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litres),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pecic),
						'other' => q({0} pecic),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pecic),
						'other' => q({0} pecic),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:òc|o|yes|y)$' }
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
				end => q({0} e {1}),
				2 => q({0} e {1}),
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
			'timeSeparator' => q('h'),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
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
		'adlm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'arabext' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'bali' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'beng' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'brah' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'cakm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'cham' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'deva' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'fullwide' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'gong' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'gonm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'gujr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'guru' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'hanidec' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'java' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'kali' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'khmr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'knda' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'lana' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'lanatham' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'laoo' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(#,##0.00¤)',
						'positive' => '#,##0.00¤',
					},
					'standard' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'lepc' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'limb' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'mlym' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'mong' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'mtei' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'mymr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'mymrshan' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'nkoo' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'olck' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'orya' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'osma' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'rohg' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'saur' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'shrd' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'sora' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'sund' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'takr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'talu' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'tamldec' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'telu' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'thai' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'tibt' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
					},
				},
			},
		},
		'vaii' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00',
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
		'AED' => {
			display_name => {
				'currency' => q(dírham des Emirats Arabi Units),
				'other' => q(dírhams des Emirats Arabi Units),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgani),
				'other' => q(afganis),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek),
				'other' => q(leks),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram),
				'other' => q(drams),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(florin atillans),
				'other' => q(florins atillans),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kuanza),
				'other' => q(kuances),
			},
		},
		'ARS' => {
			symbol => '$AR',
			display_name => {
				'currency' => q(peso argentí),
				'other' => q(pesi argentís),
			},
		},
		'AUD' => {
			symbol => '$AU',
			display_name => {
				'currency' => q(dòlar australian),
				'other' => q(dòlars australians),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(florin arubenc),
				'other' => q(florins arubencs),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azerbaiyan),
				'other' => q(manats azerbaiyans),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marc convertible de Bosnia e Herzegovina),
				'other' => q(marcs convertibles de Bosnia e Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dòlar barbadenc),
				'other' => q(dòlars barbadencs),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka),
				'other' => q(takas),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(leva búlgara),
				'other' => q(leves búlgares),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar bareiní),
				'other' => q(dinars bareinís),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franc burundés),
				'other' => q(francs burundessi),
			},
		},
		'BMD' => {
			symbol => '$BM',
			display_name => {
				'currency' => q(dòlar bermudense),
				'other' => q(dòlars bermudenses),
			},
		},
		'BND' => {
			symbol => '$BN',
			display_name => {
				'currency' => q(dòlar bruneian),
				'other' => q(dòlars bruneians),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivian),
				'other' => q(bolivians),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(real brasilian),
				'other' => q(reals brasilians),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dòlar bahamenc),
				'other' => q(dòlars bahamencs),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(gultrum),
				'other' => q(gultrums),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula),
				'other' => q(pules),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(roble bielorrús),
				'other' => q(robles bielorrussi),
			},
		},
		'BZD' => {
			symbol => '$BZ',
			display_name => {
				'currency' => q(dòlar belizen),
				'other' => q(dòlars belizens),
			},
		},
		'CAD' => {
			symbol => '$CA',
			display_name => {
				'currency' => q(dòlar canadiense),
				'other' => q(dòlars canadienses),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franc congolenc),
				'other' => q(francs congolencs),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franc suís),
				'other' => q(francs suïssi),
			},
		},
		'CLP' => {
			symbol => '$CL',
			display_name => {
				'currency' => q(peso chilen),
				'other' => q(pesi chilens),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(yuan chinés \(extracontinanetal\)),
				'other' => q(yuans chineses \(extracontinanetals\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan chinés),
				'other' => q(yuans chineses),
			},
		},
		'COP' => {
			symbol => '$CO',
			display_name => {
				'currency' => q(peso colombian),
				'other' => q(pesi colombians),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colon costarricense),
				'other' => q(colons costarricenses),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso convertible cuban),
				'other' => q(pesi convertibles cubans),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cuban),
				'other' => q(pesi cubans),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escut de Cab Verd),
				'other' => q(escuts de Cab Verd),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(corona checa),
				'other' => q(corones cheques),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franc yibutian),
				'other' => q(francs yibutians),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(corona danesa),
				'other' => q(corones daneses),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(pes dominican),
				'other' => q(pesi dominicans),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar argelin),
				'other' => q(dinars argelins),
			},
		},
		'EGP' => {
			symbol => '£E',
			display_name => {
				'currency' => q(libra egipcia),
				'other' => q(libres egipcies),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa),
				'other' => q(nakfes),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(bir),
				'other' => q(bires),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'other' => q(euros),
			},
		},
		'FJD' => {
			symbol => '$FJ',
			display_name => {
				'currency' => q(dòlar fiyian),
				'other' => q(dòlars fiyians),
			},
		},
		'FKP' => {
			symbol => '£FK',
			display_name => {
				'currency' => q(libra malvinenca),
				'other' => q(libres malvinenques),
			},
		},
		'GBP' => {
			symbol => '£GB',
			display_name => {
				'currency' => q(liura esterlina),
				'other' => q(liuras esterlinas),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari),
				'other' => q(laris),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi),
				'other' => q(cedis),
			},
		},
		'GIP' => {
			symbol => '£GI',
			display_name => {
				'currency' => q(libra gibraltarenca),
				'other' => q(libres gibraltarenques),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi),
				'other' => q(dalasis),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franc guinean),
				'other' => q(francs guineans),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal gautemaltec),
				'other' => q(quetzals gautemaltecs),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dòlar guayanés),
				'other' => q(dòlars guayanesi),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(dòlar hongkonés),
				'other' => q(dòlars hongkoneses),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira hondurenh),
				'other' => q(lempires hondurenhs),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna),
				'other' => q(kunes),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gorde haitian),
				'other' => q(gordes haitians),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forinto húngar),
				'other' => q(forintos húngars),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(ropia indonesia),
				'other' => q(ropies indonesies),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(nau séquel israelí),
				'other' => q(naus séquels israelís),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ropia indiana),
				'other' => q(ropias indianas),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar iraquí),
				'other' => q(dinars iraquís),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iraní),
				'other' => q(rials iranís),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(corona islandesa),
				'other' => q(corones islandeses),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dòlar jamaican),
				'other' => q(dòlars jamaicans),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar jordan),
				'other' => q(dinars jordans),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(yen),
				'other' => q(yens),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(chelin kenian),
				'other' => q(chelins kenians),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(sòm),
				'other' => q(sòms),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel),
				'other' => q(riels),
			},
		},
		'KMF' => {
			symbol => 'FC',
			display_name => {
				'currency' => q(franc comorens),
				'other' => q(francs comorensi),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won nòrd-corean),
				'other' => q(wons nòrd-coreans),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(won sud-corean),
				'other' => q(wons sud-coreans),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar kuwaitin),
				'other' => q(dinars kuwaitins),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dòlar d’Illes Caiman),
				'other' => q(dòlars d’Illes Caiman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tengue kazaji),
				'other' => q(tengues kazajis),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip),
				'other' => q(kips),
			},
		},
		'LBP' => {
			symbol => '£LB',
			display_name => {
				'currency' => q(libra libanesa),
				'other' => q(libres libaneses),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(ropia esrilanquesa),
				'other' => q(ropies esrilanqueses),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dòlar liberian),
				'other' => q(dòlars liberians),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lesotenc),
				'other' => q(lotis lesotensi),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libi),
				'other' => q(dinars libis),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dírham marroquin),
				'other' => q(dírhams marroquins),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldau),
				'other' => q(leus moldaus),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariari),
				'other' => q(ariaris),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dinar macedoni),
				'other' => q(dinars macedonis),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kiat),
				'other' => q(kiats),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik),
				'other' => q(tugriks),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca de Macao),
				'other' => q(pataques de Macao),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(uguiya),
				'other' => q(uguiyes),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(ropia mauriciana),
				'other' => q(ropies mauricianes),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiya),
				'other' => q(rufiyas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kuacha malauí),
				'other' => q(kuaches malauies),
			},
		},
		'MXN' => {
			symbol => '$MX',
			display_name => {
				'currency' => q(peso mexican),
				'other' => q(pesi mexicans),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringit),
				'other' => q(ringits),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical),
				'other' => q(meticals),
			},
		},
		'NAD' => {
			symbol => '$NA',
			display_name => {
				'currency' => q(dòlar namibi),
				'other' => q(dòlars namibis),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira),
				'other' => q(naires),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(còrdoba aur),
				'other' => q(còrdobas aur),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(corona noruegua),
				'other' => q(corones noruegues),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(ropia nepalí),
				'other' => q(ropies nepalís),
			},
		},
		'NZD' => {
			symbol => '$NZ',
			display_name => {
				'currency' => q(dòlar neozelandés),
				'other' => q(dòlars neozelandeses),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omaní),
				'other' => q(rials omanís),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa panamenh),
				'other' => q(balboes panamenhs),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sòl peruan),
				'other' => q(sòls peruans),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina),
				'other' => q(kinas),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso filipin),
				'other' => q(pesi filipins),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(ropia pakistaní),
				'other' => q(ropies pakistanís),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(esloti),
				'other' => q(eslotis),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guaraní paraguayan),
				'other' => q(guaranís paraguayans),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial catarí),
				'other' => q(rials catarís),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(leu ruman),
				'other' => q(leus rumans),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar serbi),
				'other' => q(dinars serbis),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(roble rus),
				'other' => q(robles russes),
			},
		},
		'RWF' => {
			symbol => 'FR',
			display_name => {
				'currency' => q(franc ruandés),
				'other' => q(francs ruandessi),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rial saudí),
				'other' => q(rials saudís),
			},
		},
		'SBD' => {
			symbol => '$SB',
			display_name => {
				'currency' => q(dòlar salomonenc),
				'other' => q(dòlars salomonencs),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(ropia seychellense),
				'other' => q(ropies seychellenses),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(libra sudanesa),
				'other' => q(libres sudaneses),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(corona sueca),
				'other' => q(corones sueques),
			},
		},
		'SGD' => {
			symbol => '$SG',
			display_name => {
				'currency' => q(dòlar singapurense),
				'other' => q(dòlars singapurenses),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(libra de Santa Elena),
				'other' => q(libres de Santa Elena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leona),
				'other' => q(leones),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leona \(1964—2022\)),
				'other' => q(leones \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(chelin somalí),
				'other' => q(chelins somalís),
			},
		},
		'SRD' => {
			symbol => '$SR',
			display_name => {
				'currency' => q(dòlar surinamés),
				'other' => q(dòlars surinamesi),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(libra sud-sudanesa),
				'other' => q(libres sud-sudaneses),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra),
				'other' => q(dobres),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(libra siria),
				'other' => q(libres siries),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni),
				'other' => q(lilangenis),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(bat),
				'other' => q(bats),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tayiko),
				'other' => q(somonis tayikos),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turcoman),
				'other' => q(manats turcomans),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunecin),
				'other' => q(dinars tunecins),
			},
		},
		'TOP' => {
			symbol => '$T',
			display_name => {
				'currency' => q(paanga),
				'other' => q(paangues),
			},
		},
		'TRY' => {
			symbol => 'LT',
			display_name => {
				'currency' => q(lira turca),
				'other' => q(lires turques),
			},
		},
		'TTD' => {
			symbol => '$TT',
			display_name => {
				'currency' => q(dòlar de Trinidad e Tobago),
				'other' => q(dòlars de Trinidad e Tobago),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(nau dòlar taiwanés),
				'other' => q(naus dòlars taiwaneses),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(chelin tanzan),
				'other' => q(chelins tanzans),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(grivna),
				'other' => q(grivnes),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(chelin ugandés),
				'other' => q(chelins ugandessi),
			},
		},
		'USD' => {
			symbol => '$US',
			display_name => {
				'currency' => q(dòlar american),
				'other' => q(dòlars americans),
			},
		},
		'UYU' => {
			symbol => '$UY',
			display_name => {
				'currency' => q(peso uruguayan),
				'other' => q(pesi uruguayans),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(sum),
				'other' => q(sums),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar venezolan),
				'other' => q(bolívars venezolans),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dong),
				'other' => q(dongs),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu),
				'other' => q(vatus),
			},
		},
		'WST' => {
			symbol => '$WS',
			display_name => {
				'currency' => q(tala),
				'other' => q(tales),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franc CFA d’Africa central),
				'other' => q(francs CFA d’Africa central),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(dòlar del Caribe Occidental),
				'other' => q(dòlars del Caribe Occidental),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franc CFA d’Africa occidental),
				'other' => q(francs CFA d’Africa occidental),
			},
		},
		'XPF' => {
			symbol => 'FCFP',
			display_name => {
				'currency' => q(franc CFP),
				'other' => q(francs CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Moneda desconeguda),
				'other' => q(\(moneda desconeguda\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial yemení),
				'other' => q(rials yemenís),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand),
				'other' => q(rands),
			},
		},
		'ZMW' => {
			symbol => 'Kw',
			display_name => {
				'currency' => q(kuacha zambiana),
				'other' => q(kuaches zambianes),
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
							'gen.',
							'feb.',
							'març',
							'abr.',
							'mai',
							'junh',
							'jul.',
							'ago.',
							'set.',
							'oct.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'de genièr',
							'de febrièr',
							'de març',
							'd’abril',
							'de mai',
							'de junh',
							'de julhet',
							'd’agost',
							'de setembre',
							'd’octòbre',
							'de novembre',
							'de decembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'G',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'genièr',
							'febrièr',
							'març',
							'abril',
							'mai',
							'junh',
							'julhet',
							'agost',
							'setembre',
							'octòbre',
							'novembre',
							'decembre'
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
					short => {
						mon => 'dl',
						tue => 'dm',
						wed => 'dc',
						thu => 'dj',
						fri => 'dv',
						sat => 'ds',
						sun => 'dg'
					},
					wide => {
						mon => 'diluns',
						tue => 'dimars',
						wed => 'dimècres',
						thu => 'dijòus',
						fri => 'divendres',
						sat => 'dissabte',
						sun => 'dimenge'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'Dl',
						tue => 'Dm',
						wed => 'Dc',
						thu => 'Dj',
						fri => 'Dv',
						sat => 'Ds',
						sun => 'Dg'
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
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					wide => {0 => '1èr trimèstre',
						1 => '2nd trimèstre',
						2 => '3en trimèstre',
						3 => '4en trimèstre'
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
				'0' => 'Ab. J.C.',
				'1' => 'de. J.-C.'
			},
			narrow => {
				'1' => 'CE'
			},
			wide => {
				'0' => 'Abans Jèsus-Crist',
				'1' => 'despús Jèsus-Crist'
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
			'full' => q{EEEE d MMMM 'de' y G},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM 'de' y},
			'long' => q{d MMMM 'de' y},
			'medium' => q{d MMM y},
			'short' => q{d/MM/yy},
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
			'full' => q{HH:mm:ss zzzz},
			'long' => q{H'h'mm:ss z},
			'medium' => q{H'h'mm:ss},
			'short' => q{H'h'mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} 'a' {0}},
			'long' => q{{1} 'a' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'a' {0}},
			'long' => q{{1} 'a' {0}},
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
			Ed => q{E d},
			Gy => q{y G},
			MEd => q{E dd/MM},
			Md => q{dd/MM},
		},
		'gregorian' => {
			Bh => q{h'h' B},
			Bhm => q{h'h'mm B},
			Bhms => q{h'h'mm:ss B},
			EBhm => q{E h'h'mm B},
			EBhms => q{E h'h'mm:ss B},
			EHm => q{E HH'h'mm},
			EHms => q{E HH'h'mm ss 'seg'.},
			Ed => q{ccc d},
			Ehm => q{E h'h'mm a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/Y G},
			Hm => q{HH'h'mm},
			Hms => q{HH'h'mm ss 'seg'.},
			Hmsv => q{HH'h'mm ss 'seg'. v},
			Hmv => q{HH'h'mm v},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMW => q{'setmana' W MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h'h' a},
			hm => q{h'h'mm a},
			hms => q{h'h'mm:ss a},
			hmv => q{h'h'mm a v},
			yM => q{MM/y},
			yMEd => q{E dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{LLLL 'de' y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'de' y},
			yw => q{'setmana' w 'de' Y},
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
			d => {
				d => q{d – d},
			},
		},
		'gregorian' => {
			Bhm => {
				B => q{h'h'mm B – h'h'mm B},
				h => q{h'h'mm – h'h'mm B},
				m => q{h'h'mm – h'h'mm B},
			},
			Gy => {
				y => q{y – y G},
			},
			GyM => {
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E d/M/y GGGGG – E d/M/y GGGGG},
				M => q{E d/MM – E d/MM/y G},
				d => q{E d – E d/MM/y G},
				y => q{E d/MM/y – E d/MM/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM 'de' y G – E d MMM 'de' y G},
				M => q{E d MMM – E d MMM 'de' y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM 'de' y – E d MMM 'de' y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/MM/y GGGGG – d/MM/y GGGGG},
				M => q{d/MM/y – d/MM/y GGGGG},
				d => q{d/MM/y – d/MM/y GGGGG},
			},
			H => {
				H => q{HH'h' – HH'h'},
			},
			Hm => {
				H => q{HH'h'mm – HH'h'mm},
				m => q{HH'h'mm – HH'h'mm},
			},
			Hmv => {
				H => q{HH'h'mm – HH'h'mm v},
				m => q{HH'h'mm – HH'h'mm v},
			},
			Hv => {
				H => q{HH'h' – HH'h' v},
			},
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{E dd-MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h'h' a – h'h' a},
				h => q{h'h' – h'h' a},
			},
			hm => {
				a => q{h'h'mm a – h'h'mm a},
				h => q{h'h'mm – h'h'mm a},
				m => q{h'h'mm – h'h'mm a},
			},
			hmv => {
				a => q{h'h'mm a – h'h'mm a v},
				h => q{h'h'mm – h'h'mm a v},
				m => q{h'h'mm – h'h'mm a v},
			},
			hv => {
				a => q{h'h' a – h'h' a v},
				h => q{h'h' – h'h' a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM 'de' y},
				d => q{E d MMM – E d MMM 'de' y},
				y => q{E d MMM 'de' y – E d MMM 'de' y},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'de' y},
				y => q{LLLL 'de' y – LLLL 'de' y},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y},
				d => q{d – d MMM y},
				y => q{d LLL 'de' y – d LLL 'de' y},
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
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(ora de {0}),
		regionFormat => q({0} (ora d’estiu)),
		regionFormat => q({0} (ora estandard)),
		'Afghanistan' => {
			long => {
				'standard' => q#ora d’Afganistan#,
			},
		},
		'Africa/Algiers' => {
			exemplarCity => q#Argièrs#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jiboti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Doala#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#ora d’Africa centrala#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#ora d’Africa de l’èst#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#ora de Sudafrica#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#ora d’estiu d’Africa occidentala#,
				'generic' => q#ora d’Africa occidentala#,
				'standard' => q#ora estandarda d’Africa occidentala#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#ora d’estiu d’Alaska#,
				'generic' => q#ora d’Alaska#,
				'standard' => q#ora estandarda d’Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#ora d’estiu l’Amazònes#,
				'generic' => q#ora de l’Amazònes#,
				'standard' => q#ora estandarda de l’Amazònes#,
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q#ora d’estiu centrala#,
				'generic' => q#ora centrala#,
				'standard' => q#ora estandarda centrala#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ora d’estiu de l’Èst#,
				'generic' => q#ora de l’Èst#,
				'standard' => q#ora estandarda de l’Èst#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ora d’estiu de la montanha#,
				'generic' => q#ora de la montanha#,
				'standard' => q#ora estandarda de la montanha#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#ora d’estiu del Pacific#,
				'generic' => q#ora del Pacific#,
				'standard' => q#ora estandarda del Pacific#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#ora d’esiu d’Apia#,
				'generic' => q#ora d’Apia#,
				'standard' => q#ora estandard d’Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#ora d’estiu d’Arabia#,
				'generic' => q#ora d’Arabia#,
				'standard' => q#ora estandarda d’Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#ora d’estiu d’Argentina#,
				'generic' => q#ora d’Argentina#,
				'standard' => q#ora estandarda d’Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#ora d’estiu de l’oèst d’Argentina#,
				'generic' => q#ora de l’oèst d’Argentina#,
				'standard' => q#ora estandarda de l’oèst d’Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ora d’estiu d’Armenia#,
				'generic' => q#ora d’Armenia#,
				'standard' => q#ora estandarda d’Armenia#,
			},
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkòk#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcuta#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dacca#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabol#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sajalin#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapor#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterimburg#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ora d’estiu de l’Atlantic#,
				'generic' => q#ora de l’Atlantic#,
				'standard' => q#ora estandarda de l’Atlantic#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Açòres#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canàries#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cap Verd#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaïda#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#ora d’estiu d’Austràlia centrala#,
				'generic' => q#ora d’Austràlia centrala#,
				'standard' => q#ora estandard d’Austràlia centrala#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#ora d’estiu estandarda d’Austràlia centreoccidentala#,
				'generic' => q#ora d’Austràlia centreoccidentala#,
				'standard' => q#ora estandard d’Austràlia centreoccidentala#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#ora d’estiu d’Austràlia oriental#,
				'generic' => q#ora d’Austràlia oriental#,
				'standard' => q#ora estandard d’Austràlia oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#ora d’estiu d’Austràlia occidental#,
				'generic' => q#ora d’Austràlia occidental#,
				'standard' => q#ora estandard d’Austràlia occidental#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#ora d’estiu d’Azerbaijan#,
				'generic' => q#ora d’Azerbaijan#,
				'standard' => q#ora estandarda d’Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#ora d’estiu de les Açòres#,
				'generic' => q#ora de les Açòres#,
				'standard' => q#ora estandarda de les Açòres#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#ora d’estiu de Bangaldesh#,
				'generic' => q#ora de Bangaldesh#,
				'standard' => q#ora estandarda de Bangaldesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#ora de Butan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#ora de Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#ora d’estiu de Brasilia#,
				'generic' => q#ora de Brasilia#,
				'standard' => q#ora estandarda de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#ora de Brunei#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#ora d’estiu de Cap-Verd#,
				'generic' => q#ora de Cap-Verd#,
				'standard' => q#ora estandarda de Cap-Verd#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#ora estandard de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#ora d’estiu de Chatham#,
				'generic' => q#ora de Chatham#,
				'standard' => q#ora estandard de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#ora d’estiu de Chile#,
				'generic' => q#ora de Chile#,
				'standard' => q#ora estandarda de Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#ora d’estiu de China#,
				'generic' => q#ora de China#,
				'standard' => q#ora estandarda de China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#ora d’estiu de Choibalsan#,
				'generic' => q#ora de Choibalsan#,
				'standard' => q#ora estandarda de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#ora de l’illa de Nadau#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#ora de l’illa de Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#ora d’estiu de Colòmbia#,
				'generic' => q#ora de Colòmbia#,
				'standard' => q#ora estandarda de Colòmbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#ora d’estiu mieja de les Illes Cook#,
				'generic' => q#ora de les Illes Cook#,
				'standard' => q#ora estandard de les Illes Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#ora d’estiu de Cuba#,
				'generic' => q#ora de Cuba#,
				'standard' => q#ora estandarda de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#ora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ora de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#ora de Timòr oriental#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ora d’estiu de la illa de Pascua#,
				'generic' => q#ora de la illa de Pascua#,
				'standard' => q#ora estandarda de la illa de Pascua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ora d’Equator#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ora coordonada universala#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Vila desconeguda#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andòrra#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atenes#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussèlas#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarèst#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapèst#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#ora estandarda irlandesa#,
			},
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbona#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#ora d’estiu britanica#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemborg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mónegue#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscòu#,
		},
		'Europe/Paris' => {
			exemplarCity => q#París#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ora d’estiu d’Euròpa centrala#,
				'generic' => q#ora d’Euròpa centrala#,
				'standard' => q#ora estandarda d’Euròpa centrala#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ora d’estiu d’Euròpa de l’èst#,
				'generic' => q#ora d’Euròpa de l’èst#,
				'standard' => q#ora estandarda d’Euròpa de l’èst#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ora de l’extrem d’Euròpa orientala#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ora d’estiu d’Euròpa de l’oèst#,
				'generic' => q#ora d’Euròpa de l’oèst#,
				'standard' => q#ora estandarda d’Euròpa de l’oèst#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ora d’estiu de les illes Malvinas#,
				'generic' => q#ora de les illes Malvinas#,
				'standard' => q#ora estandarda de les illes Malvinas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#ora d’estiu de Fiji#,
				'generic' => q#ora de Fiji#,
				'standard' => q#ora estandard de Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ora de la Guayana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#ora de les Terres australes e antartiques franceses#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ora al meridian de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ora de Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#ora de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#ora d’estiu de Geòrgia#,
				'generic' => q#ora de Geòrgia#,
				'standard' => q#ora estandarda de Geòrgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#ora de les illes Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#ora d’estiu de l’èst de Groenlandia#,
				'generic' => q#ora de l’èst de Groenlandia#,
				'standard' => q#ora estandarda de l’èst de Groenlandia#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#ora d’estiu de l’oèst de Groenlandia#,
				'generic' => q#ora de l’oèst de Groenlandia#,
				'standard' => q#ora estandarda de l’oèst de Groenlandia#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#ora estandard deth Gòlf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#ora de la Guayana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#ora d’estiu de Hawai-Aleutianes#,
				'generic' => q#ora de Hawai-Aleutianes#,
				'standard' => q#ora estandarda de Hawai-Aleutianes#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#ora d’estiu de Hong Kong#,
				'generic' => q#ora de Hong Kong#,
				'standard' => q#ora estandarda de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#ora d’estiu de Hovd#,
				'generic' => q#ora de Hovd#,
				'standard' => q#ora estandarda de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#ora estandarda de l’India#,
			},
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malvines#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#ora de l’Ocean Indic#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#ora d’Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#hora d’Indonesia centrala#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#hora d’Indonesia orientala#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#hora d’Indonesia occidentala#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ora d’estiu d’Iran#,
				'generic' => q#ora d’Iran#,
				'standard' => q#ora estandarda d’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ora d’estiu d’Irkutsk#,
				'generic' => q#ora d’Irkutsk#,
				'standard' => q#ora estandarda d’Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ora d’estiu d’Israèl#,
				'generic' => q#ora d’Israèl#,
				'standard' => q#ora estandarda d’Israèl#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#ora d’estiu de Japon#,
				'generic' => q#ora de Japon#,
				'standard' => q#ora estandarda de Japon#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#ora de Kazajistan orientala#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#ora de Kazajistan occidenatal#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#ora d’estiu de Corèa#,
				'generic' => q#ora de Corèa#,
				'standard' => q#ora estandarda de Corèa#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#ora de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#ora d’estiu de Krasnoyarsk#,
				'generic' => q#ora de Krasnoyarsk#,
				'standard' => q#ora estandarda de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#ora de Kirguistan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#ora de les Espòrades Equatorials#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#ora d’estiu de Lord Howe#,
				'generic' => q#ora de Lord Howe#,
				'standard' => q#ora estandard de Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#ora de l’illa Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#ora d’estiu de Magadan#,
				'generic' => q#ora de Magadan#,
				'standard' => q#ora estandarda de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#ora de Malàisia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#ora des Malvines#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#ora de les Illes Marqueses#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#ora de les Illes Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ora d’estiu de Maurici#,
				'generic' => q#ora de Maurici#,
				'standard' => q#ora estandarda de Maurici#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#ora de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#ora d’estiu del nòrd-èst de Mexic#,
				'generic' => q#ora del nòrd-èst de Mexic#,
				'standard' => q#ora estandarda del nòrd-èst de Mexic#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#ora d’estiu del Pacific Mexican#,
				'generic' => q#ora del Pacific Mexican#,
				'standard' => q#ora estandarda del Pacific Mexican#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ora d’estiu de Ulan Bator#,
				'generic' => q#ora de Ulan Bator#,
				'standard' => q#ora estandarda de Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ora d’estiu de Moscòu#,
				'generic' => q#ora de Moscòu#,
				'standard' => q#ora estandarda de Moscòu#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#ora de Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#ora de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#ora de Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#ora d’estiu de Nòva Caledònia#,
				'generic' => q#ora de Nòva Caledònia#,
				'standard' => q#ora estandard de Nòva Caledònia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#ora d’estiu de Nòva Zelanda#,
				'generic' => q#ora de Nòva Zelanda#,
				'standard' => q#ora estandard de Nòva Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#ora d’estiu de Terra-Nòva#,
				'generic' => q#ora de Terra-Nòva#,
				'standard' => q#ora estandarda de Terra-Nòva#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#ora de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#ora d’estiu de l’illa Norfolk#,
				'generic' => q#ora de l’illa Norfolk#,
				'standard' => q#ora estandard de l’illa Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ora d’estiu de Fernando Noronha#,
				'generic' => q#ora de Fernando Noronha#,
				'standard' => q#ora estandarda de Fernando Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#ora d’estiu de Novosibirsk#,
				'generic' => q#ora de Novosibirsk#,
				'standard' => q#ora estandarda de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ora d’estiu d’Omsk#,
				'generic' => q#ora d’Omsk#,
				'standard' => q#ora estandarda d’Omsk#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#ora d’estiu de Pakistan#,
				'generic' => q#ora de Pakistan#,
				'standard' => q#ora estandarda de Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#ora de Palaos#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#ora de Papua Nòva Guinèa#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#ora d’estiu de Paraguay#,
				'generic' => q#ora de Paraguay#,
				'standard' => q#ora estandarda de Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#ora d’estiu de Perú#,
				'generic' => q#ora de Perú#,
				'standard' => q#ora estandarda de Perú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#ora d’estiu de Filipines#,
				'generic' => q#ora de Filipines#,
				'standard' => q#ora estandarda de Filipines#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#ora de les Illes Fénix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#ora d’estiu de St. Pierre e Miquelon#,
				'generic' => q#ora de St. Pierre e Miquelon#,
				'standard' => q#ora estandarda de St. Pierre e Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#ora de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ora de Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#ora de Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#ora de la Reünion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#ora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#ora d’estiu de Sajalin#,
				'generic' => q#ora de Sajalin#,
				'standard' => q#ora estandarda de Sajalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#ora d’estiu de Samoa#,
				'generic' => q#ora de Samoa#,
				'standard' => q#ora estandard de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#ora de Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#ora de Singapor#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#ora de les Illes Salomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#ora de Geòrgia del Sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#ora de Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#ora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#ora de Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#ora d’estiu de Taipei#,
				'generic' => q#ora de Taipei#,
				'standard' => q#ora estandarda de Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#ora de Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#ora de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#ora d’estiu de Tonga#,
				'generic' => q#ora de Tonga#,
				'standard' => q#ora estandard de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#ora de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ora d’estiu de Turkmenistan#,
				'generic' => q#ora de Turkmenistan#,
				'standard' => q#ora estandarda de Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#ora de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#ora d’estiu de l’Uruguay#,
				'generic' => q#ora de l’Uruguay#,
				'standard' => q#ora estandarda de l’Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ora d’estiu de Uzbekistan#,
				'generic' => q#ora de Uzbekistan#,
				'standard' => q#ora estandarda de Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#ora d’estiu de Vanuatu#,
				'generic' => q#ora de Vanuatu#,
				'standard' => q#ora estandard de Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#ora de Veneçuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ora d’estiu de Vladivostok#,
				'generic' => q#ora de Vladivostok#,
				'standard' => q#ora estandarda de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#ora d’estiu de Volgograd#,
				'generic' => q#ora de Volgograd#,
				'standard' => q#ora estandarda de Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#ora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ora de l’Illa Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#ora de Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#ora d’estiu de Yakutsk#,
				'generic' => q#ora de Yakutsk#,
				'standard' => q#ora estandarda de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#ora d’estiu d’Ekaterimburg#,
				'generic' => q#ora d’Ekaterimburg#,
				'standard' => q#ora estandarda d’Ekaterimburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#ora de Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
