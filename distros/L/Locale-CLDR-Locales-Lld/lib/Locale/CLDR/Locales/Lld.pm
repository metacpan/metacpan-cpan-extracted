package Locale::CLDR::Locales::Lld;
# This file auto generated from Data\common\main\lld.xml
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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'afar',
 				'ab' => 'abkhasich',
 				'af' => 'afrikaans',
 				'ak' => 'akan',
 				'am' => 'amarich',
 				'an' => 'aragonesc',
 				'ar' => 'arabich',
 				'ar_001' => 'arabich modern standard',
 				'as' => 'assamesc',
 				'az' => 'azerbaijan',
 				'ba' => 'bashkir',
 				'be' => 'belarus',
 				'bg' => 'bulgar',
 				'bm' => 'bambara',
 				'bn' => 'bengalesc',
 				'bo' => 'tibetan',
 				'br' => 'breton',
 				'bs' => 'bosniach',
 				'ca' => 'catalan',
 				'ce' => 'cecen',
 				'chr' => 'cherokee',
 				'co' => 'corsich',
 				'cs' => 'cech',
 				'cu' => 'slav eclesiastich',
 				'cv' => 'ciuvascich',
 				'cy' => 'galesc',
 				'da' => 'danesc',
 				'de' => 'todësch',
 				'de_AT' => 'todësch dl’Austria',
 				'de_CH' => 'todësch standard dla Svizera',
 				'dv' => 'divehi',
 				'dz' => 'dzongkha',
 				'ee' => 'ewe',
 				'el' => 'grech',
 				'en' => 'inglesc',
 				'en_AU' => 'inglesc australian',
 				'en_CA' => 'inglesc canadesc',
 				'en_GB' => 'inglesc (UK)',
 				'en_US' => 'inglesc (USA)',
 				'eo' => 'esperanto',
 				'es' => 'spagnol',
 				'es_419' => 'spagnol latin american',
 				'es_ES' => 'spagnol (ES)',
 				'es_MX' => 'spagnol (MX)',
 				'et' => 'eston',
 				'eu' => 'basch',
 				'fa' => 'persian',
 				'fa_AF' => 'dari',
 				'ff' => 'fula',
 				'fi' => 'finlandesc',
 				'fil' => 'filipin',
 				'fo' => 'faroesc',
 				'fr' => 'franzesc',
 				'fr_CA' => 'franzesc (CA)',
 				'fr_CH' => 'franzesc (CH)',
 				'fur' => 'furlan',
 				'fy' => 'frison dl vest',
 				'ga' => 'irlandesc',
 				'gd' => 'gaelich scozesc',
 				'gl' => 'galizian',
 				'gn' => 'guaraní',
 				'gu' => 'gujarati',
 				'gv' => 'manx',
 				'ha' => 'haussa',
 				'he' => 'ebraich',
 				'hi' => 'hindi',
 				'hi_Latn' => 'hindi (latin)',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hr' => 'croat',
 				'hu' => 'ungaresc',
 				'hy' => 'armenich',
 				'ia' => 'interlingua',
 				'id' => 'indonesian',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'io' => 'ido',
 				'is' => 'islandesc',
 				'it' => 'talian',
 				'iu' => 'inuktitut',
 				'ja' => 'iapanesc',
 				'jv' => 'giavanesc',
 				'ka' => 'georgian',
 				'kgp' => 'kaingang',
 				'ki' => 'kikuyu',
 				'kk' => 'kazakh',
 				'kl' => 'groenlandesc',
 				'km' => 'khmer',
 				'kn' => 'kannada',
 				'ko' => 'corean',
 				'ks' => 'kashmiri',
 				'ku' => 'curdich',
 				'kw' => 'cornich',
 				'ky' => 'kyrgyz',
 				'la' => 'latin',
 				'lb' => 'lussemburghesc',
 				'lg' => 'ganda',
 				'lld' => 'ladin',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lt' => 'lituan',
 				'lu' => 'luba-katanga',
 				'lv' => 'leton',
 				'mg' => 'malgasich',
 				'mi' => 'maori',
 				'mk' => 'macedonich',
 				'ml' => 'malayalam',
 				'mn' => 'mongolich',
 				'mr' => 'marathi',
 				'ms' => 'malesc',
 				'mt' => 'maltesc',
 				'my' => 'birmanich',
 				'nb' => 'norvegesc bokmål',
 				'nd' => 'ndebele dl nord',
 				'ne' => 'nepalesc',
 				'nl' => 'neerlandesc',
 				'nl_BE' => 'flamesc',
 				'nn' => 'norvegesc nynorsk',
 				'no' => 'norvegesc',
 				'nr' => 'ndebele dl süd',
 				'nv' => 'navajan',
 				'ny' => 'nyanja',
 				'oc' => 'ocitan',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'ossetich',
 				'pa' => 'punjabi',
 				'pl' => 'polach',
 				'ps' => 'pashto',
 				'pt' => 'portoghesc',
 				'pt_BR' => 'portoghesc (BR)',
 				'pt_PT' => 'portoghesc (PT)',
 				'qu' => 'quechua',
 				'rm' => 'rumanc',
 				'rn' => 'rundi',
 				'ro' => 'rumen',
 				'ro_MD' => 'moldavich',
 				'ru' => 'rus',
 				'rw' => 'kinyarwanda',
 				'sa' => 'sanscrit',
 				'sc' => 'sard',
 				'sd' => 'sindhi',
 				'se' => 'sami dl nord',
 				'sg' => 'sango',
 				'si' => 'singalesc',
 				'sk' => 'slovach',
 				'sl' => 'sloven',
 				'sn' => 'shona',
 				'so' => 'somalich',
 				'sq' => 'albanesc',
 				'sr' => 'serb',
 				'ss' => 'swati',
 				'st' => 'sotho dl süd',
 				'su' => 'sundanesc',
 				'sv' => 'svedesc',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili dl Congo',
 				'ta' => 'tamilich',
 				'te' => 'telugu',
 				'tg' => 'tajich',
 				'th' => 'thailandesc',
 				'ti' => 'tigrin',
 				'tk' => 'turcmenich',
 				'tn' => 'tswana',
 				'to' => 'tongaich',
 				'tr' => 'türch',
 				'ts' => 'tsonga',
 				'tt' => 'tatarich',
 				'ug' => 'uigurich',
 				'uk' => 'ucrainich',
 				'und' => 'lingaz nia conesciü',
 				'ur' => 'urdu',
 				'uz' => 'uzbech',
 				've' => 'venda',
 				'vi' => 'vietnamesc',
 				'vo' => 'volapük',
 				'wa' => 'valonesc',
 				'wo' => 'wolof',
 				'xh' => 'xhosa',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'za' => 'zhuang',
 				'zh' => 'cinesc',
 				'zh@alt=menu' => 'cinesc (mandarin)',
 				'zh_Hans' => 'cinesc scemplifiché',
 				'zh_Hans@alt=long' => 'cinesc mandarin scemplifiché',
 				'zh_Hant' => 'cinesc tradizional',
 				'zh_Hant@alt=long' => 'cinesc mandarin tradizional',
 				'zu' => 'zulu',

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
			'Arab' => 'arabich',
 			'Cyrl' => 'zirilich',
 			'Hans' => 'scemplifiché',
 			'Hans@alt=stand-alone' => 'cinesc han scemplifiché',
 			'Hant' => 'tradizional',
 			'Hant@alt=stand-alone' => 'cinesc han tradizional',
 			'Jpan' => 'iapanesc',
 			'Kore' => 'corean',
 			'Latn' => 'latin',
 			'Zxxx' => 'nia scrit',
 			'Zzzz' => 'scritöra nia conesciüda',

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
			'001' => 'monn',
 			'002' => 'Africa',
 			'003' => 'Nord America',
 			'005' => 'America dl Süd',
 			'009' => 'Ozeania',
 			'011' => 'Africa ozidentala',
 			'013' => 'America Zentrala',
 			'014' => 'Africa orientala',
 			'015' => 'Africa dl Nord',
 			'017' => 'Africa zentrala',
 			'018' => 'Africa dl Süd',
 			'019' => 'Americhes',
 			'021' => 'America dl Nord',
 			'029' => 'Caraibi',
 			'030' => 'Asia orientala',
 			'034' => 'Asia dl Süd',
 			'035' => 'Asia dl Süd-Ost',
 			'039' => 'Europa dl Süd',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Isoles dla Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia zentrala',
 			'145' => 'Asia ozidentala',
 			'150' => 'Europa',
 			'151' => 'Europa orientala',
 			'154' => 'Europa dl Nord',
 			'155' => 'Europa ozidentala',
 			'202' => 'Africa sot-sahariana',
 			'419' => 'America latina',
 			'AC' => 'Isola dl’Ascensiun',
 			'AD' => 'Andorra',
 			'AE' => 'Emirac Arabics Unis',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua y Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antartida',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Isoles Åland',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia y Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesc',
 			'BE' => 'Belgio',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caraibi olandesc',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Isola Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belaruscia',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Isoles Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (Republica Democratica)',
 			'CF' => 'Republica Zentrafricana',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Congo (Republica)',
 			'CH' => 'Svizera',
 			'CI' => 'Costa d’Avore',
 			'CK' => 'Isoles Cook',
 			'CL' => 'Cile',
 			'CM' => 'Camerun',
 			'CN' => 'Cina',
 			'CO' => 'Colombia',
 			'CP' => 'Isola de Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Capo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Isola dl Nadé',
 			'CY' => 'Ziper',
 			'CZ' => 'Cechia',
 			'CZ@alt=variant' => 'Repubblica Ceca',
 			'DE' => 'Paisc Todësc',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danimarca',
 			'DM' => 'Dominica',
 			'DO' => 'Republica Dominicana',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta y Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egit',
 			'EH' => 'Sahara ozidentala',
 			'ER' => 'Eritrea',
 			'ES' => 'Spagna',
 			'ET' => 'Etiopia',
 			'EU' => 'Uniun Europeica',
 			'EZ' => 'Zona Euro',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fiji',
 			'FK' => 'Isoles Falkland',
 			'FK@alt=variant' => 'Isoles Falkland (Isoles Malvines)',
 			'FM' => 'Micronesia',
 			'FO' => 'Isoles Faroer',
 			'FR' => 'Francia',
 			'GA' => 'Gabun',
 			'GB' => 'Rëgn Uní',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guiana franzeja',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinea ecuatoriala',
 			'GR' => 'Grecia',
 			'GS' => 'Georgia dl Süd y Isoles Sandwich dl Süd',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Regiun aministrativa speziala de Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Isoles Heard y McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croazia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungaria',
 			'IC' => 'Isoles Canaries',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Isola de Man',
 			'IN' => 'India',
 			'IO' => 'Teritore britanich dl Ozean Indian',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islanda',
 			'IT' => 'Talia',
 			'JE' => 'Jersey',
 			'JM' => 'Giamaica',
 			'JO' => 'Iordania',
 			'JP' => 'Iapan',
 			'KE' => 'Kenia',
 			'KG' => 'Kyrgystan',
 			'KH' => 'Cambogia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comores',
 			'KN' => 'St. Kitts y Nevis',
 			'KP' => 'Corea dl Nord',
 			'KR' => 'Corea dl Süd',
 			'KW' => 'Kuwait',
 			'KY' => 'Isoles Cayman',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Lussemburgh',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Maroco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Isoles Marshall',
 			'MK' => 'Macedonia dl Nord',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Regiun aministrativa speziala de Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Isoles Marianes dl Nord',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Messich',
 			'MY' => 'Malesia',
 			'MZ' => 'Mozambich',
 			'NA' => 'Namibia',
 			'NC' => 'Nöia Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Isola Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Paisc Basc',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nöia Zelanda',
 			'NZ@alt=variant' => 'Aotearoa (Nöia Zelanda)',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Perú',
 			'PF' => 'Polinesia franzeja',
 			'PG' => 'Papua Nöia Guinea',
 			'PH' => 'Filipines',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'St. Pierre y Miquelon',
 			'PN' => 'Isoles Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Teritori palestinesc',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Ozeania dlafora',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Ruscia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudita',
 			'SB' => 'Isoles Salomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Svezia',
 			'SG' => 'Singapur',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard y Jan Mayen',
 			'SK' => 'Slovachia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudan dl Süd',
 			'ST' => 'São Tomé y Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Isoles Turks y Caicos',
 			'TD' => 'Ciad',
 			'TF' => 'Teritori franzesc dl Süd y dl’Antartica',
 			'TG' => 'Togo',
 			'TH' => 'Thailandia',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor Ost',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turchia',
 			'TT' => 'Trinidad y Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganda',
 			'UM' => 'Isoles mëndres dlafora di Stac Unis',
 			'UN' => 'Naziuns Unides',
 			'US' => 'Stac Unis',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Cité dl Vatican',
 			'VC' => 'St. Vincent y Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Isoles Vergines britaniches',
 			'VI' => 'Isoles Vergines americanes',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis y Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-azënc',
 			'XB' => 'Pseudo-bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Südafrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Raiun nia conesciü',

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
 				'gregorian' => q{Calënder gregorian},
 				'iso8601' => q{Calënder ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{Ordinamënt standard},
 			},
 			'numbers' => {
 				'latn' => q{Zifres ozidentales},
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
			'metric' => q{metrich},
 			'UK' => q{Gran Bretagna},
 			'US' => q{Stac Unis},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lingaz: {0}',
 			'script' => 'Scritöra: {0}',
 			'region' => 'Area geografica: {0}',

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
			auxiliary => qr{[ăåäãąā ĉčċç ð ěėē ğ ìïī ńňñ òŏőõō ŕř śŝş ß ùûůűū ýÿ źžż]},
			main => qr{[aáàâ b cć d eéèêë f g h iíî j k l m n oóôö p q r s t uúü v w x y z]},
			numbers => qr{[\- ‑ . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ , ; \: ! ? . '’ “”„ « » ( ) \[ \] \{ \} @ * / \& # < >]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punt cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punt cardinal),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nord),
						'south' => q({0} süd),
						'west' => q({0} vest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nord),
						'south' => q({0} süd),
						'west' => q({0} vest),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direziun),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direziun),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direziun),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direziun),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
						'west' => q({0}V),
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

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'one' => 'mile',
					'other' => '0 mile',
				},
				'10000' => {
					'one' => '00 mile',
					'other' => '00 mile',
				},
				'100000' => {
					'one' => '000 mile',
					'other' => '000 mile',
				},
				'1000000' => {
					'one' => '0 miliun',
					'other' => '0 miliuns',
				},
				'10000000' => {
					'one' => '00 miliuns',
					'other' => '00 miliuns',
				},
				'100000000' => {
					'one' => '000 miliuns',
					'other' => '000 miliuns',
				},
				'1000000000' => {
					'one' => '0 miliard',
					'other' => '0 miliarg',
				},
				'10000000000' => {
					'one' => '00 miliarg',
					'other' => '00 miliarg',
				},
				'100000000000' => {
					'one' => '000 miliarg',
					'other' => '000 miliarg',
				},
				'1000000000000' => {
					'one' => '0 biliun',
					'other' => '0 biliuns',
				},
				'10000000000000' => {
					'one' => '00 biliuns',
					'other' => '00 biliuns',
				},
				'100000000000000' => {
					'one' => '000 biliuns',
					'other' => '000 biliuns',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0m',
					'other' => '0m',
				},
				'10000' => {
					'one' => '00m',
					'other' => '00m',
				},
				'100000' => {
					'one' => '000m',
					'other' => '000m',
				},
				'1000000' => {
					'one' => '0 Mln',
					'other' => '0 Mln',
				},
				'10000000' => {
					'one' => '00 Mln',
					'other' => '00 Mln',
				},
				'100000000' => {
					'one' => '000 Mln',
					'other' => '000 Mln',
				},
				'1000000000' => {
					'one' => '0 Mlg',
					'other' => '0 Mlg',
				},
				'10000000000' => {
					'one' => '00 Mlg',
					'other' => '00 Mlg',
				},
				'100000000000' => {
					'one' => '000 Mlg',
					'other' => '000 Mlg',
				},
				'1000000000000' => {
					'one' => '0 Bln',
					'other' => '0 Bln',
				},
				'10000000000000' => {
					'one' => '00 Bln',
					'other' => '00 Bln',
				},
				'100000000000000' => {
					'one' => '000 Bln',
					'other' => '000 Bln',
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
						'positive' => '#,##0.00 ¤',
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
		'AED' => {
			display_name => {
				'currency' => q(Dirham di Emirac Arabics Unis),
				'one' => q(dirham di EAU),
				'other' => q(dirhams di EAU),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani dl Afghanistan),
				'one' => q(Afghani dl Afghanistan),
				'other' => q(Afghanis dl Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek dl’Albania),
				'one' => q(lek dl’Albania),
				'other' => q(lekë dl’Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram dl’Armenia),
				'one' => q(dram dl’Armenia),
				'other' => q(drams dl’Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Rainesc dles Antiles neerlandejes),
				'one' => q(rainesc dles Antiles neerlandejes),
				'other' => q(rainesc dles Antiles neerlandejes),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza dl Angola),
				'one' => q(kwanza dl Angola),
				'other' => q(kwanzas dl Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso dl’Argentina),
				'one' => q(peso dl’Argentina),
				'other' => q(pesos dl’Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolar dl’Australia),
				'one' => q(dolar dl’Australia),
				'other' => q(dolars dl’Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin d’Aruba),
				'one' => q(florin d’Aruba),
				'other' => q(florins d’Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat dl Azerbaijan),
				'one' => q(manat dl Azerbaijan),
				'other' => q(manats dl Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(March convertibl dla Bosnia y Herzegovina),
				'one' => q(march convertibl dla Bosnia y Herzegovina),
				'other' => q(marcs convertibli dla Bosnia y Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dolar de Barbados),
				'one' => q(dolar de Barbados),
				'other' => q(dolars de Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka dl Bangladesc),
				'one' => q(taka dl Bangladesc),
				'other' => q(takas dl Bangladesc),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev dla Bulgaria),
				'one' => q(lev dla Bulgaria),
				'other' => q(levs dla Bulgaria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar dl Bahrain),
				'one' => q(dinar dl Bahrain),
				'other' => q(dinars dl Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franch dl Burundi),
				'one' => q(franch dl Burundi),
				'other' => q(francs dl Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermudan Dollar),
				'one' => q(dolar dles Bermuda),
				'other' => q(dolars dles Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dolar dl Brunei),
				'one' => q(dolar dl Brunei),
				'other' => q(dolars dl Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano dla Bolivia),
				'one' => q(boliviano dla Bolivia),
				'other' => q(bolivianos dla Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real dl Brasil),
				'one' => q(real dl Brasil),
				'other' => q(reai dl Brasil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dolar dles Bahamas),
				'one' => q(dolar dles Bahamas),
				'other' => q(dolars dles Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum dl Bhutan),
				'one' => q(ngultrum dl Bhutan),
				'other' => q(ngultrums dl Bhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula dl Botswana),
				'one' => q(pula dl Botswana),
				'other' => q(pulas dl Botswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rubl dla Belaruscia),
				'one' => q(rubl dla Belaruscia),
				'other' => q(rubli dla Belaruscia),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dolar dl Belize),
				'one' => q(dolar dl Belize),
				'other' => q(dolars dl Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolar dl Canada),
				'one' => q(dolar dl Canada),
				'other' => q(dolars dl Canada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franch dl Congo),
				'one' => q(franch dl Congo),
				'other' => q(francs dl Congo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franch dla Svizera),
				'one' => q(franch dla Svizera),
				'other' => q(francs dla Svizera),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso dl Cile),
				'one' => q(peso dl Cile),
				'other' => q(pesos dl Cile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan dla Cina \(offshore\)),
				'one' => q(yuan dla Cina \(offshore\)),
				'other' => q(yuans dla Cina \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan dla Cina),
				'one' => q(yuan dla Cina),
				'other' => q(yuans dla Cina),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso dla Colombia),
				'one' => q(peso dla Colombia),
				'other' => q(pesos dla Colombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón dl Costa Rica),
				'one' => q(colón dl Costa Rica),
				'other' => q(colóns dl Costa Rica),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso convertibl de Cuba),
				'one' => q(peso convertibl de Cuba),
				'other' => q(pesos convertibli de Cuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso de Cuba),
				'one' => q(peso de Cuba),
				'other' => q(pesos de Cuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo de Capo Verde),
				'one' => q(escudo de Capo Verde),
				'other' => q(escudos de Capo Verde),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Corona dla Cechia),
				'one' => q(corona dla Cechia),
				'other' => q(corones dla Cechia),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franch dl Djibouti),
				'one' => q(franch dl Djibouti),
				'other' => q(francs dl Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Corona dla Danimarca),
				'one' => q(corona dla Danimarca),
				'other' => q(corones dla Danimarca),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso dla Republica Dominicana),
				'one' => q(peso dla Republica Dominicana),
				'other' => q(pesos dla Republica Dominicana),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar dl’Algeria),
				'one' => q(dinar dl’Algeria),
				'other' => q(dinars dl’Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Sterlina dl Egit),
				'one' => q(sterlina dl Egit),
				'other' => q(sterlines dl Egit),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa dl’Eritrea),
				'one' => q(nakfa dl’Eritrea),
				'other' => q(nakfas dl’Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr dl’Etiopia),
				'one' => q(birr dl’Etiopia),
				'other' => q(birrs dl’Etiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dolar dles Fiji),
				'one' => q(dolar dles Fiji),
				'other' => q(dolars dles Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Sterlina dles Isoles Falkland),
				'one' => q(sterlina dles Isoles Falkland),
				'other' => q(sterlines dles Isoles Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Sterlina Britanica),
				'one' => q(sterlina britanica),
				'other' => q(sterlines britaniches),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari dla Georgia),
				'one' => q(lari dla Georgia),
				'other' => q(laris dla Georgia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi dl Ghana),
				'one' => q(cedi dl Ghana),
				'other' => q(cedis dl Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Sterlina de Gibiltera),
				'one' => q(sterlina de Gibiltera),
				'other' => q(sterlines de Gibiltera),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi dl Gambia),
				'one' => q(dalasi dl Gambia),
				'other' => q(dalasis dl Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franch dla Guinea),
				'one' => q(franch dla Guinea),
				'other' => q(francs dla Guinea),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal dl Guatemala),
				'one' => q(quetzal dl Guatemala),
				'other' => q(quetzai dl Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dolar dla Guyana),
				'one' => q(dolar dla Guyana),
				'other' => q(dolars dla Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dolar de Hong Kong),
				'one' => q(dolar de Hong Kong),
				'other' => q(dolars de Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira dl Honduras),
				'one' => q(lempira dl Honduras),
				'other' => q(lempiras dl Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna dla Croazia),
				'one' => q(kuna dla Croazia),
				'other' => q(kunas dla Croazia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde de Haiti),
				'one' => q(gourde de Haiti),
				'other' => q(gourdes de Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint dl’Ungaria),
				'one' => q(forint dl’Ungaria),
				'other' => q(forints dl’Ungaria),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupia dla Indonesia),
				'one' => q(rupia dla Indonesia),
				'other' => q(rupies dla Indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Shekel Nü d’Israel),
				'one' => q(shekel nü d’Israel),
				'other' => q(shekli nüs d’Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupia dl’India),
				'one' => q(rupia dl’India),
				'other' => q(rupies dl’India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar dl Irak),
				'one' => q(dinar dl Irak),
				'other' => q(dinars dl Irak),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial dl Iran),
				'one' => q(rial dl Iran),
				'other' => q(riai dl Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Corona dl’Islanda),
				'one' => q(corona dl’Islanda),
				'other' => q(corones dl’Islanda),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolar dla Giamaica),
				'one' => q(dolar dla Giamaica),
				'other' => q(dolars dla Giamaica),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar dla Iordania),
				'one' => q(dinar dla Iordania),
				'other' => q(dinars dla Iordania),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen dl Iapan),
				'one' => q(yen dl Iapan),
				'other' => q(yens dl Iapan),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilling dl Kenia),
				'one' => q(shilling dl Kenia),
				'other' => q(shillings dl Kenia),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som dl Kyrgystan),
				'one' => q(som dl Kyrgystan),
				'other' => q(soms dl Kyrgystan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel dla Cambogia),
				'one' => q(riel dla Cambogia),
				'other' => q(riei dla Cambogia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franch dles Comores),
				'one' => q(franch dles Comores),
				'other' => q(francs dles Comores),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won dla Corea dl Nord),
				'one' => q(won dla Corea dl Nord),
				'other' => q(wons dla Corea dl Nord),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won dla Corea dl Süd),
				'one' => q(won dla Corea dl Süd),
				'other' => q(wons dla Corea dl Süd),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar dl Kuwait),
				'one' => q(dinar dl Kuwait),
				'other' => q(dinars dl Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dolar dles Isoles Cayman),
				'one' => q(dolar dles Isoles Cayman),
				'other' => q(dolars dles Isoles Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge dl Kazakhstan),
				'one' => q(tenge dl Kazakhstan),
				'other' => q(tenges dl Kazakhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip dl Laos),
				'one' => q(kip dl Laos),
				'other' => q(kips dl Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Lira dl Libanon),
				'one' => q(lira dl Libanon),
				'other' => q(lires dl Libanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupia dl Sri Lanka),
				'one' => q(rupia dl Sri Lanka),
				'other' => q(rupies dl Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolar dla Liberia),
				'one' => q(dolar dla Liberia),
				'other' => q(dolars dla Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti dl Lesotho),
				'one' => q(loti dl Lesotho),
				'other' => q(lotis dl Lesotho),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar dla Libia),
				'one' => q(dinar dla Libia),
				'other' => q(dinars dla Libia),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham dl Maroco),
				'one' => q(dirham dl Maroco),
				'other' => q(dirhams dl Maroco),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu dla Moldavia),
				'one' => q(leu dla Moldavia),
				'other' => q(lei dla Moldavia),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary dl Madagascar),
				'one' => q(ariary dl Madagascar),
				'other' => q(ariarys dl Madagascar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar dla Macedonia),
				'one' => q(denar dla Macedonia),
				'other' => q(denars dla Macedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat dl Myanmar),
				'one' => q(kyat dl Myanmar),
				'other' => q(kyats dl Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik dla Mongolia),
				'one' => q(tugrik dla Mongolia),
				'other' => q(tugriks dla Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca de Macao),
				'one' => q(pataca de Macao),
				'other' => q(pataches de Macao),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya dla Mauritania),
				'one' => q(ouguiya dla Mauritania),
				'other' => q(ouguiyas dla Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia de Mauritius),
				'one' => q(rupia de Mauritius),
				'other' => q(rupies de Mauritius),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa dles Maldives),
				'one' => q(rufiyaa dles Maldives),
				'other' => q(rufiyaas dles Maldives),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha dl Malawi),
				'one' => q(kwacha dl Malawi),
				'other' => q(kwachas dl Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso dl Messich),
				'one' => q(peso dl Messich),
				'other' => q(pesos dl Messich),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit dla Malesia),
				'one' => q(ringgit dla Malesia),
				'other' => q(ringgits dla Malesia),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical dl Mozambich),
				'one' => q(metical dl Mozambich),
				'other' => q(meticai dl Mozambich),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolar dla Namibia),
				'one' => q(dolar dla Namibia),
				'other' => q(dolars dla Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira dl Nigeria),
				'one' => q(naira dl Nigeria),
				'other' => q(nairas dl Nigeria),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Cordoba dl Nicaragua),
				'one' => q(cordoba dl Nicaragua),
				'other' => q(cordobas dl Nicaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Corona dla Norvegia),
				'one' => q(corona dla Norvegia),
				'other' => q(corones dla Norvegia),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupia dl Nepal),
				'one' => q(rupia dl Nepal),
				'other' => q(rupes dl Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dolar dla Nöia Zelanda),
				'one' => q(dolar dla Nöia Zelanda),
				'other' => q(dolars dla Nöia Zelanda),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial dl Oman),
				'one' => q(rial dl Oman),
				'other' => q(riai dl Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa de Panama),
				'one' => q(balboa de Panama),
				'other' => q(balboas de Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol dl Perú),
				'one' => q(sol dl Perú),
				'other' => q(soles dl Perú),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina dla Papua Nöia Guinea),
				'one' => q(kina dla Papua Nöia Guinea),
				'other' => q(kinas dla Papua Nöia Guinea),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Peso dles Filipines),
				'one' => q(peso dles Filipines),
				'other' => q(pesos dles Filipines),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupia dl Pakistan),
				'one' => q(rupia dl Pakistan),
				'other' => q(rupies dl Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty dla Polonia),
				'one' => q(zloty dla Polonia),
				'other' => q(zlotys dla Polonia),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guaraní dl Paraguay),
				'one' => q(guaraní dl Paraguay),
				'other' => q(guaranis dl Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial dl Qatar),
				'one' => q(rial dl Qatar),
				'other' => q(riai dl Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu dla Romania),
				'one' => q(leu dla Romania),
				'other' => q(lei dla Romania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar dla Serbia),
				'one' => q(dinar dla Serbia),
				'other' => q(dinars dla Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubl dla Ruscia),
				'one' => q(rubl dla Ruscia),
				'other' => q(rubli dla Ruscia),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franch dla Ruanda),
				'one' => q(franch dla Ruanda),
				'other' => q(francs dla Ruanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Rial dl’Arabia Saudita),
				'one' => q(rial dl’Arabia Saudita),
				'other' => q(riai dl’Arabia Saudita),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dolar dles Isoles Salomon),
				'one' => q(dolar dles Isoles Salomon),
				'other' => q(dolars dles Isoles Salomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia dles Seychelles),
				'one' => q(rupia dles Seychelles),
				'other' => q(rupies dles Seychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sterlina dl Sudan),
				'one' => q(sterlina dl Sudan),
				'other' => q(sterlines dl Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Corona dla Svezia),
				'one' => q(corona dla Svezia),
				'other' => q(corones dla Svezia),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dolar de Singapur),
				'one' => q(dolar de Singapur),
				'other' => q(dolars de Singapur),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Sterlina de St. Helena),
				'one' => q(sterlina de St. Helena),
				'other' => q(sterlines de St. Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone dla Sierra Leone),
				'one' => q(leone dla Sierra Leone),
				'other' => q(leones dla Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone dla Sierra Leone \(1964–2022\)),
				'one' => q(leone dla Sierra Leone \(1964–2022\)),
				'other' => q(leones dla Sierra Leone \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilling dla Somalia),
				'one' => q(shilling dla Somalia),
				'other' => q(shillings dla Somalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dolar dl Surinam),
				'one' => q(dolar dl Surinam),
				'other' => q(dolars dl Surinam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Sterlina dl Sudan dl Süd),
				'one' => q(sterlina dl Sudan dl Süd),
				'other' => q(sterlines dl Sudan dl Süd),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra de São Tomé y Príncipe),
				'one' => q(dobra de São Tomé y Príncipe),
				'other' => q(dobras de São Tomé y Príncipe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Lira dla Siria),
				'one' => q(lira dla Siria),
				'other' => q(lira dla Siria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni dl Eswatini),
				'one' => q(lilangeni dl Eswatini),
				'other' => q(emalangeni dl Eswatini),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Bath dla Thailandia),
				'one' => q(bath dla Thailandia),
				'other' => q(baths dla Thailandia),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni dl Tajikistan),
				'one' => q(somoni dl Tajikistan),
				'other' => q(somonis dl Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat dl Turkmenistan),
				'one' => q(manat dl Turkmenistan),
				'other' => q(manats dl Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar dla Tunisia),
				'one' => q(dinar dla Tunisia),
				'other' => q(dinars dla Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga dl Tonga),
				'one' => q(paʻanga dl Tonga),
				'other' => q(paʻangas dl Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira türca),
				'one' => q(lira türca),
				'other' => q(lires türches),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dolar de Trinidad y Tobago),
				'one' => q(dolar de Trinidad y Tobago),
				'other' => q(dolars Trinidad y Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dolar Nü dl Taiwan),
				'one' => q(dolar nü dl Taiwan),
				'other' => q(dolars nüs dl Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilling dla Tanzania),
				'one' => q(shilling dla Tanzania),
				'other' => q(shillings dla Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Grivnia dl’Ucraina),
				'one' => q(grivnia dl’Ucraina),
				'other' => q(grivnias dl’Ucraina),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilling dl’Uganda),
				'one' => q(shilling dl’Uganda),
				'other' => q(shillings dl’Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolar di USA),
				'one' => q(dolar di USA),
				'other' => q(dolars di USA),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso dl Uruguay),
				'one' => q(peso dl Uruguay),
				'other' => q(pesos dl Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Sum dl Uzbekistan),
				'one' => q(sum dl Uzbekistan),
				'other' => q(sums dl Uzbekistan),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar dl Venezuela),
				'one' => q(bolivar dl Venezuela),
				'other' => q(bolivars dl Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong dl Vietnam),
				'one' => q(dong dl Vietnam),
				'other' => q(dongs dl Vietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu de Vanuatu),
				'one' => q(vatu de Vanuatu),
				'other' => q(vatus de Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala de Samoa),
				'one' => q(tala de Samoa),
				'other' => q(tala de Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franch CFA dl’Africa zentrala),
				'one' => q(franch CFA dl’Africa zentrala),
				'other' => q(francs CFA dl’Africa zentrala),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolar di Caraibi orientai),
				'one' => q(dolar di Caraibi orientai),
				'other' => q(dolars di Caraibi orientai),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franch CFA dl’Africa ozidentala),
				'one' => q(franch CFA dl’Africa ozidentala),
				'other' => q(francs CFA dl’Africa ozidentala),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franch CFP),
				'one' => q(franch CFP),
				'other' => q(francs CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Valüta nia conesciüda),
				'one' => q(\(monëda nia conesciüda\)),
				'other' => q(\(valüta nia conesciüda\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial dl Yemen),
				'one' => q(rial dl Yemen),
				'other' => q(riai dl Yemen),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand dl Südafrica),
				'one' => q(rand dl Südafrica),
				'other' => q(rands dl Südafrica),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha dl Zambia),
				'one' => q(kwacha dl Zambia),
				'other' => q(kwachas dl Zambia),
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
							'de jená',
							'de forá',
							'de merz',
							'd’aurí',
							'de ma',
							'de jügn',
							'de messé',
							'd’aost',
							'de set',
							'd’oto',
							'de nov',
							'de dez'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'M',
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
							'de jená',
							'de forá',
							'de merz',
							'd’aurí',
							'de ma',
							'de jügn',
							'de messé',
							'd’aost',
							'de setëmber',
							'd’otober',
							'de novëmber',
							'de dezëmber'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jená',
							'forá',
							'merz',
							'aurí',
							'ma',
							'jügn',
							'messé',
							'aost',
							'set',
							'oto',
							'nov',
							'dez'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'M',
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
							'jená',
							'forá',
							'merz',
							'aurí',
							'ma',
							'jügn',
							'messé',
							'aost',
							'setëmber',
							'otober',
							'novëmber',
							'dezëmber'
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
						mon => 'lön',
						tue => 'mert',
						wed => 'merc',
						thu => 'jöb',
						fri => 'vën',
						sat => 'sab',
						sun => 'dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'lön',
						tue => 'mert',
						wed => 'merc',
						thu => 'jöb',
						fri => 'vën',
						sat => 'sab',
						sun => 'dom'
					},
					wide => {
						mon => 'lönesc',
						tue => 'mertesc',
						wed => 'mercui',
						thu => 'jöbia',
						fri => 'vëndres',
						sat => 'sabeda',
						sun => 'domënia'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'lön',
						tue => 'mert',
						wed => 'merc',
						thu => 'jöb',
						fri => 'vën',
						sat => 'sab',
						sun => 'dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'lön',
						tue => 'mert',
						wed => 'merc',
						thu => 'jöb',
						fri => 'vën',
						sat => 'sab',
						sun => 'dom'
					},
					wide => {
						mon => 'lönesc',
						tue => 'mertesc',
						wed => 'mercui',
						thu => 'jöbia',
						fri => 'vëndres',
						sat => 'sabeda',
						sun => 'domënia'
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
					wide => {0 => 'pröm trimester',
						1 => 'secundo trimester',
						2 => 'terzo trimester',
						3 => 'cuarto trimester'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					wide => {0 => 'pröm trimester',
						1 => 'secundo trimester',
						2 => 'terzo trimester',
						3 => 'cuarto trimester'
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
				'0' => 'dan G.C.',
				'1' => 'AD'
			},
			wide => {
				'0' => 'dan Gejú Crist',
				'1' => 'A.D.'
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
			'full' => q{EEEE, d MMMM 'dl' y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM 'dl' y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd.MM.yy},
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
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
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
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, 'ai' d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d.M.y GGGGG},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			h => q{hh a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y GGGGG},
			yyyyMEd => q{E, d.M.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM 'dl' y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d.M.y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d.M.y GGGGG},
			MEd => q{E, d.M.},
			MMMEd => q{E, d MMM},
			MMMMW => q{'edema' W MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d.M.},
			yM => q{MM.y},
			yMEd => q{E, d.M.y},
			yMMM => q{LLL y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL y},
			yMMMd => q{d MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'edema' w 'dl' Y},
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
			GyM => {
				M => q{M.y – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.M.y – E, d.M.y GGGGG},
				M => q{E, d.M.y – E, d.M.y GGGGG},
				d => q{E, d.M.y – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
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
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d.M.y – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, dd – E, dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y G},
				d => q{dd–dd MMM y G},
				y => q{dd MMM y – dd MMM y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM.y GGGGG – MM.y GGGGG},
				M => q{MM.y – MM.y GGGGG},
				y => q{MM.y – MM.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.M.y – E, d.M.y GGGGG},
				M => q{E, d.M.y – E, d.M.y GGGGG},
				d => q{E, d.M.y – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
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
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d.M.y – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{LLL–LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d – E, d MMM y},
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
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Ora: {0}),
		regionFormat => q(Ora da d’isté: {0}),
		regionFormat => q(Ora standard: {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Ora dl Afghanistan#,
			},
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daressalam#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Ora dl’Africa zentrala#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora dl’Africa orientala#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ora dl’Africa dl Süd#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Africa ozidentala#,
				'generic' => q#Ora dl’Africa ozidentala#,
				'standard' => q#Ora standard dl’Africa ozidentala#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Alaska#,
				'generic' => q#Ora dl’Alaska#,
				'standard' => q#Ora standard dl’Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Amazonia#,
				'generic' => q#Ora dl’Amazonia#,
				'standard' => q#Ora standard dl’Amazonia#,
			},
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Giamaica#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Cité dl Messich#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota dl Nord#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota dl Nord#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota dl Nord#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Iakutat#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ora da d’isté dl’America dl Nord zentrala#,
				'generic' => q#Ora dl’America dl Nord zentrala#,
				'standard' => q#Ora standard dl’America dl Nord zentrala#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ora da d’isté dl’America dl Nord orientala#,
				'generic' => q#Ora dl’America dl Nord orientala#,
				'standard' => q#Ora standard dl’America dl Nord orientala#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ora da d’isté dles Rocky Mountains#,
				'generic' => q#Ora dles Rocky Mountains#,
				'standard' => q#Ora standard dles Rocky Mountains#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ora da d’isté dl’America dl Nord ozidentala#,
				'generic' => q#Ora dl’America dl Nord ozidentala#,
				'standard' => q#Ora standard dl’America dl Nord ozidentala#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Ora da d’isté de Apia#,
				'generic' => q#Ora de Apia#,
				'standard' => q#Ora standard de Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Arabia#,
				'generic' => q#Ora dl’Arabia#,
				'standard' => q#Ora standard dl’Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Argentina#,
				'generic' => q#Ora dl’Argentina#,
				'standard' => q#Ora standard dl’Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Argentina ozidentala#,
				'generic' => q#OraOra dl’Argentina ozidentala dl’Argentina ozidentala#,
				'standard' => q#Ora standard dl’Argentina ozidentala#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Armenia#,
				'generic' => q#Ora dl’Armenia#,
				'standard' => q#Ora standard dl’Armenia#,
			},
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Cita#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Giacarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Ierusalem#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjöngjang#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh City#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Iakutsk#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ora da d’isté dl Atlantich#,
				'generic' => q#Ora dl Atlantich#,
				'standard' => q#Ora standard dl Atlantich#,
			},
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canaries#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroer#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia dl Süd#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Australia zentrala#,
				'generic' => q#Ora dl’Australia zentrala#,
				'standard' => q#Ora standard dl’Australia zentrala#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Australia zënter-ozidentala#,
				'generic' => q#Ora dl’Australia zënter-ozidentala#,
				'standard' => q#Ora standard dl’Australia zënter-ozidentala#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Australia orientala#,
				'generic' => q#Ora dl’Australia orientala#,
				'standard' => q#Ora standard dl’Australia orientala#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Australia ozidentala#,
				'generic' => q#Ora dl’Australia ozidentala#,
				'standard' => q#Ora standard dl’Australia ozidentala#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ora da d’isté dl Azerbaijan#,
				'generic' => q#Ora dl Azerbaijan#,
				'standard' => q#Ora standard dl Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Ora da d’isté dles Azores#,
				'generic' => q#Ora dles Azores#,
				'standard' => q#Ora standard dles Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Ora da d’isté dl Bangladesc#,
				'generic' => q#Ora dl Bangladesc#,
				'standard' => q#Ora standard dl Bangladesc#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Ora dl Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Ora dla Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Ora da d’isté de Brasilia#,
				'generic' => q#Ora de Brasilia#,
				'standard' => q#Ora standard de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Ora dl Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Ora da d’isté de Capo Verde#,
				'generic' => q#Ora de Capo Verde#,
				'standard' => q#Ora standard de Capo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Ora standard de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Ora da d’isté dles Isoles Chatham#,
				'generic' => q#Ora dles Isoles Chatham#,
				'standard' => q#Ora standard dles Isoles Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Ora da d’isté dl Cile#,
				'generic' => q#Ora dl Cile#,
				'standard' => q#Ora standard dl Cile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Ora da d’isté dla Cina#,
				'generic' => q#Ora dla Cina#,
				'standard' => q#Ora standard dla Cina#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ora dla Isola dl Nadé#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Ora dles Isoles Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Ora da d’isté dla Colombia#,
				'generic' => q#Ora dla Colombia#,
				'standard' => q#Ora standard dla Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Ora da d’isté mesana dles Isoles Cook#,
				'generic' => q#Ora dles Isoles Cook#,
				'standard' => q#Ora standard dles Isoles Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Ora da d’isté de Cuba#,
				'generic' => q#Ora de Cuba#,
				'standard' => q#Ora standard de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ora de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ora de Timor Ost#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Isola de Pasca#,
				'generic' => q#Ora dl’Isola de Pasca#,
				'standard' => q#Ora standard dl’Isola de Pasca#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ora dl Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Tëmp coordiné universal#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Cité nia conesciüda#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Irlanda#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isola de Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbona#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubiana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#Ora da d’isté britanica#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lussemburgh#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosca#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsavia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Turic#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Europa zentrala#,
				'generic' => q#Ora dl’Europa zentrala#,
				'standard' => q#Ora standard dl’Europa zentrala#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Europa orientala#,
				'generic' => q#Ora dl’Europa orientala#,
				'standard' => q#Ora standard dl’Europa orientala#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Ora de Kaliningrad#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Europa ozidentala#,
				'generic' => q#Ora dl’Europa ozidentala#,
				'standard' => q#Ora standard dl’Europa ozidentala#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Ora da d’isté dles Isoles Falkland#,
				'generic' => q#Ora dles Isoles Falkland#,
				'standard' => q#Ora standard dles Isoles Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Ora da d’isté dles Fiji#,
				'generic' => q#Ora dles Fiji#,
				'standard' => q#Ora standard dles Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ora dla Guyana franzeja#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ora di Teritori franzesc dl Süd y dl’Antartica#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ora mesana de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Ora dles Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Ora dles Isoles Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Ora da d’isté dla Georgia#,
				'generic' => q#Ora dla Georgia#,
				'standard' => q#Ora standard dla Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Ora dles Isoles Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ora da d’isté dla Groenlandia orientala#,
				'generic' => q#Ora dla Groenlandia orientala#,
				'standard' => q#Ora standard dla Groenlandia orientala#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Ora da d’isté dla Groenlandia ozidentala#,
				'generic' => q#Ora dla Groenlandia ozidentala#,
				'standard' => q#Ora standard dla Groenlandia ozidentala#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Ora standard dl Golf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Ora dla Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Ora da d’isté dles Isoles Hawaii-Aleutines#,
				'generic' => q#Ora dles Isoles Hawaii-Aleutines#,
				'standard' => q#Ora standard dles Isoles Hawaii-Aleutines#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Ora da d’isté de Hong Kong#,
				'generic' => q#Ora de Hong Kong#,
				'standard' => q#Ora standard de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ora da d’isté de Hovd#,
				'generic' => q#Ora de Hovd#,
				'standard' => q#Ora standard de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ora standard dl’India#,
			},
		},
		'Indian/Comoro' => {
			exemplarCity => q#Isoles Comores#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ora dl Ozean indian#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ora dl’Indocina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ora dl’Indonesia zentrala#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ora dl’Indonesia orientala#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ora dl’Indonesia ozidentala#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Ora da d’isté dl Iran#,
				'generic' => q#Ora dl Iran#,
				'standard' => q#Ora standard dl Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Ora da d’isté de Irkutsk#,
				'generic' => q#Ora de Irkutsk#,
				'standard' => q#Ora standard de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ora da d’isté d’Israel#,
				'generic' => q#Ora d’Israel#,
				'standard' => q#Ora standard d’Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Ora da d’isté dl Iapan#,
				'generic' => q#Ora dl Iapan#,
				'standard' => q#Ora standard dl Iapan#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Ora dl Kazakhstan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ora dl Kazakhstan oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Ora dl Kazakhstan ozidental#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Ora da d’isté dla Corea#,
				'generic' => q#Ora dla Corea#,
				'standard' => q#Ora standard dla Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Ora dl’Isola Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Ora da d’isté de Krasnoyarsk#,
				'generic' => q#Ora de Krasnoyarsk#,
				'standard' => q#Ora standard de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Ora dl Kyrgystan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ora dles Isoles Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ora da d’isté de Lord Howe#,
				'generic' => q#Ora de Lord Howe#,
				'standard' => q#Ora standard de Lord Howe#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Ora da d’isté de Magadan#,
				'generic' => q#Ora de Magadan#,
				'standard' => q#Ora standard de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Ora dla Malesia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Ora dles Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Ora dles Isoles Marchejes#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Ore dles Isoles Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Ora da d’isté de Mauritius#,
				'generic' => q#Ora de Mauritius#,
				'standard' => q#Ora standard de Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Ora de Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Ora da d’isté dla spona pazifica dl Messich#,
				'generic' => q#Ora dla spona pazifica dl Messich#,
				'standard' => q#Ora standard dla spona pazifica dl Messich#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ora da d’isté de Ulan Bator#,
				'generic' => q#Ora de Ulan Bator#,
				'standard' => q#Ora standard de Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Ora da d’isté de Mosca#,
				'generic' => q#Ora de Mosca#,
				'standard' => q#Ora standard de Mosca#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Ora dl Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Ora de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Ora dl Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ora da d’isté dla Nöia Caledonia#,
				'generic' => q#Ora dla Nöia Caledonia#,
				'standard' => q#Ora standard dla Nöia Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ora da d’isté dla Nöia Zelanda#,
				'generic' => q#Ora dla Nöia Zelanda#,
				'standard' => q#Ora standard dla Nöia Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ora da d’isté de Newfoundland#,
				'generic' => q#Ora de Newfoundland#,
				'standard' => q#Ora standard de Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ora de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Ora da d’isté dl’Isola Norfolk#,
				'generic' => q#Ora dl’Isola Norfolk#,
				'standard' => q#Ora standard dl’Isola Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Ora da d’isté de Fernando de Noronha#,
				'generic' => q#Ora de Fernando de Noronha#,
				'standard' => q#Ora standard de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Ora da d’isté de Novosibirsk#,
				'generic' => q#Ora de Novosibirsk#,
				'standard' => q#Ora standard de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ora da d’isté de Omsk#,
				'generic' => q#Ora de Omsk#,
				'standard' => q#Ora standard de Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Isola de Pasca#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Isoles Marchejes#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Ora da d’isté dl Pakistan#,
				'generic' => q#Ora dl Pakistan#,
				'standard' => q#Ora standard dl Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Ora de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Ora dla Papua Nöia Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Ora da d’isté dl Paraguay#,
				'generic' => q#Ora dl Paraguay#,
				'standard' => q#Ora standard dl Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Ora da d’isté dl Perú#,
				'generic' => q#Ora dl Perú#,
				'standard' => q#Ora standard dl Perú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Ora da d’isté dles Filipines#,
				'generic' => q#Ora dles Filipines#,
				'standard' => q#Ora standard dles Filipines#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Ora dles Isoles Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ora da d’isté de St. Pierre y Miquelon#,
				'generic' => q#Ora de St. Pierre y Miquelon#,
				'standard' => q#Ora standard de St. Pierre y Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Ora dles Isoles Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ora de Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Ora de Pjöngjang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Ora de Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Ora da d’isté de Sachalin#,
				'generic' => q#Ora de Sachalin#,
				'standard' => q#Ora standard de Sachalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Ora da d’isté de Samoa#,
				'generic' => q#Ora de Samoa#,
				'standard' => q#Ora standard de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ora dles Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Ora standard de Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Ora dles Isoles Salomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Ora dla Georgia dl Süd#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Ora dl Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Ora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Ora de Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Ora da d’isté de Taipei#,
				'generic' => q#Ora de Taipei#,
				'standard' => q#Ora standard de Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Ora dl Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Ora de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Ora da d’isté de Tonga#,
				'generic' => q#Ora de Tonga#,
				'standard' => q#Ora standard de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Ora dl Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Ora da d’isté dl Turkmenistan#,
				'generic' => q#Ora dl Turkmenistan#,
				'standard' => q#Ora standard dl Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Ora de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Ora da d’isté dl Uruguay#,
				'generic' => q#Ora dl Uruguay#,
				'standard' => q#Ora standard dl Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Ora da d’isté dl Uzbekistan#,
				'generic' => q#Ora dl Uzbekistan#,
				'standard' => q#Ora standard dl Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Ora da d’isté dl Vanuatu#,
				'generic' => q#Ora dl Vanuatu#,
				'standard' => q#Ora standard dl Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Ora dl Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Ora da d’isté de Vladivostok#,
				'generic' => q#Ora de Vladivostok#,
				'standard' => q#Ora standard de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Ora da d’isté de Volgograd#,
				'generic' => q#Ora de Volgograd#,
				'standard' => q#Ora standard de Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Ora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ora dl’Isola de Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Ora de Wallis y Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Ora da d’isté de Iakutsk#,
				'generic' => q#Ora de Iakutsk#,
				'standard' => q#Ora standard de Iakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ora da d’isté de Yekaterinburg#,
				'generic' => q#Ora de Yekaterinburg#,
				'standard' => q#Ora standard de Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Ora dl Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
