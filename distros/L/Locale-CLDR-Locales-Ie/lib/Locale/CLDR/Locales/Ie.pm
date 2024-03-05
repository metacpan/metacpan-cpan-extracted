=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ie - Package for language Interlingue

=cut

package Locale::CLDR::Locales::Ie;
# This file auto generated from Data\common\main\ie.xml
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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ab' => 'abkhazian',
 				'ady' => 'adyghean',
 				'af' => 'afrikaans',
 				'ale' => 'aleut',
 				'alt' => 'sud-altaic',
 				'am' => 'amharesi',
 				'an' => 'aragonesi',
 				'ar' => 'arabic',
 				'arn' => 'mapuche',
 				'ars' => 'arabic najdi',
 				'as' => 'assamesi',
 				'ast' => 'asturian',
 				'av' => 'avar',
 				'ay' => 'aymaran',
 				'az' => 'azerbaidjanesi',
 				'ba' => 'bashkir',
 				'ban' => 'balinesi',
 				'be' => 'bieloruss',
 				'bg' => 'bulgarian',
 				'bi' => 'Bislama',
 				'bm' => 'bambaran',
 				'bn' => 'bangla',
 				'bo' => 'tibetan',
 				'br' => 'bretonesi',
 				'brx' => 'bodo',
 				'bs' => 'bosnian',
 				'ca' => 'catalan',
 				'ce' => 'tchetchen',
 				'ceb' => 'cebuano',
 				'ch' => 'chamorro',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'central kurd',
 				'ckb@alt=menu' => 'kurd, central',
 				'ckb@alt=variant' => 'kurd, sorani',
 				'co' => 'corsican',
 				'crj' => 'sudost-cree',
 				'crk' => 'planuran cree',
 				'crl' => 'nordost-cree',
 				'crm' => 'cree de Moose',
 				'crr' => 'algonquinesi de Carolina',
 				'cs' => 'tchec',
 				'csw' => 'paludan cree',
 				'cv' => 'chuvash',
 				'cy' => 'vallesi',
 				'da' => 'danesi',
 				'dak' => 'dakota',
 				'de' => 'german',
 				'de_AT' => 'austrian german',
 				'de_CH' => 'sviss alt-german',
 				'dsb' => 'platt sorbic',
 				'dz' => 'dzongkha',
 				'el' => 'grec',
 				'en' => 'anglesi',
 				'en_AU' => 'australian anglesi',
 				'en_CA' => 'canadian anglesi',
 				'en_GB' => 'britannic anglesi',
 				'en_GB@alt=short' => 'anglesi de UR',
 				'en_US' => 'american anglesi',
 				'en_US@alt=short' => 'anglesi de USA',
 				'eo' => 'Esperanto',
 				'es' => 'hispan',
 				'es_419' => 'hispan del latin America',
 				'es_ES' => 'europan hispan',
 				'es_MX' => 'mexican hispan',
 				'et' => 'estonian',
 				'eu' => 'basc',
 				'fa' => 'persian',
 				'fa_AF' => 'dari',
 				'fi' => 'finn',
 				'fil' => 'filipinesi',
 				'fj' => 'fidjian',
 				'fo' => 'feroesi',
 				'fr' => 'francesi',
 				'fr_CA' => 'canadian francesi',
 				'fr_CH' => 'sviss francesi',
 				'frc' => 'cadjun-francesi',
 				'frr' => 'nord-frisian',
 				'fy' => 'west-frisian',
 				'ga' => 'irlandesi',
 				'gd' => 'scotian gaelic',
 				'gl' => 'galician',
 				'gsw' => 'swiss-aleman',
 				'ha' => 'hausa',
 				'hai' => 'haidan',
 				'haw' => 'hawaian',
 				'hax' => 'sud-haidan',
 				'he' => 'hebreic',
 				'hi' => 'hindi',
 				'hi_Latn' => 'hindi latinisat',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hr' => 'croatian',
 				'hsb' => 'montan sorbic',
 				'ht' => 'haitian creol',
 				'hu' => 'hungarian',
 				'hy' => 'armenian',
 				'ia' => 'Interlingua',
 				'id' => 'indonesian',
 				'ie' => 'Interlingue',
 				'ii' => 'yi de Sichuan',
 				'inh' => 'ingush',
 				'io' => 'Ido',
 				'is' => 'islandesi',
 				'it' => 'italian',
 				'ja' => 'japanesi',
 				'jbo' => 'Lojban',
 				'jv' => 'javan',
 				'ka' => 'georgian',
 				'kk' => 'kazakh',
 				'ko' => 'korean',
 				'krl' => 'karelian',
 				'ks' => 'kashmiran',
 				'ksh' => 'kölnesi',
 				'ku' => 'kurdesi',
 				'kw' => 'cornwallesi',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lb' => 'luxemburgic',
 				'lkt' => 'lakota',
 				'lou' => 'creol de Louisiana',
 				'lrc' => 'nord-lurian',
 				'lt' => 'lituan',
 				'luo' => 'luo',
 				'lv' => 'lettonian',
 				'mad' => 'maduran',
 				'mak' => 'macassaresi',
 				'mdf' => 'mokshan',
 				'mg' => 'malgachic',
 				'mh' => 'marshallesi',
 				'mi' => 'maoric',
 				'mk' => 'macedonian',
 				'ml' => 'malayalam',
 				'mn' => 'mongolian',
 				'ms' => 'malayesi',
 				'mt' => 'maltesi',
 				'mul' => 'multiplic lingues',
 				'mwl' => 'mirandesi',
 				'my' => 'birman',
 				'na' => 'nauru',
 				'nap' => 'neapolitan',
 				'nb' => 'norvegian, bokmål',
 				'nd' => 'nord-ndebele',
 				'nds' => 'bass-german',
 				'ne' => 'nepalesi',
 				'nl' => 'hollandesi',
 				'nl_BE' => 'flandrian',
 				'nn' => 'neo-norvegian',
 				'no' => 'norvegian',
 				'nr' => 'sud-ndebele',
 				'nso' => 'nord-sotho',
 				'nv' => 'navajo',
 				'oc' => 'occitan',
 				'ojc' => 'central odjibwe',
 				'ojs' => 'odji-cree',
 				'os' => 'ossetian',
 				'pa' => 'pandjabic',
 				'pap' => 'Papiamento',
 				'pau' => 'palauan',
 				'pcm' => 'pidgin-nigerian',
 				'pl' => 'polonesi',
 				'ps' => 'pashto',
 				'pt' => 'portugalesi',
 				'pt_BR' => 'brasilian portugalesi',
 				'pt_PT' => 'europan portugalesi',
 				'qu' => 'quechua',
 				'rap' => 'rapanuic',
 				'rm' => 'reto-romanch',
 				'ro' => 'rumanian',
 				'ru' => 'russ',
 				'sa' => 'sanscrit',
 				'sah' => 'yakutan',
 				'sat' => 'santalesi',
 				'sc' => 'sardinian',
 				'scn' => 'sicilian',
 				'sco' => 'Scots',
 				'se' => 'nord-samian',
 				'si' => 'sinhalesi',
 				'sk' => 'slovac',
 				'sl' => 'slovenian',
 				'sm' => 'samoan',
 				'sn' => 'shonan',
 				'so' => 'somalian',
 				'sq' => 'albanesi',
 				'sr' => 'serbian',
 				'srn' => 'sranan',
 				'ss' => 'swati',
 				'st' => 'sud-sotho',
 				'str' => 'salishan del Straits',
 				'su' => 'sundan',
 				'sv' => 'sved',
 				'sw' => 'swahili',
 				'swb' => 'maoresi comoran',
 				'syr' => 'sirian',
 				'tg' => 'tadjic',
 				'th' => 'thai',
 				'tk' => 'turcmen',
 				'tlh' => 'Klingon',
 				'tli' => 'tlingit',
 				'tok' => 'Toki Pona',
 				'tr' => 'turc',
 				'tt' => 'tataric',
 				'ty' => 'tahitian',
 				'tyv' => 'tuvan',
 				'tzm' => 'tamazight del central Atlas',
 				'udm' => 'udmurtan',
 				'ug' => 'uyghur',
 				'uk' => 'ukrainan',
 				'und' => 'ínconosset lingue',
 				'ur' => 'urdu',
 				'uz' => 'uzbec',
 				've' => 'venda',
 				'vi' => 'vietnamesi',
 				'wa' => 'wallonesi',
 				'xh' => 'xhosa',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yue' => 'cantonesi',
 				'yue@alt=menu' => 'chinesi, cantonesi',
 				'zgh' => 'standard maroccan tamazight',
 				'zh' => 'chinesi',
 				'zh@alt=menu' => 'chinesi, mandarin',
 				'zh_Hans' => 'chinesi simplificat',
 				'zh_Hant' => 'chinesi traditional',
 				'zu' => 'zulu',
 				'zxx' => 'sin linguistic contenete',

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
			'Arab' => 'arabic',
 			'Aran' => 'nastalik',
 			'Armn' => 'armenian',
 			'Beng' => 'bengalic',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'Braille',
 			'Cans' => 'canadian sillabarium',
 			'Cyrl' => 'cirillic',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etiopic',
 			'Geor' => 'georgian',
 			'Grek' => 'grec',
 			'Gujr' => 'gujaratic',
 			'Guru' => 'gurmukhic',
 			'Hanb' => 'han con bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'simplificat',
 			'Hans@alt=stand-alone' => 'han simplificat',
 			'Hant' => 'traditional',
 			'Hant@alt=stand-alone' => 'han traditional',
 			'Hebr' => 'hebreic',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'japanesi sillabariums',
 			'Jamo' => 'jamo',
 			'Jpan' => 'japanesi',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'korean',
 			'Laoo' => 'laotic',
 			'Latn' => 'latin',
 			'Mong' => 'mongolian',
 			'Mymr' => 'birmesi',
 			'Sinh' => 'sinhalic',
 			'Syrc' => 'sirian',
 			'Taml' => 'tamil',
 			'Telu' => 'telugu',
 			'Thai' => 'thai',
 			'Tibt' => 'tibetic',
 			'Zmth' => 'matematic notation',
 			'Zsym' => 'simboles',
 			'Zxxx' => 'ínscrit',
 			'Zyyy' => 'comun',
 			'Zzzz' => 'ínconosset scritura',

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
			'001' => 'munde',
 			'002' => 'Africa',
 			'003' => 'septentrional America',
 			'005' => 'Sud-America',
 			'009' => 'Oceania',
 			'011' => 'West-Africa',
 			'013' => 'central America',
 			'014' => 'Ost-Africa',
 			'015' => 'Nord-Africa',
 			'017' => 'central Africa',
 			'018' => 'meridional Africa',
 			'019' => 'Americas',
 			'021' => 'Nord-America',
 			'029' => 'Caribes',
 			'030' => 'Ost-Asia',
 			'034' => 'Sud-Asia',
 			'035' => 'Sudost-Asia',
 			'039' => 'Sud-Europa',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'region de Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Central Asia',
 			'145' => 'West-Asia',
 			'150' => 'Europa',
 			'151' => 'Ost-Europa',
 			'154' => 'Nord-Europa',
 			'155' => 'West-Europa',
 			'202' => 'Sub-Saharan Africa',
 			'419' => 'latin America',
 			'AC' => 'Insul de Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Unit Arab Emiratus',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentinia',
 			'AS' => 'American Samoa',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Insules Åland',
 			'AZ' => 'Azerbaidjan',
 			'BA' => 'Bosnia e Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina-Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sant-Bartolomeo',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribean Nederland',
 			'BR' => 'Brasilia',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Insul Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorussia',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Insules Cocos (Keeling)',
 			'CD' => 'Congo (Kinshasa)',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Central African Republica',
 			'CG' => 'Congo (Brazzaville)',
 			'CG@alt=variant' => 'Congo',
 			'CH' => 'Svissia',
 			'CI' => 'Coste de Ivor',
 			'CK' => 'Insules Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerun',
 			'CN' => 'China',
 			'CO' => 'Columbia',
 			'CP' => 'Insul Clipperton',
 			'CR' => 'Costa-Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cap-Verdi',
 			'CW' => 'Curaçao',
 			'CX' => 'Insul Christmas',
 			'CY' => 'Cypria',
 			'CZ' => 'Tchekia',
 			'DE' => 'Germania',
 			'DG' => 'Diego-Garcia',
 			'DJ' => 'Djibuti',
 			'DK' => 'Dania',
 			'DM' => 'Dominica',
 			'DO' => 'Dominican Republica',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta e Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egiptia',
 			'EH' => 'West-Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Hispania',
 			'ET' => 'Etiopia',
 			'EU' => 'Union Europan',
 			'EZ' => 'Zone de euro',
 			'FI' => 'Finland',
 			'FJ' => 'Fidji',
 			'FK' => 'Insules Falkland',
 			'FK@alt=variant' => 'Insules Falkland (Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Insulas Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabon',
 			'GB' => 'Unit Reyia',
 			'GB@alt=short' => 'UR',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Francesi Guiana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadelup',
 			'GQ' => 'Equatoral Guinea',
 			'GR' => 'Grecia',
 			'GS' => 'Insules Sud-Georgia e Sud-Sandwich',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong-Kong (SAR de China)',
 			'HK@alt=short' => 'Hong-Kong',
 			'HM' => 'Insules Heard e McDonald Islands',
 			'HN' => 'Hondura',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'IC' => 'Insules Canarias',
 			'ID' => 'Indonesia',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Insul de Man',
 			'IN' => 'India',
 			'IO' => 'Chagos (BTIO)',
 			'IO@alt=biot' => 'Britanic Territoria del Indian Ocean',
 			'IO@alt=chagos' => 'Archipelago Chagos',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordania',
 			'JP' => 'Japan',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgizstan',
 			'KH' => 'Cambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'St. Kitts e Nevis',
 			'KP' => 'Nord-Korea',
 			'KR' => 'Sud-Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Insules Cayman',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'St.-Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri-Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburg',
 			'LV' => 'Lettonia',
 			'LY' => 'Libia',
 			'MA' => 'Marocco',
 			'MC' => 'Mónaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'St.-Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Insules Marshall',
 			'MK' => 'Nord-Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao (SAR de China)',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Insules Nord Mariana',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauretania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricio',
 			'MV' => 'Maldivas',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambic',
 			'NA' => 'Namibia',
 			'NC' => 'Nov-Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Insul Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederland',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nov-Zeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Perú',
 			'PF' => 'Francesi Polinesia',
 			'PG' => 'Papua Nov-Guinea',
 			'PH' => 'Filipines',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'St.-Pierre e Miquelon',
 			'PN' => 'Insules Pitcairn',
 			'PR' => 'Porto-Rico',
 			'PS' => 'Territorias de Palestina',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'periferic Oceania',
 			'RE' => 'Reunion',
 			'RO' => 'Rumania',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Rwanda',
 			'SA' => 'Sauditic Arabia',
 			'SB' => 'Insules Solomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Svedia',
 			'SG' => 'Singapur',
 			'SH' => 'Sant-Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra-Leone',
 			'SM' => 'San-Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sud-Sudan',
 			'ST' => 'São-Tomé e Príncipe',
 			'SV' => 'El-Salvador',
 			'SX' => 'Sint-Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan-da-Cunha',
 			'TC' => 'Turks e Caicos',
 			'TD' => 'Tchad',
 			'TF' => 'Territorias meridional de Francia',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Ost-Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turcia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Insules periferic de USA',
 			'UN' => 'Unit Nationes',
 			'US' => 'Unit States',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Cité de Vatican',
 			'VC' => 'St. Vincent e Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Insules Vírginas (UR)',
 			'VI' => 'Insules Vírginas (USA)',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudo-diacritica',
 			'XB' => 'pseudo-bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sud-Africa',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'ínconosset region',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'ortografie post-1901',
 			'1994' => 'standardisat ortografie',
 			'1996' => 'ortografie post-1996',
 			'1694ACAD' => 'temporan modern francesi',
 			'1959ACAD' => 'academic',
 			'AO1990' => 'acorde ortografic de 1990',
 			'BAKU1926' => 'Janalif',
 			'BOHORIC' => 'de Bohoric',
 			'COLB1945' => 'convention ortografic de 1945',
 			'EKAVSK' => 'ekavian',
 			'EMODENG' => 'temporan modern anglesi',
 			'FONIPA' => 'alfabet IPA',
 			'FONUPA' => 'alfabet UPA',
 			'FONXSAMP' => 'X-SAMPA',
 			'GASCON' => 'gascon',
 			'GRCLASS' => 'classic ortografie',
 			'GRITAL' => 'italianesc',
 			'GRMISTR' => 'mistralianesc',
 			'HEPBURN' => 'romanisation Hepburn',
 			'HOGNORSK' => 'alt-norvegian',
 			'HSISTEMO' => 'h-sistema',
 			'IJEKAVSK' => 'ijekavian',
 			'ITIHASA' => 'epic sanscrit',
 			'IVANCHOV' => 'ortografie pre-1945',
 			'JAUER' => 'jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'ortografie comun',
 			'KOCIEWIE' => 'de Kociewie',
 			'KSCOR' => 'standard ortografie',
 			'LEMOSIN' => 'lemosin',
 			'LENGADOC' => 'languedocan',
 			'LTG1929' => 'ortografie de 1929',
 			'LTG2007' => 'ortografie de 2007',
 			'LUNA1918' => 'modern ortografie',
 			'METELKO' => 'de Metelko',
 			'MONOTON' => 'monotonic',
 			'NEWFOUND' => 'de Newfoundland',
 			'NULIK' => 'modern Volapük',
 			'OXENDICT' => 'ortografie del OED',
 			'PEANO' => 'de Peano',
 			'PETR1708' => 'ortografie pre-1918',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'politonic',
 			'POSIX' => 'computational',
 			'PROVENC' => 'provanceal',
 			'PUTER' => 'puter',
 			'REVISED' => 'reviset ortografie',
 			'RIGIK' => 'classic Volapük',
 			'ROZAJ' => 'resian',
 			'SCOTLAND' => 'de Scotia',
 			'SCOUSE' => 'Scouse',
 			'SIMPLE' => 'simplificat',
 			'SOTAV' => 'del Sotavento',
 			'SPANGLIS' => 'Spanglish',
 			'SURMIRAN' => 'surmiran',
 			'SURSILV' => 'sursilvan',
 			'SUTSILV' => 'sutsilvan',
 			'TARASK' => 'de Tarashkevitch',
 			'TUNUMIIT' => 'ost-grenlandesi',
 			'UCCOR' => 'unificat ortografie',
 			'ULSTER' => 'de Ulster',
 			'UNIFON' => 'alfabet Unifon',
 			'VAIDIKA' => 'Vedic',
 			'VALENCIA' => 'valencian',
 			'VALLADER' => 'vallader',
 			'VECDRUKA' => 'old ortografie',
 			'VIVARAUP' => 'vivaroalpin',
 			'WADEGILE' => 'romanisation Wade-Giles',
 			'XSISTEMO' => 'x-sistema',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'calendare',
 			'cf' => 'formate de valuta',
 			'collation' => 'órdine',
 			'currency' => 'valuta',
 			'hc' => 'cicle de hores (12 o 24)',
 			'ms' => 'sistema de mesuras',
 			'numbers' => 'númeres',

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
 				'buddhist' => q{buddhist calendare},
 				'chinese' => q{chinesi calendare},
 				'coptic' => q{coptic calendare},
 				'ethiopic' => q{etiopic calendare},
 				'gregorian' => q{gregorian calendare},
 				'hebrew' => q{hebreic calendare},
 				'islamic' => q{calendare hejra},
 				'iso8601' => q{calendare ISO-8601},
 				'japanese' => q{japanesi calendare},
 				'persian' => q{persian calendare},
 			},
 			'cf' => {
 				'account' => q{formate por contation},
 				'standard' => q{standard valuta-formate},
 			},
 			'collation' => {
 				'big5han' => q{órdine Big5},
 				'dictionary' => q{órdine de dictionarium},
 				'ducet' => q{órdine predefinit de Unicode},
 				'eor' => q{órdine paneuropan},
 				'gb2312han' => q{órdine GB2312},
 				'phonebook' => q{órdine de numerarium},
 				'pinyin' => q{órdine pinyin},
 				'search' => q{órdine por sercha},
 				'standard' => q{standard órdine},
 				'stroke' => q{órdine de strecs},
 				'unihan' => q{órdine de radicales},
 			},
 			'hc' => {
 				'h11' => q{sistema 12-hor (0..11)},
 				'h12' => q{sistema 12-hor (1..12)},
 				'h23' => q{sistema 24-hor (0..23)},
 				'h24' => q{sistema 24-hor (1..24)},
 			},
 			'ms' => {
 				'metric' => q{metric sistema},
 				'uksystem' => q{britanic sistema},
 				'ussystem' => q{american sistema},
 			},
 			'numbers' => {
 				'arab' => q{oriental ciffres},
 				'arabext' => q{extendet oriental ciffres},
 				'armn' => q{armenian númeres},
 				'armnlow' => q{armenian minuscules},
 				'beng' => q{bengalic ciffres},
 				'cakm' => q{ciffres chakma},
 				'deva' => q{ciffres devanagari},
 				'ethi' => q{etiopic ciffres},
 				'fullwide' => q{plen-larg ciffres},
 				'geor' => q{georgian númeres},
 				'grek' => q{grec númeres},
 				'greklow' => q{grec minuscules},
 				'gujr' => q{gujaratic ciffres},
 				'guru' => q{gurmukhic ciffres},
 				'hanidec' => q{chinesi decimal númeres},
 				'hans' => q{simplificat chinesi númeres},
 				'hansfin' => q{simp. chinesi financial númeres},
 				'hant' => q{traditional chinesi númeres},
 				'hantfin' => q{trad. chinesi financial númeres},
 				'hebr' => q{hebreic númeres},
 				'java' => q{javanesi ciffres},
 				'jpan' => q{japanesi númeres},
 				'jpanfin' => q{japanesi financial númeres},
 				'khmr' => q{ciffres khmer},
 				'knda' => q{kannadan ciffres},
 				'laoo' => q{laotic ciffres},
 				'latn' => q{occidental ciffres},
 				'mlym' => q{ciffres malayalam},
 				'mymr' => q{birmesi ciffres},
 				'roman' => q{roman ciffres},
 				'romanlow' => q{roman minuscules},
 				'taml' => q{traditional tamilic númeres},
 				'tamldec' => q{tamilic ciffres},
 				'telu' => q{ciffres telugu},
 				'thai' => q{thai ciffres},
 				'tibt' => q{tibetan ciffres},
 				'vaii' => q{ciffres vai},
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
			'metric' => q{metric},
 			'UK' => q{anglesi},
 			'US' => q{american},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lingue: {0}',
 			'script' => 'Scritura: {0}',
 			'region' => 'Region: {0}',

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
			auxiliary => qr{[àăâåäãā æ ç èĕêëē ìĭîïī {lʼ} ñ {nʼ} òŏôöøō œ ùŭûüū ýÿ]},
			main => qr{[aá b c d eé f g h ií j k l m n oó p q r s t uú v w x y z]},
			numbers => qr{[\- ‑ , ' % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“”„ « » ( ) \[ \] § @ * / \& † ‡]},
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
					'' => {
						'name' => q(direction cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direction cardinal),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
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
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metres per seconde quadrat),
						'other' => q({0} metres per seconde quadrat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metres per seconde quadrat),
						'other' => q({0} metres per seconde quadrat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arc-minutes),
						'other' => q({0} arc-minutes),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arc-minutes),
						'other' => q({0} arc-minutes),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arc-secondes),
						'other' => q({0} arc-secondes),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arc-secondes),
						'other' => q({0} arc-secondes),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gradus),
						'other' => q({0} gradus),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gradus),
						'other' => q({0} gradus),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianes),
						'other' => q({0} radianes),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianes),
						'other' => q({0} radianes),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectares),
						'other' => q({0} hectares),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectares),
						'other' => q({0} hectares),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(centimetre quadrat),
						'other' => q({0} centimetres quadrat),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(centimetre quadrat),
						'other' => q({0} centimetres quadrat),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pedes quadrat),
						'other' => q({0} pedes quadrat),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pedes quadrat),
						'other' => q({0} pedes quadrat),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inches quadrat),
						'other' => q({0} inches quadrat),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inches quadrat),
						'other' => q({0} inches quadrat),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometres quadrat),
						'other' => q({0} kilometres quadrat),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometres quadrat),
						'other' => q({0} kilometres quadrat),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metre quadrat),
						'other' => q({0} metres quadrat),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metre quadrat),
						'other' => q({0} metres quadrat),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milies quadrat),
						'other' => q({0} milies quadrat),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milies quadrat),
						'other' => q({0} milies quadrat),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yardes quadrat),
						'other' => q({0} yardes quadrat),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yardes quadrat),
						'other' => q({0} yardes quadrat),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(carates),
						'other' => q({0} carates),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(carates),
						'other' => q({0} carates),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(percent),
						'other' => q({0} percent),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(percent),
						'other' => q({0} percent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permille),
						'other' => q({0} permille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permille),
						'other' => q({0} permille),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litres per kilometre),
						'other' => q({0} litres per kilometre),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litres per kilometre),
						'other' => q({0} litres per kilometre),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} west),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} west),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bits),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bits),
						'other' => q({0} bits),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(octetes),
						'other' => q({0} octetes),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(octetes),
						'other' => q({0} octetes),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabits),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigaoctetes),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigaoctetes),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobits),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilooctetes),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilooctetes),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabits),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabits),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megaoctetes),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megaoctetes),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petaoctetes),
						'other' => q({0} petaoctetes),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petaoctetes),
						'other' => q({0} petaoctetes),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabits),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(teraoctetes),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(teraoctetes),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(secules),
						'other' => q({0} secules),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(secules),
						'other' => q({0} secules),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0} dies),
						'per' => q({0} per die),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0} dies),
						'per' => q({0} per die),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(decennies),
						'other' => q({0} decennies),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(decennies),
						'other' => q({0} decennies),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} hores),
						'per' => q({0} per hor),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} hores),
						'per' => q({0} per hor),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(microsecondes),
						'other' => q({0} microsecondes),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(microsecondes),
						'other' => q({0} microsecondes),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisecondes),
						'other' => q({0} millisecondes),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisecondes),
						'other' => q({0} millisecondes),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutes),
						'other' => q({0} minutes),
						'per' => q({0} per minute),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutes),
						'other' => q({0} minutes),
						'per' => q({0} per minute),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} mensus),
						'per' => q({0} per mensu),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} mensus),
						'per' => q({0} per mensu),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosecondes),
						'other' => q({0} nanosecondes),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosecondes),
						'other' => q({0} nanosecondes),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(trimestres),
						'other' => q({0} trimestres),
						'per' => q({0} per trimestre),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(trimestres),
						'other' => q({0} trimestres),
						'per' => q({0} per trimestre),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(secondes),
						'other' => q({0} secondes),
						'per' => q({0} per seconde),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(secondes),
						'other' => q({0} secondes),
						'per' => q({0} per seconde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} semanes),
						'per' => q({0} per semane),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} semanes),
						'per' => q({0} per semane),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} annus),
						'per' => q({0} per annu),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} annus),
						'per' => q({0} per annu),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperes),
						'other' => q({0} amperes),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperes),
						'other' => q({0} amperes),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamperes),
						'other' => q({0} milliamperes),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamperes),
						'other' => q({0} milliamperes),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohms),
						'other' => q({0} ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohms),
						'other' => q({0} ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(voltes),
						'other' => q({0} voltes),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(voltes),
						'other' => q({0} voltes),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(britanic termal unités),
						'other' => q({0} britanic termal unités),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(britanic termal unités),
						'other' => q({0} britanic termal unités),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(calories),
						'other' => q({0} calories),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(calories),
						'other' => q({0} calories),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electron-voltes),
						'other' => q({0} electron-voltes),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electron-voltes),
						'other' => q({0} electron-voltes),
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
						'name' => q(kilocalories),
						'other' => q({0} kilocalories),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilocalories),
						'other' => q({0} kilocalories),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoules),
						'other' => q({0} kilojoules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoules),
						'other' => q({0} kilojoules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt-hores),
						'other' => q({0} kilowatt-hores),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-hores),
						'other' => q({0} kilowatt-hores),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newtones),
						'other' => q({0} newtones),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newtones),
						'other' => q({0} newtones),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixels),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixels),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixels per centimetre),
						'other' => q({0} pixels per centimetre),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixels per centimetre),
						'other' => q({0} pixels per centimetre),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels per inch),
						'other' => q({0} pixels per inch),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels per inch),
						'other' => q({0} pixels per inch),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unité astronomic),
						'other' => q({0} unités astronomic),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unité astronomic),
						'other' => q({0} unités astronomic),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centimetres),
						'other' => q({0} centimetres),
						'per' => q({0} per centimetre),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimetres),
						'other' => q({0} centimetres),
						'per' => q({0} per centimetre),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decimetres),
						'other' => q({0} decimetres),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decimetres),
						'other' => q({0} decimetres),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radiuses del terra),
						'other' => q({0} radiuses del terra),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radiuses del terra),
						'other' => q({0} radiuses del terra),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pedes),
						'other' => q({0} pedes),
						'per' => q({0} per pede),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pedes),
						'other' => q({0} pedes),
						'per' => q({0} per pede),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inches),
						'other' => q({0} inches),
						'per' => q({0} per inch),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inches),
						'other' => q({0} inches),
						'per' => q({0} per inch),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometres),
						'other' => q({0} kilometres),
						'per' => q({0} per kilometre),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometres),
						'other' => q({0} kilometres),
						'per' => q({0} per kilometre),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(luce-annus),
						'other' => q({0} luce-annus),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(luce-annus),
						'other' => q({0} luce-annus),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metres),
						'other' => q({0} metres),
						'per' => q({0} per metre),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metres),
						'other' => q({0} metres),
						'per' => q({0} per metre),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrometres),
						'other' => q({0} micrometres),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrometres),
						'other' => q({0} micrometres),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milies),
						'other' => q({0} milies),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milies),
						'other' => q({0} milies),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimetres),
						'other' => q({0} millimetres),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimetres),
						'other' => q({0} millimetres),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometres),
						'other' => q({0} nanometres),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometres),
						'other' => q({0} nanometres),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(marin milies),
						'other' => q({0} marin milies),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(marin milies),
						'other' => q({0} marin milies),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picometres),
						'other' => q({0} picometres),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picometres),
						'other' => q({0} picometres),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punctus),
						'other' => q({0} punctus),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punctus),
						'other' => q({0} punctus),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radiuses del sol),
						'other' => q({0} radiuses del sol),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radiuses del sol),
						'other' => q({0} radiuses del sol),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yards),
						'other' => q({0} yardes),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yards),
						'other' => q({0} yardes),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candelas),
						'other' => q({0} candelas),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candelas),
						'other' => q({0} candelas),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumenes),
						'other' => q({0} lumenes),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumenes),
						'other' => q({0} lumenes),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminositás solari),
						'other' => q({0} luminositás solari),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminositás solari),
						'other' => q({0} luminositás solari),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grammes),
						'other' => q({0} grammes),
						'per' => q({0} per gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grammes),
						'other' => q({0} grammes),
						'per' => q({0} per gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogrammes),
						'other' => q({0} kilogrammes),
						'per' => q({0} per kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogrammes),
						'other' => q({0} kilogrammes),
						'per' => q({0} per kilogramm),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(microgrammes),
						'other' => q({0} microgrammes),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(microgrammes),
						'other' => q({0} microgrammes),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligrammes),
						'other' => q({0} milligrammes),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligrammes),
						'other' => q({0} milligrammes),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(uncies),
						'other' => q({0} uncies),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(uncies),
						'other' => q({0} uncies),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pundes),
						'other' => q({0} pundes),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pundes),
						'other' => q({0} pundes),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
						'other' => q({0} stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
						'other' => q({0} stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(american tonnes),
						'other' => q({0} american tonnes),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(american tonnes),
						'other' => q({0} american tonnes),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonnes),
						'other' => q({0} tonnes),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonnes),
						'other' => q({0} tonnes),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawattes),
						'other' => q({0} gigawattes),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawattes),
						'other' => q({0} gigawattes),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cavall-forties),
						'other' => q({0} cavall-forties),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cavall-forties),
						'other' => q({0} cavall-forties),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowattes),
						'other' => q({0} kilowattes),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowattes),
						'other' => q({0} kilowattes),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawattes),
						'other' => q({0} megawattes),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawattes),
						'other' => q({0} megawattes),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milliwattes),
						'other' => q({0} milliwattes),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milliwattes),
						'other' => q({0} milliwattes),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(wattes),
						'other' => q({0} wattes),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(wattes),
						'other' => q({0} wattes),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} quadrat),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} quadrat),
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
						'name' => q(atmosferes),
						'other' => q({0} atmosferes),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosferes),
						'other' => q({0} atmosferes),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bares),
						'other' => q({0} bares),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bares),
						'other' => q({0} bares),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hectopascales),
						'other' => q({0} hectopascales),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hectopascales),
						'other' => q({0} hectopascales),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopascales),
						'other' => q({0} kilopascales),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopascales),
						'other' => q({0} kilopascales),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascales),
						'other' => q({0} megapascales),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascales),
						'other' => q({0} megapascales),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibares),
						'other' => q({0} millibares),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibares),
						'other' => q({0} millibares),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascales),
						'other' => q({0} pascales),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascales),
						'other' => q({0} pascales),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometres per hor),
						'other' => q({0} kilometres per hor),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometres per hor),
						'other' => q({0} kilometres per hor),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nodes),
						'other' => q({0} nodes),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nodes),
						'other' => q({0} nodes),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metres per seconde),
						'other' => q({0} metres per seconde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metres per seconde),
						'other' => q({0} metres per seconde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milies per hor),
						'other' => q({0} milies per hor),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milies per hor),
						'other' => q({0} milies per hor),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gradus Celsius),
						'other' => q({0} gradus Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gradus Celsius),
						'other' => q({0} gradus Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(gradus Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(gradus Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(gradus de temperatura),
						'other' => q({0} gradus de temperatura),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(gradus de temperatura),
						'other' => q({0} gradus de temperatura),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvines),
						'other' => q({0} kelvines),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvines),
						'other' => q({0} kelvines),
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
						'name' => q(newton-metres),
						'other' => q({0} newton-metres),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-metres),
						'other' => q({0} newton-metres),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(busheles),
						'other' => q({0} busheles),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(busheles),
						'other' => q({0} busheles),
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
						'name' => q(centimetres cubic),
						'other' => q({0} centimetres cubic),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(centimetres cubic),
						'other' => q({0} centimetres cubic),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pedes cubic),
						'other' => q({0} pedes cubic),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pedes cubic),
						'other' => q({0} pedes cubic),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inches cubic),
						'other' => q({0} inches cubic),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inches cubic),
						'other' => q({0} inches cubic),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilometres cubic),
						'other' => q({0} kilometres cubic),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilometres cubic),
						'other' => q({0} kilometres cubic),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metres cubic),
						'other' => q({0} metres cubic),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metres cubic),
						'other' => q({0} metres cubic),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milies cubic),
						'other' => q({0} milies cubic),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milies cubic),
						'other' => q({0} milies cubic),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yardes cubic),
						'other' => q({0} yardes cubic),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yardes cubic),
						'other' => q({0} yardes cubic),
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
					'volume-liter' => {
						'name' => q(litres),
						'other' => q({0} litres),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litres),
						'other' => q({0} litres),
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
						'name' => q(millilitres),
						'other' => q({0} millilitres),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millilitres),
						'other' => q({0} millilitres),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(dir.),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(dir.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acre),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(o),
						'other' => q({0} o),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(o),
						'other' => q({0} o),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mn),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mn),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
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
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
					},
				},
				'short' => {
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(mc{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mc{0}),
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
					'area-acre' => {
						'name' => q(acres),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acres),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(oct),
						'other' => q({0} oct),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(oct),
						'other' => q({0} oct),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(Go),
						'other' => q({0} Go),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(Go),
						'other' => q({0} Go),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ko),
						'other' => q({0} ko),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ko),
						'other' => q({0} ko),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(Mo),
						'other' => q({0} Mo),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(Mo),
						'other' => q({0} Mo),
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
						'other' => q({0} To),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(To),
						'other' => q({0} To),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(scl),
						'other' => q({0} scl),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(scl),
						'other' => q({0} scl),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dies),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dies),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hores),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hores),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mcs),
						'other' => q({0} mcs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mcs),
						'other' => q({0} mcs),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mensus),
						'other' => q({0} mn),
						'per' => q({0}/mn),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mensus),
						'other' => q({0} mn),
						'per' => q({0}/mn),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(tr),
						'other' => q({0} tr),
						'per' => q({0}/tr),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(tr),
						'other' => q({0} tr),
						'per' => q({0}/tr),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semanes),
						'other' => q({0} sem),
						'per' => q({0}/sem),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semanes),
						'other' => q({0} sem),
						'per' => q({0}/sem),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(annus),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(annus),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(btu),
						'other' => q({0} btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(btu),
						'other' => q({0} btu),
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
					'length-astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(la),
						'other' => q({0} la),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(la),
						'other' => q({0} la),
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
					'length-micrometer' => {
						'name' => q(mcm),
						'other' => q({0} mcm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mcm),
						'other' => q({0} mcm),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramm),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mcg),
						'other' => q({0} mcg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mcg),
						'other' => q({0} mcg),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milies/hor),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milies/hor),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inches³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inches³),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				2 => q({0} e {1}),
		} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 2,
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
					'other' => '0 milles',
				},
				'10000' => {
					'other' => '00 milles',
				},
				'100000' => {
					'other' => '000 milles',
				},
				'1000000' => {
					'other' => '0 milliones',
				},
				'10000000' => {
					'other' => '00 milliones',
				},
				'100000000' => {
					'other' => '000 milliones',
				},
				'1000000000' => {
					'other' => '0 milliardes',
				},
				'10000000000' => {
					'other' => '00 milliardes',
				},
				'100000000000' => {
					'other' => '000 milliardes',
				},
				'1000000000000' => {
					'other' => '0 billiones',
				},
				'10000000000000' => {
					'other' => '00 billiones',
				},
				'100000000000000' => {
					'other' => '000 billiones',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0',
				},
				'10000' => {
					'other' => '0',
				},
				'100000' => {
					'other' => '0',
				},
				'1000000' => {
					'other' => '0',
				},
				'10000000' => {
					'other' => '0',
				},
				'100000000' => {
					'other' => '0',
				},
				'1000000000' => {
					'other' => '0',
				},
				'10000000000' => {
					'other' => '0',
				},
				'100000000000' => {
					'other' => '0',
				},
				'1000000000000' => {
					'other' => '0',
				},
				'10000000000000' => {
					'other' => '0',
				},
				'100000000000000' => {
					'other' => '0',
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
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
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
				'currency' => q(UAE dirham),
				'other' => q(UAE dirhams),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghan afghani),
				'other' => q(afghan afghanis),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albanian lek),
				'other' => q(albanian leks),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armenian dram),
				'other' => q(armenian drams),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(guilder del Nederlandesi Antilles),
				'other' => q(guilderes del Nederlandesi Antilles),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolan kwanza),
				'other' => q(angolan kwanzas),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinian peso),
				'other' => q(argentinian pesos),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(australian dollar),
				'other' => q(australian dollares),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(aruban florin),
				'other' => q(aruban florines),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbaidjanesi manat),
				'other' => q(azerbaidjanesi manates),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(convertibil mark de Bosnia-Herzogovina),
				'other' => q(convertibil marks de Bosnia-Herzogovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadan dollar),
				'other' => q(barbadan dollares),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeshan taka),
				'other' => q(bangladeshan takas),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgarian lev),
				'other' => q(bulgarian leves),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainesi dinar),
				'other' => q(bahrainesi dinares),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundian franc),
				'other' => q(burundian francs),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudan dollar),
				'other' => q(bermudan dollares),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(brunesi dollar),
				'other' => q(brunesi dollares),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivian boliviano),
				'other' => q(bolivian bolivianos),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brasilian real),
				'other' => q(brasilian reales),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahaman dollar),
				'other' => q(bahaman dollares),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutanesi ngultrum),
				'other' => q(bhutanesi ngultrums),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswanan pula),
				'other' => q(botswanan pulas),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(bieloruss ruble),
				'other' => q(bieloruss rubles),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizan dollar),
				'other' => q(belizan dollares),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(canadan dollar),
				'other' => q(canadan dollares),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(congolesi franc),
				'other' => q(congolesi francs),
			},
		},
		'CHF' => {
			symbol => 'F.Sv.',
			display_name => {
				'currency' => q(sviss franc),
				'other' => q(sviss francs),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilan peso),
				'other' => q(chilan pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(chinesi yuan \(extraterritorial\)),
				'other' => q(chinesi yuanes \(extraterritorial\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(chinesi yuan),
				'other' => q(chinesi yuanes),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(columbian peso),
				'other' => q(columbian pesos),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(costa-rican colon),
				'other' => q(costa-rican colones),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(cuban convertibil peso),
				'other' => q(cuban convertibil pesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(cuban peso),
				'other' => q(cuban pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(cap-verdesi escudo),
				'other' => q(cap-verdesi escudos),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(tchec koruna),
				'other' => q(tchec korunas),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(djibutian franc),
				'other' => q(djibutian francs),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(danesi krone),
				'other' => q(danesi krones),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominican peso),
				'other' => q(dominican pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algerian dinar),
				'other' => q(algerian dinares),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egiptian pund),
				'other' => q(egiptian pundes),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritrean nakfa),
				'other' => q(eritrean nakfas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopian birr),
				'other' => q(etiopian birres),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'other' => q(euros),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidjian dollar),
				'other' => q(fidjian dollares),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(pund de Falkland),
				'other' => q(pundes de Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(pund sterling),
				'other' => q(pundes sterling),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgian lari),
				'other' => q(georgian laris),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanan cedi),
				'other' => q(ghanan cedis),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(pund de Gibraltar),
				'other' => q(pundes de Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambian dalasi),
				'other' => q(gambian dalasis),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guinean franc),
				'other' => q(guinean francs),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalan quetzal),
				'other' => q(guatemalan quetzales),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyanesi dollar),
				'other' => q(guyanesi dollares),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(dollar de Hong-Kong),
				'other' => q(dollares de Hong-Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduresi lempira),
				'other' => q(honduresi lempiras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(croatian kuna),
				'other' => q(croatian kunas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitian gourde),
				'other' => q(haitian gourdes),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(hungarian forint),
				'other' => q(hungarian forintes),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonesian rupia),
				'other' => q(indonesian rupias),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(israelesi nov shekel),
				'other' => q(israelesi nov shekeles),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indian rupia),
				'other' => q(indian rupias),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakesi dinar),
				'other' => q(irakesi dinares),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranesi real),
				'other' => q(iranesi reales),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandesi krona),
				'other' => q(islandesi kronas),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaican dollar),
				'other' => q(jamaican dollares),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordanian dinar),
				'other' => q(jordanian dinares),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(japanesi yen),
				'other' => q(japanesi yenes),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenian shilling),
				'other' => q(kenian shillings),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgistanesi som),
				'other' => q(kirgistanesi somes),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(cambodjan riel),
				'other' => q(cambodjan rieles),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(comoran franc),
				'other' => q(comoran francs),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(nord-korean won),
				'other' => q(nord-korean wones),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(sud-korean won),
				'other' => q(sud-korean wones),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitesi dinar),
				'other' => q(kuwaitesi dinares),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(caymanesi dollar),
				'other' => q(caymanesi dollares),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazakhstanesi tenge),
				'other' => q(kazakhstanesi tenges),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laotic kip),
				'other' => q(laotic kipes),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanesi pund),
				'other' => q(libanesi pundes),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(sri-lankan rupia),
				'other' => q(sri-lankan rupias),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberian dollar),
				'other' => q(liberian dollares),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothan loti),
				'other' => q(lesothan lotis),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libian dinar),
				'other' => q(libian dinares),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(maroccan dirham),
				'other' => q(maroccan dirhams),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldovan lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(malgachic ariary),
				'other' => q(malgachic ariarys),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(macedonian denar),
				'other' => q(macedonian denares),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmaran kyat),
				'other' => q(myanmaran kyates),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolian tugric),
				'other' => q(mongolian tugrics),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(macan pataca),
				'other' => q(macan patacas),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritanian uguiya),
				'other' => q(mauritanian uguiyas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(maurician rupia),
				'other' => q(maurician rupias),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldivan rufia),
				'other' => q(maldivan rufias),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawian kwacha),
				'other' => q(malawian kwachas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(mexican peso),
				'other' => q(mexican pesos),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malaysian ringgit),
				'other' => q(malaysian ringgites),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambican metical),
				'other' => q(mozambican meticales),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibian dollar),
				'other' => q(namibian dollares),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigerian naira),
				'other' => q(nigerian nairas),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nicaraguan cordoba),
				'other' => q(nicaraguan cordobas),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norvegian krone),
				'other' => q(norvegian krones),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalesi rupia),
				'other' => q(nepalesi rupias),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(nov-zelandesi dollar),
				'other' => q(nov-zelandesi dollares),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omanesi rial),
				'other' => q(omanesi riales),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamesi balboa),
				'other' => q(panamesi balboas),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruan sol),
				'other' => q(peruan soles),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina de Papua Nov-Guinea),
				'other' => q(kinas de Papua Nov-Guinea),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(filipinesi peso),
				'other' => q(filipinesi pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistani rupia),
				'other' => q(pakistani rupias),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polonesi zloty),
				'other' => q(polonesi zlotys),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayan guarani),
				'other' => q(paraguayan guaranis),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(qataresi riyal),
				'other' => q(qataresi riyales),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rumanian lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbian dinar),
				'other' => q(serbian dinares),
			},
		},
		'RUB' => {
			symbol => 'Rub.',
			display_name => {
				'currency' => q(russian ruble),
				'other' => q(russian rubles),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandan franc),
				'other' => q(rwandan francs),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(sauditic riyal),
				'other' => q(sauditic riyales),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dollar del Insules Solomon),
				'other' => q(dollares del Insules Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychellan rupia),
				'other' => q(seychellan rupias),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudanesi pund),
				'other' => q(sudanesi pundes),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(sved krona),
				'other' => q(sved kronas),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapuran dollar),
				'other' => q(singapuran dollares),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(pund de Sant-Helena),
				'other' => q(pundes de Sant-Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leone de Sierra-Leone),
				'other' => q(leones de Sierra-Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone de Sierra-Leone \(1964..2022\)),
				'other' => q(leones de Sierra-Leone \(1964..2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somalian shilling),
				'other' => q(somalian shillings),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamesi dollar),
				'other' => q(surinamesi dollares),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(sud-sudanesi pund),
				'other' => q(sud-sudanesi pundes),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra de São Tomé e Príncipe),
				'other' => q(dobras de São Tomé e Príncipe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(sirian pund),
				'other' => q(sirian pundes),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swazian lilangeni),
				'other' => q(swazian lilangenis),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(thai baht),
				'other' => q(thai bahtes),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadjikistanesi somoni),
				'other' => q(tadjikistanesi somonis),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turcmen manat),
				'other' => q(turcmen manates),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunisian dinar),
				'other' => q(tunisian dinares),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongan pa’anga),
				'other' => q(tongan pa’angas),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turc lira),
				'other' => q(turc liras),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dollar de Trinidad e Tobago),
				'other' => q(dollares de Trinidad e Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(nov taiwanesi dollar),
				'other' => q(nov taiwanesi dollares),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzanian shilling),
				'other' => q(tanzanian shillings),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainan hrivnia),
				'other' => q(ukrainan hrivnias),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandesi shilling),
				'other' => q(ugandesi shillings),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(american dollar),
				'other' => q(american dollares),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayan peso),
				'other' => q(uruguayan pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbec som),
				'other' => q(uzbec somes),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelan bolivar),
				'other' => q(venezuelan bolivares),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(vietnamesi dong),
				'other' => q(vietnamesi dongs),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatuan vatu),
				'other' => q(vanuatuan vatus),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoan tala),
				'other' => q(samoan talas),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA franc),
				'other' => q(CFA francs),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(argent),
				'other' => q(troy-uncies de argent),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(aur),
				'other' => q(troy-uncies de aur),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(ost-caribean dollar),
				'other' => q(ost-caribean dollares),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(west-african CFA franc),
				'other' => q(west-african CFA francs),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladium),
				'other' => q(troy-uncies de palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP franc),
				'other' => q(CFP francs),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platine),
				'other' => q(troy-uncies de platine),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ínconosset valuta),
				'other' => q(de ínconosset valuta),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(yemenesi real),
				'other' => q(yemenesi reales),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(sud-african rand),
				'other' => q(sud-african randes),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambian kwacha),
				'other' => q(zambian kwachas),
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
							'jan.',
							'febr.',
							'mar.',
							'apr.',
							'may',
							'jun.',
							'julí',
							'aug.',
							'sept.',
							'oct.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januar',
							'februar',
							'marte',
							'april',
							'may',
							'junio',
							'julí',
							'august',
							'septembre',
							'octobre',
							'novembre',
							'decembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
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
						mon => 'lun.',
						tue => 'mar.',
						wed => 'mer.',
						thu => 'jov.',
						fri => 'ven.',
						sat => 'sat.',
						sun => 'sol.'
					},
					short => {
						mon => 'Lu',
						tue => 'Ma',
						wed => 'Me',
						thu => 'Jo',
						fri => 'Ve',
						sat => 'Sa',
						sun => 'So'
					},
					wide => {
						mon => 'lunedí',
						tue => 'mardí',
						wed => 'mercurdí',
						thu => 'jovedí',
						fri => 'venerdí',
						sat => 'saturdí',
						sun => 'soledí'
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
						sun => 'S'
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
					wide => {0 => '1-m trimestre',
						1 => '2-m trimestre',
						2 => '3-m trimestre',
						3 => '4-m trimestre'
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
				'narrow' => {
					'am' => q{a.},
					'pm' => q{p.},
				},
				'wide' => {
					'am' => q{ante midí},
					'pm' => q{pos midí},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{a.},
					'pm' => q{p.},
				},
				'wide' => {
					'am' => q{ante midí},
					'pm' => q{pos midí},
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
				'1' => 'e.C.'
			},
			wide => {
				'0' => 'ante Crist',
				'1' => 'era Cristan'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d.M.yy},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
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
			Bh => q{h 'h'. B},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d.M.y GGGGG},
			H => q{H 'h'.},
			MEd => q{E d.M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d.M},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y GGGGG},
			yyyyMEd => q{E d.M.y GGGGG},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d.M.y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d.M.y G},
			H => q{H 'h'.},
			MEd => q{E d.M},
			MMMEd => q{E d MMM},
			MMMMW => q{W-'im' 'semane' 'de' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d.M},
			d => q{d.},
			yM => q{M.y},
			yMEd => q{E d.M.y},
			yMMM => q{MMM y},
			yMMMEd => q{EEEE d MMM y},
			yMMMM => q{LLLL y},
			yMMMd => q{d MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w-'im' 'semane' 'de' Y},
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
			Bh => {
				h => q{h–h 'h'. B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M.y GGGGG – M.y GGGGG},
				M => q{M – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			GyMEd => {
				G => q{E d.M.y GGGGG – E d.M.y GGGGG},
				M => q{E d.M.y – E d.M.y GGGGG},
				d => q{E d. – E d.M.y GGGGG},
				y => q{E d.M.y – E d.M.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
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
				d => q{d. – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E d. – E d.M},
				d => q{E d.M – E d.M},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d. – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d.M – d.M},
				d => q{d. – d.M},
			},
			d => {
				d => q{d. – d.},
			},
			fallback => '{0} til {1}',
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M.y – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			yMEd => {
				M => q{E d.M.y – E d.M.y GGGGG},
				d => q{E d. – E d.M.y GGGGG},
				y => q{E d.M.y – E d.M.y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d. – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d. – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G 'til' y G},
				y => q{y 'til' y G},
			},
			GyM => {
				G => q{M.y G – M.y G},
				M => q{M.y – M.y G},
				y => q{M.y – M.y G},
			},
			GyMEd => {
				G => q{E d.M.y G – E d.M.y G},
				M => q{E d.M.y – E d.M.y G},
				d => q{E d. – E d.M.y G},
				y => q{E d.M.y – E d.M.y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d. – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d.M.y G – d.M.y G},
				M => q{d.M.y – d.M.y G},
				d => q{d. – d.M.y G},
				y => q{d.M.y – d.M.y G},
			},
			H => {
				H => q{H – H 'h'.},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E d.M – E d.M},
				d => q{E d.M – E d.M},
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
				M => q{d.M – d.M},
				d => q{d. – d.M},
			},
			d => {
				d => q{d. – d.},
			},
			fallback => '{0} til {1}',
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M.y – M.y},
				y => q{M.y – M.y},
			},
			yMEd => {
				M => q{E d.M.y – E d.M.y},
				d => q{E d. – E d.M.y},
				y => q{E d.M.y – E d.M.y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d.M.y – d.M.y},
				d => q{d. – d.M.y},
				y => q{d.M.y – d.M.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(TMG{0}),
		gmtZeroFormat => q(TMG),
		regionFormat => q(témpor de {0}),
		regionFormat => q(témpor estival de {0}),
		regionFormat => q(témpor standard de {0}),
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis-Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar-es-Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El-Aaiun#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugu#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São-Tomé#,
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaskan estival témpor#,
				'generic' => q#alaskan témpor#,
				'standard' => q#alaskan standard témpor#,
			},
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La-Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio-Gallegos#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#Sant-Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Sant-Luis#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#bay de Banderas#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa-Vista#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos-Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge-Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo-Grande#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Ciudad-Juarez#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa-Rica#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson-Creek#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El-Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort-Nelson#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace-Bay#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose-Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand-Turk#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadelupa#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell-City, Indiana#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La-Paz#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los-Angeles#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower-Prince’s-Quarter#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexican Cité#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Nord-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Nord-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Nord-Dakota#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto-Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto-Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta-Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy-River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin-Inlet#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio-Branco#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#San-Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São-Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sant-Bartolomeo#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St.-John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St.-Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St.-Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St.-Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St.-Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift-Current#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder-Bay#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#american central estival témpor#,
				'generic' => q#american central témpor#,
				'standard' => q#american central standard témpor#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#american oriental estival témpor#,
				'generic' => q#american oriental témpor#,
				'standard' => q#american oriental standard témpor#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#american montan estival témpor#,
				'generic' => q#american montan témpor#,
				'standard' => q#american montan standard témpor#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#american pacific estival témpor#,
				'generic' => q#american pacific témpor#,
				'standard' => q#american pacific standard témpor#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont-d’Urville#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Showa#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong-Kong#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala-Lumpur#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom-Penh#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilorda#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho-Chi-Minh#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#american atlantic estival témpor#,
				'generic' => q#american atlantic témpor#,
				'standard' => q#american atlantic standard témpor#,
			},
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canaria#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cap-Verdi#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Feroe#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Sud-Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sant-Helena#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken-Hill#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Insul Lord-Howe#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pert#,
		},
		'Azores' => {
			long => {
				'daylight' => q#témpor estival del Azores#,
				'generic' => q#témpor del Azores#,
				'standard' => q#témpor standard del Azores#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#témpor del Insul Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#témpor del Insules Cocos#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#témpor estival del Insules Cook#,
				'generic' => q#témpor del Insules Cook#,
				'standard' => q#témpor standard del Insules Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#cuban estival témpor#,
				'generic' => q#cuban témpor#,
				'standard' => q#cuban standard témpor#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#universal témpor coordinat#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ínconosset cité#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Aten#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucuresti#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#København#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#irlandesi standard témpor#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Insul de Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#britanic estival témpor#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mónaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscva#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San-Marino#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warszawa#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#central europan estival témpor#,
				'generic' => q#central europan témpor#,
				'standard' => q#central europan standard témpor#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ost-europan estival témpor#,
				'generic' => q#ost-europan témpor#,
				'standard' => q#ost-europan standard témpor#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#west-europan estival témpor#,
				'generic' => q#west-europan témpor#,
				'standard' => q#west-europan standard témpor#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#témpor estival del Insules Falkland#,
				'generic' => q#témpor del Insules Falkland#,
				'standard' => q#témpor standard del Insules Falkland#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#témpore medial de Greenwich#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#témpor del Insules Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#témpor estival del oriental Greenland#,
				'generic' => q#témpor del oriental Greenland#,
				'standard' => q#témpor standard del oriental Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#témpor estival del occidental Greenland#,
				'generic' => q#témpor del occidental Greenland#,
				'standard' => q#témpor standard del occidental Greenland#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#témpor estival de Hawai e Aleutes#,
				'generic' => q#témpor de Hawai e Aleutes#,
				'standard' => q#témpor standard de Hawai e Aleutes#,
			},
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauricio#,
		},
		'Line_Islands' => {
			long => {
				'standard' => q#témpor del Insules Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#témpor estival del Insul Lord-Howe#,
				'generic' => q#témpor del Insul Lord-Howe#,
				'standard' => q#témpor standard del Insul Lord-Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#témpor del Insul Macquarie#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#témpor del Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#témpor del Insules Marshall#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#mexican nordwest estival témpor#,
				'generic' => q#mexican nordwest témpor#,
				'standard' => q#mexican nordwest standard témpor#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#mexican pacific estival témpor#,
				'generic' => q#mexican pacific témpor#,
				'standard' => q#mexican pacific standard témpor#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#témpor estival de Newfoundland#,
				'generic' => q#témpor de Newfoundland#,
				'standard' => q#témpor standard de Newfoundland#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#témpor estival del Insul Norfolk#,
				'generic' => q#témpor del Insul Norfolk#,
				'standard' => q#témpor standard del Insul Norfolk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasca#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidji#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago-Pago#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port-Moresby#,
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#témpor del Insules Fénix#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#témpor del Insules Solomon#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#témpor del Insul Wake#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#témpor de Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
