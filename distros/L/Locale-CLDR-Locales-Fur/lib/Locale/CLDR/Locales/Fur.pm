=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fur - Package for language Friulian

=cut

package Locale::CLDR::Locales::Fur;
# This file auto generated from Data\common\main\fur.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'afar',
 				'ab' => 'abcazian',
 				'ae' => 'avestan',
 				'af' => 'afrikaans',
 				'am' => 'amaric',
 				'an' => 'aragonês',
 				'ang' => 'vieri inglês',
 				'ar' => 'arap',
 				'arc' => 'aramaic',
 				'as' => 'assamês',
 				'ast' => 'asturian',
 				'av' => 'avar',
 				'ay' => 'aymarà',
 				'az' => 'azerbaijani',
 				'be' => 'bielorùs',
 				'bg' => 'bulgar',
 				'bn' => 'bengalês',
 				'bo' => 'tibetan',
 				'br' => 'breton',
 				'bs' => 'bosniac',
 				'ca' => 'catalan',
 				'ce' => 'cecen',
 				'ch' => 'chamorro',
 				'co' => 'cors',
 				'cop' => 'coptic',
 				'cr' => 'cree',
 				'cs' => 'cec',
 				'cu' => 'sclâf de glesie',
 				'cy' => 'galês',
 				'da' => 'danês',
 				'de' => 'todesc',
 				'de_AT' => 'todesc de Austrie',
 				'de_CH' => 'alt todesc de Svuizare',
 				'den' => 'sclâf',
 				'egy' => 'vieri egjizian',
 				'el' => 'grêc',
 				'en' => 'inglês',
 				'en_AU' => 'inglês australian',
 				'en_CA' => 'inglês canadês',
 				'en_GB' => 'inglês britanic',
 				'en_US' => 'ingles merecan',
 				'eo' => 'esperanto',
 				'es' => 'spagnûl',
 				'es_419' => 'spagnûl de Americhe Latine',
 				'es_ES' => 'spagnûl iberic',
 				'et' => 'eston',
 				'eu' => 'basc',
 				'fa' => 'persian',
 				'ff' => 'fulah',
 				'fi' => 'finlandês',
 				'fil' => 'filipin',
 				'fj' => 'fizian',
 				'fo' => 'faroês',
 				'fr' => 'francês',
 				'fr_CA' => 'francês dal Canade',
 				'fr_CH' => 'francês de Svuizare',
 				'fro' => 'vieri francês',
 				'fur' => 'furlan',
 				'fy' => 'frisian',
 				'ga' => 'gaelic irlandês',
 				'gd' => 'gaelic scozês',
 				'gl' => 'galizian',
 				'gn' => 'guaranì',
 				'got' => 'gotic',
 				'grc' => 'vieri grêc',
 				'gu' => 'gujarati',
 				'gv' => 'manx',
 				'he' => 'ebraic',
 				'hi' => 'hindi',
 				'hr' => 'cravuat',
 				'ht' => 'haitian',
 				'hu' => 'ongjarês',
 				'hy' => 'armen',
 				'id' => 'indonesian',
 				'ig' => 'igbo',
 				'ik' => 'inupiaq',
 				'io' => 'ido',
 				'is' => 'islandês',
 				'it' => 'talian',
 				'iu' => 'inuktitut',
 				'ja' => 'gjaponês',
 				'ka' => 'gjeorgjian',
 				'kk' => 'kazac',
 				'kl' => 'kalaallisut',
 				'km' => 'khmer',
 				'kn' => 'kannada',
 				'ko' => 'corean',
 				'ku' => 'curd',
 				'kw' => 'cornualiês',
 				'la' => 'latin',
 				'lad' => 'ladin',
 				'lb' => 'lussemburghês',
 				'li' => 'limburghês',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lt' => 'lituan',
 				'lv' => 'leton',
 				'mg' => 'malagasy',
 				'mi' => 'maori',
 				'mk' => 'macedon',
 				'ml' => 'malayalam',
 				'mn' => 'mongul',
 				'mr' => 'marathi',
 				'ms' => 'malês',
 				'mt' => 'maltês',
 				'mul' => 'lenghis multiplis',
 				'mwl' => 'mirandês',
 				'nap' => 'napoletan',
 				'nb' => 'norvegjês bokmål',
 				'nd' => 'ndebele setentrionâl',
 				'nds' => 'bas todesc',
 				'ne' => 'nepalês',
 				'nl' => 'olandês',
 				'nl_BE' => 'flamant',
 				'nn' => 'norvegjês nynorsk',
 				'no' => 'norvegjês',
 				'non' => 'vieri norvegjês',
 				'nso' => 'sotho setentrionâl',
 				'nv' => 'navajo',
 				'oc' => 'ocitan',
 				'or' => 'oriya',
 				'os' => 'osetic',
 				'ota' => 'turc otoman',
 				'pa' => 'punjabi',
 				'pap' => 'papiamento',
 				'peo' => 'vieri persian',
 				'pl' => 'polac',
 				'pro' => 'vieri provenzâl',
 				'ps' => 'pashto',
 				'pt' => 'portughês',
 				'pt_BR' => 'portughês brasilian',
 				'pt_PT' => 'portughês iberic',
 				'qu' => 'quechua',
 				'rm' => 'rumanç',
 				'ro' => 'romen',
 				'ro_MD' => 'moldâf',
 				'ru' => 'rus',
 				'sa' => 'sanscrit',
 				'sc' => 'sardegnûl',
 				'scn' => 'sicilian',
 				'sco' => 'scozês',
 				'sd' => 'sindhi',
 				'se' => 'sami setentrionâl',
 				'sg' => 'sango',
 				'sga' => 'vieri irlandês',
 				'si' => 'sinalês',
 				'sk' => 'slovac',
 				'sl' => 'sloven',
 				'sm' => 'samoan',
 				'so' => 'somal',
 				'sq' => 'albanês',
 				'sr' => 'serp',
 				'ss' => 'swati',
 				'st' => 'sotho meridionâl',
 				'su' => 'sundanês',
 				'sux' => 'sumeric',
 				'sv' => 'svedês',
 				'sw' => 'swahili',
 				'ta' => 'tamil',
 				'te' => 'telegu',
 				'tet' => 'tetum',
 				'tg' => 'tagic',
 				'th' => 'thai',
 				'tk' => 'turcmen',
 				'tl' => 'tagalog',
 				'tr' => 'turc',
 				'tt' => 'tartar',
 				'ty' => 'tahitian',
 				'ug' => 'uigur',
 				'uk' => 'ucrain',
 				'und' => 'indeterminade',
 				'ur' => 'urdu',
 				'uz' => 'uzbec',
 				've' => 'venda',
 				'vi' => 'vietnamite',
 				'wa' => 'valon',
 				'wo' => 'wolof',
 				'xh' => 'xhosa',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'zh' => 'cinês',
 				'zh_Hans' => 'cinês semplificât',
 				'zh_Hant' => 'cinês tradizionâl',
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
			'Arab' => 'arap',
 			'Armn' => 'armen',
 			'Bali' => 'balinês',
 			'Beng' => 'bengalês',
 			'Brai' => 'Braille',
 			'Bugi' => 'buginês',
 			'Cans' => 'Silabari unificât aborigjens canadês',
 			'Copt' => 'copt',
 			'Cprt' => 'cipriot',
 			'Cyrl' => 'cirilic',
 			'Cyrs' => 'cirilic dal vieri slavonic de glesie',
 			'Deva' => 'devanagari',
 			'Egyd' => 'demotic egjizian',
 			'Egyh' => 'jeratic egjizian',
 			'Egyp' => 'jeroglifics egjizians',
 			'Ethi' => 'etiopic',
 			'Geor' => 'georgjian',
 			'Glag' => 'glagolitic',
 			'Goth' => 'gotic',
 			'Grek' => 'grêc',
 			'Gujr' => 'gujarati',
 			'Hani' => 'han',
 			'Hans' => 'Han semplificât',
 			'Hant' => 'Han tradizionâl',
 			'Hebr' => 'ebreu',
 			'Hrkt' => 'katakana o hiragana',
 			'Hung' => 'vieri ongjarês',
 			'Ital' => 'vieri italic',
 			'Java' => 'gjavanês',
 			'Jpan' => 'gjaponês',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'corean',
 			'Laoo' => 'lao',
 			'Latf' => 'latin Fraktur',
 			'Latg' => 'latin gaelic',
 			'Latn' => 'latin',
 			'Lina' => 'lineâr A',
 			'Linb' => 'lineâr B',
 			'Maya' => 'jeroglifics Maya',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongul',
 			'Mymr' => 'myanmar',
 			'Orya' => 'oriya',
 			'Runr' => 'runic',
 			'Sinh' => 'sinhala',
 			'Syrc' => 'siriac',
 			'Syre' => 'siriac Estrangelo',
 			'Syrj' => 'siriac ocidentâl',
 			'Syrn' => 'siriac orientâl',
 			'Taml' => 'tamil',
 			'Telu' => 'telegu',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'thai',
 			'Tibt' => 'tibetan',
 			'Ugar' => 'ugaritic',
 			'Xpeo' => 'vieri persian',
 			'Xsux' => 'cuneiform sumeric-acadic',
 			'Zxxx' => 'codiç pes lenghis no scritis',
 			'Zyyy' => 'comun',
 			'Zzzz' => 'codiç par scrituris no codificadis',

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
			'001' => 'Mont',
 			'002' => 'Afriche',
 			'003' => 'Americhe dal Nord',
 			'005' => 'Americhe meridionâl',
 			'009' => 'Oceanie',
 			'011' => 'Afriche ocidentâl',
 			'013' => 'Americhe centrâl',
 			'014' => 'Afriche orientâl',
 			'015' => 'Afriche setentrionâl',
 			'017' => 'Afriche di mieç',
 			'018' => 'Afriche meridionâl',
 			'019' => 'Americhis',
 			'021' => 'Americhe setentrionâl',
 			'029' => 'caraibic',
 			'030' => 'Asie orientâl',
 			'034' => 'Asie meridionâl',
 			'035' => 'Asie sud orientâl',
 			'039' => 'Europe meridionâl',
 			'053' => 'Australie e Gnove Zelande',
 			'054' => 'Melanesie',
 			'057' => 'Regjon de Micronesie',
 			'061' => 'Polinesie',
 			'142' => 'Asie',
 			'143' => 'Asie centrâl',
 			'145' => 'Asie ocidentâl',
 			'150' => 'Europe',
 			'151' => 'Europe orientâl',
 			'154' => 'Europe setentrionâl',
 			'155' => 'Europe ocidentâl',
 			'419' => 'Americhe latine',
 			'AD' => 'Andorra',
 			'AE' => 'Emirâts araps unîts',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanie',
 			'AM' => 'Armenie',
 			'AO' => 'Angola',
 			'AQ' => 'Antartic',
 			'AR' => 'Argjentine',
 			'AS' => 'Samoa merecanis',
 			'AT' => 'Austrie',
 			'AU' => 'Australie',
 			'AW' => 'Aruba',
 			'AX' => 'Isulis Aland',
 			'AZ' => 'Azerbaigian',
 			'BA' => 'Bosnie e Ercegovine',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgjiche',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarie',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sant Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivie',
 			'BR' => 'Brasîl',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Isule Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorussie',
 			'BZ' => 'Belize',
 			'CA' => 'Canade',
 			'CC' => 'Isulis Cocos',
 			'CD' => 'Republiche Democratiche dal Congo',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'Republiche centri africane',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Congo (Republiche)',
 			'CH' => 'Svuizare',
 			'CI' => 'Cueste di Avoli',
 			'CK' => 'Isulis Cook',
 			'CL' => 'Cile',
 			'CM' => 'Camerun',
 			'CN' => 'Cine',
 			'CO' => 'Colombie',
 			'CP' => 'Isule Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cjâf vert',
 			'CX' => 'Isule Christmas',
 			'CY' => 'Cipri',
 			'CZ' => 'Republiche ceche',
 			'DE' => 'Gjermanie',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Gibuti',
 			'DK' => 'Danimarcje',
 			'DM' => 'Dominiche',
 			'DO' => 'Republiche dominicane',
 			'DZ' => 'Alzerie',
 			'EA' => 'Ceuta e Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonie',
 			'EG' => 'Egjit',
 			'EH' => 'Sahara ocidentâl',
 			'ER' => 'Eritree',
 			'ES' => 'Spagne',
 			'ET' => 'Etiopie',
 			'EU' => 'Union europeane',
 			'FI' => 'Finlandie',
 			'FJ' => 'Fizi',
 			'FK' => 'Isulis Falkland',
 			'FK@alt=variant' => 'Isulis Falkland (Isulis Malvinas)',
 			'FM' => 'Micronesie',
 			'FO' => 'Isulis Faroe',
 			'FR' => 'France',
 			'GA' => 'Gabon',
 			'GB' => 'Ream unît',
 			'GD' => 'Grenada',
 			'GE' => 'Gjeorgjie',
 			'GF' => 'Guiana francês',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gjibraltar',
 			'GL' => 'Groenlande',
 			'GM' => 'Gambia',
 			'GN' => 'Guinee',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinee ecuatoriâl',
 			'GR' => 'Grecie',
 			'GS' => 'Georgia dal Sud e Isulis Sandwich dal Sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Regjon aministrative speciâl de Cine di Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Isule Heard e Isulis McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Cravuazie',
 			'HT' => 'Haiti',
 			'HU' => 'Ongjarie',
 			'IC' => 'Isulis Canariis',
 			'ID' => 'Indonesie',
 			'IE' => 'Irlande',
 			'IL' => 'Israêl',
 			'IM' => 'Isule di Man',
 			'IN' => 'India',
 			'IO' => 'Teritori britanic dal Ocean Indian',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Islande',
 			'IT' => 'Italie',
 			'JE' => 'Jersey',
 			'JM' => 'Gjamaiche',
 			'JO' => 'Jordanie',
 			'JP' => 'Gjapon',
 			'KE' => 'Kenya',
 			'KG' => 'Kirghizstan',
 			'KH' => 'Camboze',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoris',
 			'KN' => 'San Kitts e Nevis',
 			'KP' => 'Coree dal nord',
 			'KR' => 'Coree dal sud',
 			'KW' => 'Kuwait',
 			'KY' => 'Isulis Cayman',
 			'KZ' => 'Kazachistan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Sante Lusie',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberie',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituanie',
 			'LU' => 'Lussemburc',
 			'LV' => 'Letonie',
 			'LY' => 'Libie',
 			'MA' => 'Maroc',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavie',
 			'ME' => 'Montenegro',
 			'MF' => 'Sant Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Isulis Marshall',
 			'ML' => 'Mali',
 			'MM' => 'Birmanie',
 			'MN' => 'Mongolie',
 			'MO' => 'Regjon aministrative speciâl de Cine di Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Isulis Mariana dal Nord',
 			'MQ' => 'Martiniche',
 			'MR' => 'Mauritanie',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurizi',
 			'MV' => 'Maldivis',
 			'MW' => 'Malawi',
 			'MX' => 'Messic',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambic',
 			'NA' => 'Namibie',
 			'NC' => 'Gnove Caledonie',
 			'NE' => 'Niger',
 			'NF' => 'Isole Norfolk',
 			'NG' => 'Nigerie',
 			'NI' => 'Nicaragua',
 			'NL' => 'Paîs bas',
 			'NO' => 'Norvegje',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Gnove Zelande',
 			'OM' => 'Oman',
 			'PA' => 'Panamà',
 			'PE' => 'Perù',
 			'PF' => 'Polinesie francês',
 			'PG' => 'Papue Gnove Guinee',
 			'PH' => 'Filipinis',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonie',
 			'PM' => 'San Pierre e Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Porto Rico',
 			'PS' => 'Teritoris palestinês',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oceanie periferiche',
 			'RE' => 'Reunion',
 			'RO' => 'Romanie',
 			'RS' => 'Serbie',
 			'RU' => 'Russie',
 			'RW' => 'Ruande',
 			'SA' => 'Arabie Saudide',
 			'SB' => 'Isulis Salomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Svezie',
 			'SG' => 'Singapore',
 			'SH' => 'Sante Eline',
 			'SI' => 'Slovenie',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Slovachie',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marin',
 			'SN' => 'Senegal',
 			'SO' => 'Somalie',
 			'SR' => 'Suriname',
 			'ST' => 'Sao Tomè e Principe',
 			'SV' => 'El Salvador',
 			'SY' => 'Sirie',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Isulis Turks e Caicos',
 			'TD' => 'Çad',
 			'TF' => 'Teritoris meridionâi francês',
 			'TG' => 'Togo',
 			'TH' => 'Tailandie',
 			'TJ' => 'Tazikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor orientâl',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisie',
 			'TO' => 'Tonga',
 			'TR' => 'Turchie',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzanie',
 			'UA' => 'Ucraine',
 			'UG' => 'Uganda',
 			'UM' => 'Isulis periferichis minôrs dai Stâts Unîts',
 			'US' => 'Stâts Unîts',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbechistan',
 			'VA' => 'Vatican',
 			'VC' => 'San Vincent e lis Grenadinis',
 			'VE' => 'Venezuela',
 			'VG' => 'Isulis vergjinis britanichis',
 			'VI' => 'Isulis vergjinis americanis',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sud Afriche',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Regjon no cognossude o no valide',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Ortografie todescje tradizionâl',
 			'1994' => 'Ortografie resiane standard',
 			'1996' => 'Ortografie todescje dal 1996',
 			'AREVELA' => 'armen orientâl',
 			'AREVMDA' => 'armen ocidentâl',
 			'BISKE' => 'dialet di San Zorç di Resie',
 			'LIPAW' => 'dialet di Lipovaz dal resian',
 			'NEDIS' => 'Dialet des valadis dal Nadison',
 			'NJIVA' => 'dialet di Gnive',
 			'OSOJS' => 'dialet di Oseac',
 			'POLYTON' => 'Politoniche',
 			'REVISED' => 'Ortografie revisade',
 			'ROZAJ' => 'Resian',
 			'SOLBA' => 'dialet di Stolvize',
 			'VALENCIA' => 'valenzian',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'calendari',
 			'collation' => 'ordenament',
 			'currency' => 'monede',

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
 				'buddhist' => q{calendari budist},
 				'chinese' => q{calendari cinês},
 				'gregorian' => q{calendari gregorian},
 				'hebrew' => q{calendari ebreu},
 				'indian' => q{calendari nazionâl indian},
 				'islamic' => q{calendari islamic},
 				'islamic-civil' => q{calendari islamic civîl},
 				'japanese' => q{calendari gjaponês},
 				'roc' => q{calendari de Republiche di Cine},
 			},
 			'collation' => {
 				'big5han' => q{ordin cinês tradizionâl - Big5},
 				'ducet' => q{ordenament predeterminât Unicode},
 				'gb2312han' => q{ordin cinês semplificât - GB2312},
 				'phonebook' => q{ordin elenc telefonic},
 				'pinyin' => q{ordin pinyin},
 				'search' => q{ricercje par fins gjenerâi},
 				'stroke' => q{ordin segns},
 				'traditional' => q{ordin tradizionâl},
 			},
 			'numbers' => {
 				'latn' => q{numars ocidentâi},
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
 			'UK' => q{Ream Unît},
 			'US' => q{USA},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lenghe: {0}',
 			'script' => 'Scriture: {0}',
 			'region' => 'Regjon: {0}',

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
			auxiliary => qr{[å č é ë ğ ï ñ ó š ü]},
			index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a à â b c ç d e è ê f g h i ì î j k l m n o ò ô p q r s t u ù û v w x y z]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
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
					'duration-day' => {
						'name' => q(zornadis),
						'one' => q({0} zornade),
						'other' => q({0} zornadis),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(zornadis),
						'one' => q({0} zornade),
						'other' => q({0} zornadis),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(oris),
						'one' => q({0} ore),
						'other' => q({0} oris),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(oris),
						'one' => q({0} ore),
						'other' => q({0} oris),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minûts),
						'one' => q({0} minût),
						'other' => q({0} minûts),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minûts),
						'one' => q({0} minût),
						'other' => q({0} minûts),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mês),
						'one' => q({0} mês),
						'other' => q({0} mês),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mês),
						'one' => q({0} mês),
						'other' => q({0} mês),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(seconts),
						'one' => q({0} secont),
						'other' => q({0} seconts),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(seconts),
						'one' => q({0} secont),
						'other' => q({0} seconts),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(setemanis),
						'one' => q({0} setemane),
						'other' => q({0} setemanis),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(setemanis),
						'one' => q({0} setemane),
						'other' => q({0} setemanis),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(agns),
						'one' => q({0} an),
						'other' => q({0} agns),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(agns),
						'one' => q({0} an),
						'other' => q({0} agns),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(zornadis),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(zornadis),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(oris),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(oris),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minûts),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minûts),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mês),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mês),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(seconts),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(seconts),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(setemanis),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(setemanis),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(agns),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(agns),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:sì|si|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:no|n)$' }
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
			'exponential' => q(E),
			'group' => q(.),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0.###',
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
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
		'AMD' => {
			display_name => {
				'currency' => q(Dram armen),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso argjentin),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Selin austriac),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dolar australian),
				'one' => q(dolar australian),
				'other' => q(dolars australians),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Franc de Belgjiche),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franc burundês),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dolar dal Brunei),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(real brasilian),
				'one' => q(real brasilian),
				'other' => q(real brasilians),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rubli bielorùs),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rubli bielorùs \(2000–2016\)),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dolar canadês),
				'one' => q(dolar canadês),
				'other' => q(dolars canadês),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franc svuizar),
				'one' => q(franc svuizar),
				'other' => q(francs svuizars),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan cinês),
				'one' => q(yuan cinês),
				'other' => q(yuan cinês),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Vieri dinar serp),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso cuban),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Corone de Republiche Ceche),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Marc todesc),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(corone danese),
				'one' => q(corone danese),
				'other' => q(coronis danesis),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar algerin),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franc francês),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(sterline britaniche),
				'one' => q(sterline britaniche),
				'other' => q(sterlinis britanichis),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(dolar di Hong Kong),
				'one' => q(dolar di Hong Kong),
				'other' => q(dolars di Hong Kong),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Dinar cravuat),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna cravuate),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupiah indonesiane),
				'one' => q(rupiah indonesiane),
				'other' => q(rupiah indonesianis),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupie indiane),
				'one' => q(rupie indiane),
				'other' => q(rupiis indianis),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial iranian),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Lire taliane),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen gjaponês),
				'one' => q(yen gjaponês),
				'other' => q(yen gjaponês),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(won de Coree dal Sud),
				'one' => q(won de Coree dal Sud),
				'other' => q(won de Coree dal Sud),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats leton),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(peso messican),
				'one' => q(peso messican),
				'other' => q(pesos messicans),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolar namibian),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Córdoba oro nicaraguan),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(corone norvegjese),
				'one' => q(corone norvegjese),
				'other' => q(coronis norvegjesis),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dollar neozelandês),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupie pachistane),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty polac),
				'one' => q(zloty polac),
				'other' => q(zloty polacs),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar serp),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rubli rus),
				'one' => q(rubli rus),
				'other' => q(rublis rus),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riyal de Arabie Saudite),
				'one' => q(riyal de Arabie Saudite),
				'other' => q(riyals de Arabie Saudite),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(corone svedese),
				'one' => q(corone svedese),
				'other' => q(coronis svedesis),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Talar sloven),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Corone slovache),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandês),
				'one' => q(baht tailandês),
				'other' => q(baht tailandês),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Viere Lire turche),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(lire turche),
				'one' => q(lire turche),
				'other' => q(liris turchis),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(gnûf dolar taiwanês),
				'one' => q(gnûf dolar taiwanês),
				'other' => q(gnûfs dolars taiwanês),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dolar american),
				'one' => q(dolar american),
				'other' => q(dolars americans),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Dolar american \(prossime zornade\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Dolar american \(stesse zornade\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Arint),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Aur),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Unitât composite europeane),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Unitât monetarie europeane),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Unitât di acont europeane \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Unitât di acont europeane \(XBD\)),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Dirits speciâi di incas),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Franc aur francês),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Franc UIC francês),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paladi),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(fonts RINET),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(codiç di verifiche de monede),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Monede no valide o no cognossude),
				'one' => q(Monede no valide o no cognossude),
				'other' => q(Monedis no validis o no cognossudis),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sudafrican),
				'one' => q(rand sudafrican),
				'other' => q(rands sudafricans),
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
							'Zen',
							'Fev',
							'Mar',
							'Avr',
							'Mai',
							'Jug',
							'Lui',
							'Avo',
							'Set',
							'Otu',
							'Nov',
							'Dic'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Z',
							'F',
							'M',
							'A',
							'M',
							'J',
							'L',
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
							'Zenâr',
							'Fevrâr',
							'Març',
							'Avrîl',
							'Mai',
							'Jugn',
							'Lui',
							'Avost',
							'Setembar',
							'Otubar',
							'Novembar',
							'Dicembar'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Zen',
							'Fev',
							'Mar',
							'Avr',
							'Mai',
							'Jug',
							'Lui',
							'Avo',
							'Set',
							'Otu',
							'Nov',
							'Dic'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Z',
							'F',
							'M',
							'A',
							'M',
							'J',
							'L',
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
							'Zenâr',
							'Fevrâr',
							'Març',
							'Avrîl',
							'Mai',
							'Jugn',
							'Lui',
							'Avost',
							'Setembar',
							'Otubar',
							'Novembar',
							'Dicembar'
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
						thu => 'joi',
						fri => 'vin',
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
					wide => {
						mon => 'lunis',
						tue => 'martars',
						wed => 'miercus',
						thu => 'joibe',
						fri => 'vinars',
						sat => 'sabide',
						sun => 'domenie'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'lun',
						tue => 'mar',
						wed => 'mie',
						thu => 'joi',
						fri => 'vin',
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
					wide => {
						mon => 'lunis',
						tue => 'martars',
						wed => 'miercus',
						thu => 'joibe',
						fri => 'vinars',
						sat => 'sabide',
						sun => 'domenie'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Prin trimestri',
						1 => 'Secont trimestri',
						2 => 'Tierç trimestri',
						3 => 'Cuart trimestri'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					wide => {0 => 'Prin trimestri',
						1 => 'Secont trimestri',
						2 => 'Tierç trimestri',
						3 => 'Cuart trimestri'
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
					'am' => q{a.},
					'pm' => q{p.},
				},
				'wide' => {
					'am' => q{a.},
					'pm' => q{p.},
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
				'0' => 'pdC',
				'1' => 'ddC'
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
			'full' => q{EEEE d 'di' MMMM 'dal' y G},
			'long' => q{d 'di' MMMM 'dal' y G},
			'medium' => q{dd/MM/y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d 'di' MMMM 'dal' y},
			'long' => q{d 'di' MMMM 'dal' y},
			'medium' => q{dd/MM/y},
			'short' => q{dd/MM/yy},
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
		'generic' => {
			Ed => q{d E},
			Hm => q{H:mm},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d 'di' MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			Md => q{d/M},
			d => q{d},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{LLLL 'dal' y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{d E},
			Hm => q{H:mm},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d 'di' MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			Md => q{d/M},
			d => q{d},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{LLLL 'dal' y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
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
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E d 'di' MMM – E d 'di' MMM},
				d => q{E d – E d 'di' MMM},
			},
			MMMd => {
				M => q{d 'di' MMM – d 'di' MMM},
				d => q{d–d 'di' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MM – MM/y},
				y => q{MM/y – MM/y},
			},
			yMMMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMMM => {
				M => q{MM – MM/y},
				y => q{MM/y – MM/y},
			},
			yMMMd => {
				M => q{dd/MM/y – d/MM},
				d => q{d – d/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E d 'di' MMM – E d 'di' MMM},
				d => q{E d – E d 'di' MMM},
			},
			MMMd => {
				M => q{d 'di' MMM – d 'di' MMM},
				d => q{d–d 'di' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MM – MM/y},
				y => q{MM/y – MM/y},
			},
			yMMMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMMM => {
				M => q{MM – MM/y},
				y => q{MM/y – MM/y},
			},
			yMMMd => {
				M => q{dd/MM/y – d/MM},
				d => q{d – d/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		fallbackFormat => q({1} ({0})),
		'America/New_York' => {
			exemplarCity => q#Gnove York#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Pauli dal Brasîl#,
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoris#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canariis#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#Citât no cognossude#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrât#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbone#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubiane#,
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lussemburc#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malte#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosche#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praghe#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marin#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viene#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ore estive de Europe centrâl#,
				'generic' => q#Ore de Europe centrâl#,
				'standard' => q#Ore standard de Europe centrâl#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ore estive de Europe orientâl#,
				'generic' => q#Ore de Europe orientâl#,
				'standard' => q#Ore standard de Europe orientâl#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ore estive de Europe ocidentâl#,
				'generic' => q#Ore de Europe ocidentâl#,
				'standard' => q#Ore standard de Europe ocidentâl#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'GMT' => {
			short => {
				'standard' => q#GMT#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Ore estive di Mosche#,
				'generic' => q#Ore di Mosche#,
				'standard' => q#Ore standard di Mosche#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
