=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kea - Package for language Kabuverdianu

=cut

package Locale::CLDR::Locales::Kea;
# This file auto generated from Data\common\main\kea.xml
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
				'ab' => 'abkáziu',
 				'af' => 'afrikaner',
 				'agq' => 'aghem',
 				'ak' => 'akan',
 				'am' => 'amáriku',
 				'an' => 'argones',
 				'ar' => 'árabi',
 				'ar_001' => 'árabi mudernu',
 				'arn' => 'araukanu',
 				'as' => 'asames',
 				'asa' => 'asu',
 				'ast' => 'asturianu',
 				'ay' => 'aimara',
 				'az' => 'azerbaijanu',
 				'az@alt=short' => 'azeri',
 				'ba' => 'baxkir',
 				'ban' => 'balines',
 				'bas' => 'basa',
 				'be' => 'bielorusu',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'búlgaru',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tibetanu',
 				'br' => 'bretãu',
 				'brx' => 'bodo',
 				'bs' => 'bosniu',
 				'ca' => 'katalãu',
 				'ccp' => 'xakma',
 				'ce' => 'txetxenu',
 				'ceb' => 'sebuanu',
 				'cgg' => 'xiga',
 				'chr' => 'xeroki',
 				'ckb' => 'kurdu sentral',
 				'co' => 'kórsiku',
 				'cs' => 'txeku',
 				'cu' => 'slavu klériku',
 				'cv' => 'txuvaxi',
 				'cy' => 'gales',
 				'da' => 'dinamarkes',
 				'dav' => 'taita',
 				'de' => 'alemon',
 				'de_AT' => 'alemon austríaku',
 				'de_CH' => 'alemon altu suisu',
 				'dje' => 'zarma',
 				'dsb' => 'sórbiu baxu',
 				'dua' => 'duala',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzonka',
 				'ebu' => 'embu',
 				'ee' => 'eve',
 				'el' => 'gregu',
 				'en' => 'ingles',
 				'en_AU' => 'ingles australianu',
 				'en_CA' => 'ingles kanadianu',
 				'en_GB' => 'ingles britániku',
 				'en_GB@alt=short' => 'ingles (R.U.)',
 				'en_US' => 'ingles merkanu',
 				'en_US@alt=short' => 'ingles (S.U.)',
 				'eo' => 'sperantu',
 				'es' => 'spanhol',
 				'es_419' => 'spanhol latinu-merkanu',
 				'es_ES' => 'spanhol europeu',
 				'es_MX' => 'spanhol mexikanu',
 				'et' => 'stonianu',
 				'eu' => 'basku',
 				'ewo' => 'ewondo',
 				'fa' => 'persa',
 				'ff' => 'fula',
 				'fi' => 'finlandes',
 				'fil' => 'filipinu',
 				'fj' => 'fijianu',
 				'fo' => 'faroes',
 				'fr' => 'franses',
 				'fr_CA' => 'franses kanadianu',
 				'fr_CH' => 'franses suisu',
 				'fur' => 'friulanu',
 				'fy' => 'fríziu osidental',
 				'ga' => 'irlandes',
 				'gag' => 'gagauz',
 				'gl' => 'galegu',
 				'gn' => 'guarani',
 				'gsw' => 'alemon suisu',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manks',
 				'ha' => 'auza',
 				'haw' => 'avaianu',
 				'he' => 'ebraiku',
 				'hi' => 'indi',
 				'hmn' => 'hmong',
 				'hr' => 'kroata',
 				'hsb' => 'sórbiu altu',
 				'ht' => 'aitianu',
 				'hu' => 'úngaru',
 				'hy' => 'arméniu',
 				'ia' => 'interlingua',
 				'id' => 'indonéziu',
 				'ig' => 'ibo',
 				'ii' => 'nuosu',
 				'is' => 'islandes',
 				'it' => 'italianu',
 				'iu' => 'inuktitut',
 				'ja' => 'japones',
 				'jgo' => 'ñomba',
 				'jmc' => 'matxame',
 				'jv' => 'javanes',
 				'ka' => 'jorjianu',
 				'kab' => 'kabila',
 				'kam' => 'kamba',
 				'kde' => 'makonde',
 				'kea' => 'kabuverdianu',
 				'khq' => 'koira txiini',
 				'ki' => 'kikuiu',
 				'kk' => 'kazak',
 				'kkj' => 'kako',
 				'kl' => 'groenlandes',
 				'kln' => 'kalenjin',
 				'km' => 'kmer',
 				'kn' => 'kanares',
 				'ko' => 'korianu',
 				'koi' => 'komi-permiak',
 				'kok' => 'konkani',
 				'ks' => 'kaxmira',
 				'ksf' => 'bafia',
 				'ksh' => 'kolonhanu',
 				'ku' => 'kurdu',
 				'kw' => 'kórniku',
 				'ky' => 'kirgiz',
 				'la' => 'latin',
 				'lag' => 'langi',
 				'lb' => 'luxemburges',
 				'lg' => 'luganda',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'lausianu',
 				'lt' => 'lituanu',
 				'lu' => 'luba-katanga',
 				'luo' => 'luo',
 				'luy' => 'luyia',
 				'lv' => 'letãu',
 				'mg' => 'malgaxi',
 				'mgh' => 'makua',
 				'mi' => 'maori',
 				'mk' => 'masedóniu',
 				'ml' => 'malaialam',
 				'mr' => 'marati',
 				'ms' => 'maláiu',
 				'mt' => 'maltes',
 				'my' => 'birmanes',
 				'nb' => 'norueges bokmål',
 				'nds' => 'alemon baxu',
 				'ne' => 'nepales',
 				'nl' => 'olandes',
 				'nl_BE' => 'flamengu',
 				'nmg' => 'kuazio',
 				'nn' => 'norueges nynorsk',
 				'om' => 'oromo',
 				'or' => 'odía',
 				'os' => 'osétiku',
 				'pa' => 'pandjabi',
 				'pl' => 'pulaku',
 				'prg' => 'prusianu',
 				'ps' => 'paxto',
 				'pt' => 'purtuges',
 				'pt_BR' => 'purtuges brazileru',
 				'pt_PT' => 'purtuges europeu',
 				'qu' => 'kexua',
 				'quc' => 'kitxe',
 				'rm' => 'romanxi',
 				'rn' => 'rundi',
 				'ro' => 'rumenu',
 				'ro_MD' => 'rumenu moldáviku',
 				'rof' => 'rombu',
 				'ru' => 'rusu',
 				'rw' => 'kiniaruanda',
 				'rwk' => 'rwa',
 				'sa' => 'sánskritu',
 				'sd' => 'sindi',
 				'ses' => 'koiraboro seni',
 				'si' => 'singales',
 				'sk' => 'slovaku',
 				'sl' => 'slovéniu',
 				'smn' => 'inari sami',
 				'so' => 'somali',
 				'sq' => 'albanes',
 				'sr' => 'sérviu',
 				'su' => 'sundanes',
 				'sv' => 'sueku',
 				'sw' => 'suaíli',
 				'sw_CD' => 'suaíli kongoles',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tg' => 'tadjiki',
 				'th' => 'tailandes',
 				'ti' => 'tigrinia',
 				'tk' => 'turkmenu',
 				'to' => 'tonganes',
 				'tr' => 'turku',
 				'tt' => 'tatar',
 				'tzm' => 'tamaziti di Atlas Sentral',
 				'ug' => 'uigur',
 				'uk' => 'ukranianu',
 				'und' => 'língua diskonxedu',
 				'ur' => 'urdu',
 				'uz' => 'uzbeki',
 				'vi' => 'vietnamita',
 				'wo' => 'uolof',
 				'xh' => 'koza',
 				'yo' => 'ioruba',
 				'yue' => 'kantunes',
 				'yue@alt=menu' => 'kantunes (tradisional)',
 				'zgh' => 'tamazait marokinu padron',
 				'zh' => 'xines',
 				'zh@alt=menu' => 'xines, mandarin',
 				'zh_Hans' => 'xines simplifikadu',
 				'zh_Hans@alt=long' => 'xines mandarin (simplificadu)',
 				'zh_Hant' => 'xines tradisional',
 				'zh_Hant@alt=long' => 'xines mandarin (tradisional)',
 				'zu' => 'zulu',
 				'zxx' => 'sen kontiudu linguístiku',

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
			'Arab' => 'arábiku',
 			'Armn' => 'arméniu',
 			'Beng' => 'bengali',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braille',
 			'Cyrl' => 'siríliku',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etiópiku',
 			'Geor' => 'jorjianu',
 			'Grek' => 'gregu',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmuki',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'simplifikadu',
 			'Hans@alt=stand-alone' => 'han simplifikadu',
 			'Hant' => 'tradisional',
 			'Hant@alt=stand-alone' => 'han tradisional',
 			'Hebr' => 'ebraiku',
 			'Hira' => 'iragana',
 			'Hrkt' => 'silabáriu japunes',
 			'Jpan' => 'japones',
 			'Kana' => 'katakana',
 			'Khmr' => 'kmer',
 			'Knda' => 'kanares',
 			'Kore' => 'korianu',
 			'Laoo' => 'lausianu',
 			'Latn' => 'latinu',
 			'Mlym' => 'malaialam',
 			'Mong' => 'mongol',
 			'Mymr' => 'birmanes',
 			'Orya' => 'oriya',
 			'Sinh' => 'singales',
 			'Taml' => 'tamil',
 			'Telu' => 'telugu',
 			'Thaa' => 'taana',
 			'Thai' => 'tailandes',
 			'Tibt' => 'tibetanu',
 			'Zmth' => 'notason matimátiku',
 			'Zsye' => 'emoji',
 			'Zsym' => 'símbulus',
 			'Zxxx' => 'nãu skritu',
 			'Zyyy' => 'komun',
 			'Zzzz' => 'skrita diskonxedu',

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
			'001' => 'Mundu',
 			'002' => 'Áfrika',
 			'003' => 'Merka di Norti',
 			'005' => 'Merka di Sul',
 			'009' => 'Oseania',
 			'011' => 'Áfrika Osidental',
 			'013' => 'Merka Sentral',
 			'014' => 'Áfrika Oriental',
 			'015' => 'Norti di Áfrika',
 			'017' => 'Áfrika Sentral',
 			'018' => 'Sul di Áfrika',
 			'019' => 'Merkas',
 			'021' => 'Norti di Merka',
 			'029' => 'Karaibas',
 			'030' => 'Ázia Oriental',
 			'034' => 'Sul di Ázia',
 			'035' => 'Sudesti Aziátiku',
 			'039' => 'Europa di Sul',
 			'053' => 'Australázia',
 			'054' => 'Melanézia',
 			'057' => 'Rejion di Mikronézia',
 			'061' => 'Polinézia',
 			'142' => 'Ázia',
 			'143' => 'Ázia Sentral',
 			'145' => 'Ázia Osidental',
 			'150' => 'Europa',
 			'151' => 'Europa Oriental',
 			'154' => 'Europa di Norti',
 			'155' => 'Europa Osidental',
 			'202' => 'Áfrika Subisariana',
 			'419' => 'Merka Latinu',
 			'AC' => 'Ilha di Asenson',
 			'AD' => 'Andora',
 			'AE' => 'Emiradus Árabi Unidu',
 			'AF' => 'Afeganistãu',
 			'AG' => 'Antigua i Barbuda',
 			'AI' => 'Angila',
 			'AL' => 'Albánia',
 			'AM' => 'Arménia',
 			'AO' => 'Angola',
 			'AQ' => 'Antártika',
 			'AR' => 'Arjentina',
 			'AS' => 'Samoa Merkanu',
 			'AT' => 'Áustria',
 			'AU' => 'Austrália',
 			'AW' => 'Aruba',
 			'AX' => 'Ilhas Åland',
 			'AZ' => 'Azerbaidjan',
 			'BA' => 'Bósnia i Erzegovina',
 			'BB' => 'Barbadus',
 			'BD' => 'Bangladexi',
 			'BE' => 'Béljika',
 			'BF' => 'Burkina Fasu',
 			'BG' => 'Bulgária',
 			'BH' => 'Barain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'San Bartolomeu',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolívia',
 			'BQ' => 'Karaibas Olandezas',
 			'BR' => 'Brazil',
 			'BS' => 'Baamas',
 			'BT' => 'Butan',
 			'BV' => 'Ilha Buvê',
 			'BW' => 'Botsuana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belizi',
 			'CA' => 'Kanadá',
 			'CC' => 'Ilhas Kokus (Keeling)',
 			'CD' => 'Kongu - Kinxasa',
 			'CD@alt=variant' => 'Repúblika Dimokrátika di Kongu',
 			'CF' => 'Republika Sentru-Afrikanu',
 			'CG' => 'Kongu - Brazavili',
 			'CG@alt=variant' => 'Repúblika di Kongu',
 			'CH' => 'Suisa',
 			'CI' => 'Kosta di Marfin',
 			'CI@alt=variant' => 'Kosta di Marfin (Côte d’Ivoire)',
 			'CK' => 'Ilhas Kuk',
 			'CL' => 'Xili',
 			'CM' => 'Kamarons',
 			'CN' => 'Xina',
 			'CO' => 'Kolómbia',
 			'CP' => 'Ilha Kliperton',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kabu Verdi',
 			'CW' => 'Kurasau',
 			'CX' => 'Ilha di Natal',
 			'CY' => 'Xipri',
 			'CZ' => 'Txékia',
 			'CZ@alt=variant' => 'Repúblika Txeka',
 			'DE' => 'Alimanha',
 			'DG' => 'Diegu Garsia',
 			'DJ' => 'Djibuti',
 			'DK' => 'Dinamarka',
 			'DM' => 'Dominika',
 			'DO' => 'Repúblika Dominikana',
 			'DZ' => 'Arjélia',
 			'EA' => 'Seuta i Melilha',
 			'EC' => 'Ekuador',
 			'EE' => 'Stónia',
 			'EG' => 'Ejitu',
 			'EH' => 'Sara Osidental',
 			'ER' => 'Iritreia',
 			'ES' => 'Spanha',
 			'ET' => 'Etiópia',
 			'EU' => 'Union Europeia',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlándia',
 			'FJ' => 'Fidji',
 			'FK' => 'Ilhas Malvinas',
 			'FK@alt=variant' => 'Ilhas Falkland (Ilhas Malvinas)',
 			'FM' => 'Mikronézia',
 			'FO' => 'Ilhas Faroe',
 			'FR' => 'Fransa',
 			'GA' => 'Gabon',
 			'GB' => 'Reinu Unidu',
 			'GB@alt=short' => 'R.U.',
 			'GD' => 'Granada',
 			'GE' => 'Jiórjia',
 			'GF' => 'Giana Franseza',
 			'GG' => 'Gernzi',
 			'GH' => 'Gana',
 			'GI' => 'Jibraltar',
 			'GL' => 'Gronelándia',
 			'GM' => 'Gámbia',
 			'GN' => 'Gine',
 			'GP' => 'Guadalupi',
 			'GQ' => 'Gine Ekuatorial',
 			'GR' => 'Grésia',
 			'GS' => 'Ilhas Jeórjia di Sul i Sanduixi di Sul',
 			'GT' => 'Guatimala',
 			'GU' => 'Guam',
 			'GW' => 'Gine-Bisau',
 			'GY' => 'Giana',
 			'HK' => 'Hong Kong, Rejion Administrativu Spesial di Xina',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Ilhas Heard i McDonald',
 			'HN' => 'Onduras',
 			'HR' => 'Kroásia',
 			'HT' => 'Aití',
 			'HU' => 'Ungria',
 			'IC' => 'Kanárias',
 			'ID' => 'Indonézia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Ilha di Man',
 			'IN' => 'Índia',
 			'IO' => 'Ilhas Británikas di Índiku',
 			'IQ' => 'Iraki',
 			'IR' => 'Irãu',
 			'IS' => 'Islándia',
 			'IT' => 'Itália',
 			'JE' => 'Jersi',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordánia',
 			'JP' => 'Japon',
 			'KE' => 'Kénia',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Kamoris',
 			'KN' => 'San Kristovan i Nevis',
 			'KP' => 'Koreia di Norti',
 			'KR' => 'Koreia di Sul',
 			'KW' => 'Kueiti',
 			'KY' => 'Ilhas Kaimon',
 			'KZ' => 'Kazakistan',
 			'LA' => 'Laus',
 			'LB' => 'Líbanu',
 			'LC' => 'Santa Lúsia',
 			'LI' => 'Lixenstain',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libéria',
 			'LS' => 'Lezotu',
 			'LT' => 'Lituánia',
 			'LU' => 'Luxemburgu',
 			'LV' => 'Letónia',
 			'LY' => 'Líbia',
 			'MA' => 'Marokus',
 			'MC' => 'Mónaku',
 			'MD' => 'Moldávia',
 			'ME' => 'Montenegru',
 			'MF' => 'San Martinhu (Fransa)',
 			'MG' => 'Madagaskar',
 			'MH' => 'Ilhas Marxal',
 			'MK' => 'Masidónia di Norti',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar (Birmánia)',
 			'MN' => 'Mongólia',
 			'MO' => 'Makau, Rejion Administrativu Spesial di Xina',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Ilhas Marianas di Norti',
 			'MQ' => 'Martinika',
 			'MR' => 'Mauritánia',
 			'MS' => 'Monserat',
 			'MT' => 'Malta',
 			'MU' => 'Maurísia',
 			'MV' => 'Maldivas',
 			'MW' => 'Malaui',
 			'MX' => 'Méxiku',
 			'MY' => 'Malázia',
 			'MZ' => 'Musambiki',
 			'NA' => 'Namíbia',
 			'NC' => 'Nova Kalidónia',
 			'NE' => 'Nijer',
 			'NF' => 'Ilhas Norfolk',
 			'NG' => 'Nijéria',
 			'NI' => 'Nikarágua',
 			'NL' => 'Olanda',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zilándia',
 			'OM' => 'Oman',
 			'PA' => 'Panamá',
 			'PE' => 'Peru',
 			'PF' => 'Polinézia Franseza',
 			'PG' => 'Papua-Nova Gine',
 			'PH' => 'Filipinas',
 			'PK' => 'Pakistan',
 			'PL' => 'Pulónia',
 			'PM' => 'San Piere i Mikelon',
 			'PN' => 'Ilhas Pitkairn',
 			'PR' => 'Portu Riku',
 			'PS' => 'Tiritóriu palistinianu',
 			'PS@alt=short' => 'Palistina',
 			'PT' => 'Purtugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Katar',
 			'QO' => 'Ilhas di Oseania',
 			'RE' => 'Runion',
 			'RO' => 'Ruménia',
 			'RS' => 'Sérvia',
 			'RU' => 'Rúsia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arábia Saudita',
 			'SB' => 'Ilhas Salumãu',
 			'SC' => 'Seixelis',
 			'SD' => 'Sudon',
 			'SE' => 'Suésia',
 			'SG' => 'Singapura',
 			'SH' => 'Santa Ilena',
 			'SI' => 'Slovénia',
 			'SJ' => 'Svalbard i Jan Maien',
 			'SK' => 'Slovákia',
 			'SL' => 'Sera Lioa',
 			'SM' => 'San Marinu',
 			'SN' => 'Senegal',
 			'SO' => 'Sumália',
 			'SR' => 'Surinami',
 			'SS' => 'Sudon di Sul',
 			'ST' => 'San Tume i Prínsipi',
 			'SV' => 'El Salvador',
 			'SX' => 'San Martinhu (Olanda)',
 			'SY' => 'Síria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Suazilándia',
 			'TA' => 'Tristan da Kunha',
 			'TC' => 'Ilhas Turkas i Kaikus',
 			'TD' => 'Txadi',
 			'TF' => 'Terras Franses di Sul',
 			'TG' => 'Togu',
 			'TH' => 'Tailándia',
 			'TJ' => 'Tadjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Lesti',
 			'TL@alt=variant' => 'Timor-Leste',
 			'TM' => 'Turkumenistan',
 			'TN' => 'Tunízia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkia',
 			'TT' => 'Trinidad i Tobagu',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiuan',
 			'TZ' => 'Tanzánia',
 			'UA' => 'Ukránia',
 			'UG' => 'Uganda',
 			'UM' => 'Ilhas Minoris Distantis de Stadus Unidus',
 			'UN' => 'Nasons Unidas',
 			'US' => 'Stadus Unidos di Merka',
 			'US@alt=short' => 'S.U.',
 			'UY' => 'Uruguai',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikanu',
 			'VC' => 'San Bisenti i Granadinas',
 			'VE' => 'Vinizuela',
 			'VG' => 'Ilhas Virjens Británikas',
 			'VI' => 'Ilhas Virjens Merkanas',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Ualis i Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-sotakis',
 			'XB' => 'Pseudo-bidiresional',
 			'XK' => 'Kozovu',
 			'YE' => 'Iémen',
 			'YT' => 'Maiote',
 			'ZA' => 'Áfrika di Sul',
 			'ZM' => 'Zámbia',
 			'ZW' => 'Zimbábui',
 			'ZZ' => 'Rejion Diskonxedu',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalendáriu',
 			'cf' => 'Formatu di mueda',
 			'collation' => 'Ordenason',
 			'currency' => 'Mueda',
 			'hc' => 'Siklu oráriu (12 o 24)',
 			'lb' => 'Stilu di kebra di linha',
 			'ms' => 'Sistema di midida',
 			'numbers' => 'Nunbru',

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
 				'buddhist' => q{Kalendáriu budista},
 				'chinese' => q{Kalendáriu xines},
 				'coptic' => q{Kalendáriu kopta},
 				'dangi' => q{Kalendáriu dangi},
 				'ethiopic' => q{Kalendáriu etiópiku},
 				'ethiopic-amete-alem' => q{Kalendáriu etíopi ameti alem},
 				'gregorian' => q{Kalendáriu Gregorianu},
 				'hebrew' => q{Kalendáriu ebraiku},
 				'indian' => q{Kalendáriu nasional indianu},
 				'islamic' => q{Kalendáriu islámiku},
 				'islamic-civil' => q{Kalendáriu islámiku (sivil)},
 				'islamic-tbla' => q{Kalendáriu islámiku (astronómiku)},
 				'islamic-umalqura' => q{Kalendáriu islámiku (Umm al-Qura)},
 				'iso8601' => q{Kalendáriu ISO-8601},
 				'japanese' => q{Kalendáriu japones},
 				'persian' => q{Kalendáriu persa},
 				'roc' => q{Kalendáriu di Repúblika di Xina},
 			},
 			'cf' => {
 				'account' => q{Formatu di mueda kontabilístiku},
 				'standard' => q{Formatu di mueda padron},
 			},
 			'collation' => {
 				'ducet' => q{Órdi padron di Unicode},
 				'search' => q{Piskiza di uzu jeral},
 				'standard' => q{Órdi padron},
 			},
 			'hc' => {
 				'h11' => q{Sistema di 12 ora (0–11)},
 				'h12' => q{Sistema di 12 ora (1–12)},
 				'h23' => q{Sistema di 24 ora (0–23)},
 				'h24' => q{Sistema di 24 ora (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Stilu fleksível di kebra di linha},
 				'normal' => q{Stilu padron di kebra di linha},
 				'strict' => q{Stilu ríjidu di kebra di linha},
 			},
 			'ms' => {
 				'metric' => q{Sistema métriku},
 				'uksystem' => q{Sistema di midida britániku},
 				'ussystem' => q{Sistema di midida merkanu},
 			},
 			'numbers' => {
 				'latn' => q{Nunbru osidental},
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
			'metric' => q{Métriku},
 			'UK' => q{Britániku},
 			'US' => q{Merkanu},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lingua: {0}',
 			'script' => 'Skrita: {0}',
 			'region' => 'Rejion: {0}',

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
			auxiliary => qr{[ªáàăâåäãā æ cç éèĕêëẽē íìĭîïĩī {n̈} ºóòŏôöõøō œ q {rr} ᵘúùŭûüũū w ÿ]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'X', 'Z'],
			main => qr{[a b d {dj} e f g h i j k l {lh} m nñ {nh} o p r s t {tx} u v x y z]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” « » ( ) \[ \] § @ * / \& # † ‡]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'X', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direson kardial),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direson kardial),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(desi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(desi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
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
						'1' => q(senti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(senti{0}),
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
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
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
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
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
						'1' => q(ekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ekto{0}),
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
						'1' => q(jiga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(jiga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(forsa G),
						'other' => q({0} forsa G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(forsa G),
						'other' => q({0} forsa G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metru pur sigundu kuadradu),
						'other' => q({0} metru pur sigundu kuadradu),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metru pur sigundu kuadradu),
						'other' => q({0} metru pur sigundu kuadradu),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(minutu di arku),
						'other' => q({0} minutu di arku),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minutu di arku),
						'other' => q({0} minutu di arku),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sigundu di arku),
						'other' => q({0} sigundu di arku),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sigundu di arku),
						'other' => q({0} sigundu di arku),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'other' => q({0} grau),
					},
					# Core Unit Identifier
					'degree' => {
						'other' => q({0} grau),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianu),
						'other' => q({0} radianu),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianu),
						'other' => q({0} radianu),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(volta),
						'other' => q({0} volta),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(volta),
						'other' => q({0} volta),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ákri),
						'other' => q({0} ákri),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ákri),
						'other' => q({0} ákri),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ektar),
						'other' => q({0} ektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ektar),
						'other' => q({0} ektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sentímetru kuadradu),
						'other' => q({0} sentímetru kuadradu),
						'per' => q({0} pur sentímetru kuadradu),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sentímetru kuadradu),
						'other' => q({0} sentímetru kuadradu),
						'per' => q({0} pur sentímetru kuadradu),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pe kuadradu),
						'other' => q({0} pe kuadradu),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pe kuadradu),
						'other' => q({0} pe kuadradu),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pulegada kuadradu),
						'other' => q({0} pulegada kuadradu),
						'per' => q({0} pur pulegada kuadradu),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pulegada kuadradu),
						'other' => q({0} pulegada kuadradu),
						'per' => q({0} pur pulegada kuadradu),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilómetru kuadradu),
						'other' => q({0} kilómetru kuadradu),
						'per' => q({0} pur kilómetru kuadradu),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilómetru kuadradu),
						'other' => q({0} kilómetru kuadradu),
						'per' => q({0} pur kilómetru kuadradu),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metru kuadradu),
						'other' => q({0} metru kuadradu),
						'per' => q({0} pur metru kuadradu),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metru kuadradu),
						'other' => q({0} metru kuadradu),
						'per' => q({0} pur metru kuadradu),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milha kuadradu),
						'other' => q({0} milha kuadradu),
						'per' => q({0} pur milha kuadradu),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milha kuadradu),
						'other' => q({0} milha kuadradu),
						'per' => q({0} pur milha kuadradu),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jarda kuadradu),
						'other' => q({0} jarda kuadradu),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jarda kuadradu),
						'other' => q({0} jarda kuadradu),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kilati),
						'other' => q({0} kilati),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kilati),
						'other' => q({0} kilati),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligrama pur desilitru),
						'other' => q({0} miligrama pur desilitru),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligrama pur desilitru),
						'other' => q({0} miligrama pur desilitru),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol pur litru),
						'other' => q({0} milimol pur litru),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol pur litru),
						'other' => q({0} milimol pur litru),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(pursentu),
						'other' => q({0} pursentu),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(pursentu),
						'other' => q({0} pursentu),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(pur mil),
						'other' => q({0} pur mil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(pur mil),
						'other' => q({0} pur mil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parti pur milhãu),
						'other' => q({0} parti pur milhãu),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parti pur milhãu),
						'other' => q({0} parti pur milhãu),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pontu bazi),
						'other' => q({0} pontu bazi),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pontu bazi),
						'other' => q({0} pontu bazi),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litru pur 100 kilómetru),
						'other' => q({0} litru pur 100 kilómetru),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litru pur 100 kilómetru),
						'other' => q({0} litru pur 100 kilómetru),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litru pur kilómetru),
						'other' => q({0} litru pur kilómetru),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litru pur kilómetru),
						'other' => q({0} litru pur kilómetru),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milha pur galãu),
						'other' => q({0} milha pur galãu),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milha pur galãu),
						'other' => q({0} milha pur galãu),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milha pur galãu britániku),
						'other' => q({0} milha pur galãu britániku),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milha pur galãu britániku),
						'other' => q({0} milha pur galãu britániku),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} esti),
						'north' => q({0} norti),
						'south' => q({0} sul),
						'west' => q({0} oesti),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} esti),
						'north' => q({0} norti),
						'south' => q({0} sul),
						'west' => q({0} oesti),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(jigabit),
						'other' => q({0} jigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(jigabit),
						'other' => q({0} jigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(jigabyte),
						'other' => q({0} jigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(jigabyte),
						'other' => q({0} jigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobyte),
						'other' => q({0} kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobyte),
						'other' => q({0} kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabyte),
						'other' => q({0} petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sékulu),
						'other' => q({0} sékulu),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sékulu),
						'other' => q({0} sékulu),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} pur dia),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} pur dia),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dékada),
						'other' => q({0} dékada),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dékada),
						'other' => q({0} dékada),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} ora),
						'per' => q({0} pur ora),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} ora),
						'per' => q({0} pur ora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosigundu),
						'other' => q({0} mikrosigundu),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosigundu),
						'other' => q({0} mikrosigundu),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisigundu),
						'other' => q({0} milisigundu),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisigundu),
						'other' => q({0} milisigundu),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutu),
						'other' => q({0} minutu),
						'per' => q({0} pur minutu),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutu),
						'other' => q({0} minutu),
						'per' => q({0} pur minutu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} pur mes),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} pur mes),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosigundu),
						'other' => q({0} nanosigundu),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosigundu),
						'other' => q({0} nanosigundu),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sigundu),
						'other' => q({0} sigundu),
						'per' => q({0} pur sigundu),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sigundu),
						'other' => q({0} sigundu),
						'per' => q({0} pur sigundu),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(simana),
						'other' => q({0} simana),
						'per' => q({0} pur simana),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(simana),
						'other' => q({0} simana),
						'per' => q({0} pur simana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} pur anu),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} pur anu),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamper),
						'other' => q({0} miliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamper),
						'other' => q({0} miliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unidadi térmiku britániku),
						'other' => q({0} unidadi térmiku britániku),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unidadi térmiku britániku),
						'other' => q({0} unidadi térmiku britániku),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloria),
						'other' => q({0} kaloria),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloria),
						'other' => q({0} kaloria),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eleton-volt),
						'other' => q({0} eletron-volt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eleton-volt),
						'other' => q({0} eletron-volt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kaloria),
						'other' => q({0} Kaloria),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kaloria),
						'other' => q({0} Kaloria),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloria),
						'other' => q({0} kilokaloria),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloria),
						'other' => q({0} kilokaloria),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule),
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule),
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt-ora),
						'other' => q({0} kilowatt-ora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-ora),
						'other' => q({0} kilowatt-ora),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(unidadi térmiku merkanu),
						'other' => q({0} unidadi térmiku merkanu),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(unidadi térmiku merkanu),
						'other' => q({0} unidadi térmiku merkanu),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(libra di forsa),
						'other' => q({0} libra di forsa),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libra di forsa),
						'other' => q({0} libra di forsa),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(jigaertz),
						'other' => q({0} jigaertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(jigaertz),
						'other' => q({0} jigaertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(ertz),
						'other' => q({0} ertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(ertz),
						'other' => q({0} ertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kiloertz),
						'other' => q({0} kiloertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kiloertz),
						'other' => q({0} kiloertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megaertz),
						'other' => q({0} megaertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megaertz),
						'other' => q({0} megaertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pontu),
						'other' => q({0} pontu),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pontu),
						'other' => q({0} pontu),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pontu pur sentímeru),
						'other' => q({0} pontu pur sentímetru),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pontu pur sentímeru),
						'other' => q({0} pontu pur sentímetru),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pontu pur pulegada),
						'other' => q({0} pontu pur pulegada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pontu pur pulegada),
						'other' => q({0} pontu pur pulegada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(emi tipográfiku),
						'other' => q({0} emi tipográfiku),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(emi tipográfiku),
						'other' => q({0} emi tipográfiku),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapiksel),
						'other' => q({0} megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksel),
						'other' => q({0} megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(piksel pur sentímetru),
						'other' => q({0} piksel pur sentímetru),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksel pur sentímetru),
						'other' => q({0} piksel pur sentímetru),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksel pur pulegada),
						'other' => q({0} piksel pur pulegada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksel pur pulegada),
						'other' => q({0} piksel pur pulegada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unidadi astronómiku),
						'other' => q({0} unidadi astronómiku),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unidadi astronómiku),
						'other' => q({0} unidadi astronómiku),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentímetru),
						'other' => q({0} sentímetru),
						'per' => q({0} pur sentímetru),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentímetru),
						'other' => q({0} sentímetru),
						'per' => q({0} pur sentímetru),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desímetru),
						'other' => q({0} desímetru),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desímetru),
						'other' => q({0} desímetru),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(raiu di Tera),
						'other' => q({0} raiu di Tera),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(raiu di Tera),
						'other' => q({0} raiu di Tera),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0} pur pe),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0} pur pe),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(pulegada),
						'other' => q({0} pulegada),
						'per' => q({0} pur pulegada),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pulegada),
						'other' => q({0} pulegada),
						'per' => q({0} pur pulegada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilómetru),
						'other' => q({0} kilómetru),
						'per' => q({0} pur kilómetru),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilómetru),
						'other' => q({0} kilómetru),
						'per' => q({0} pur kilómetru),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metru),
						'other' => q({0} metru),
						'per' => q({0} pur metru),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metru),
						'other' => q({0} metru),
						'per' => q({0} pur metru),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrómetru),
						'other' => q({0} mikrómetru),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrómetru),
						'other' => q({0} mikrómetru),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milha),
						'other' => q({0} milha),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milha),
						'other' => q({0} milha),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milha skandinavu),
						'other' => q({0} milha skandinavu),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milha skandinavu),
						'other' => q({0} milha skandinavu),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milímetru),
						'other' => q({0} milímetru),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milímetru),
						'other' => q({0} milímetru),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanómetru),
						'other' => q({0} nanómetru),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanómetru),
						'other' => q({0} nanómetru),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milha náutiku),
						'other' => q({0} milha náutiku),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milha náutiku),
						'other' => q({0} milha náutiku),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikómetru),
						'other' => q({0} pikómetru),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikómetru),
						'other' => q({0} pikómetru),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(raiu solar),
						'other' => q({0} raiu solar),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(raiu solar),
						'other' => q({0} raiu solar),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jarda),
						'other' => q({0} jarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jarda),
						'other' => q({0} jarda),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminozidadi solar),
						'other' => q({0} luminozidadi solar),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminozidadi solar),
						'other' => q({0} luminozidadi solar),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kilati),
						'other' => q({0} kilati),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kilati),
						'other' => q({0} kilati),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masa di Tera),
						'other' => q({0} masa di Tera),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masa di Tera),
						'other' => q({0} masa di Tera),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grama),
						'other' => q({0} grama),
						'per' => q({0} pur grama),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grama),
						'other' => q({0} grama),
						'per' => q({0} pur grama),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilograma),
						'other' => q({0} kilograma),
						'per' => q({0} pur kilograma),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilograma),
						'other' => q({0} kilograma),
						'per' => q({0} pur kilograma),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrograma),
						'other' => q({0} mikrograma),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrograma),
						'other' => q({0} mikrograma),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligrama),
						'other' => q({0} miligrama),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligrama),
						'other' => q({0} miligrama),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ónsa),
						'other' => q({0} ónsa),
						'per' => q({0} pur ónsa),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ónsa),
						'other' => q({0} ónsa),
						'per' => q({0} pur ónsa),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ónsa troy),
						'other' => q({0} ónsa troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ónsa troy),
						'other' => q({0} ónsa troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libra),
						'other' => q({0} libra),
						'per' => q({0} pur libra),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libra),
						'other' => q({0} libra),
						'per' => q({0} pur libra),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masa di Sol),
						'other' => q({0} masa di Sol),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masa di Sol),
						'other' => q({0} masa di Sol),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonelada),
						'other' => q({0} tonelada),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonelada),
						'other' => q({0} tonelada),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonelada métriku),
						'other' => q({0} tonelada métriku),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonelada métriku),
						'other' => q({0} tonelada métriku),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} pur {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} pur {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(jigawatt),
						'other' => q({0} jigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(jigawatt),
						'other' => q({0} jigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(kabalu-vapor),
						'other' => q({0} kabalu-vapor),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(kabalu-vapor),
						'other' => q({0} kabalu-vapor),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} kuadradu),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} kuadradu),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q({0} kúbiku),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q({0} kúbiku),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfera),
						'other' => q({0} atmosfera),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfera),
						'other' => q({0} atmosfera),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ektopaskal),
						'other' => q({0} ektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ektopaskal),
						'other' => q({0} ektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pulegada di merkúriu),
						'other' => q({0} pulegada di merkúriu),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pulegada di merkúriu),
						'other' => q({0} pulegada di merkúriu),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskal),
						'other' => q({0} megapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskal),
						'other' => q({0} megapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milímetru di merkúriu),
						'other' => q({0} milímetru di merkúriu),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milímetru di merkúriu),
						'other' => q({0} milímetru di merkúriu),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskal),
						'other' => q({0} paskal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskal),
						'other' => q({0} paskal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libra pur pulegada kuadradu),
						'other' => q({0} libra pur pulegada kuadradu),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libra pur pulegada kuadradu),
						'other' => q({0} libra pur pulegada kuadradu),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilómetru pur ora),
						'other' => q({0} kilómetru pur ora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilómetru pur ora),
						'other' => q({0} kilómetru pur ora),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nó),
						'other' => q({0} nó),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nó),
						'other' => q({0} nó),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metru pur sigundu),
						'other' => q({0} metru pur sigundu),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metru pur sigundu),
						'other' => q({0} metru pur sigundu),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milha pur ora),
						'other' => q({0} milha pur ora),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milha pur ora),
						'other' => q({0} milha pur ora),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(grau Celsius),
						'other' => q({0} grau Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(grau Celsius),
						'other' => q({0} grau Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(grau Fahrenheit),
						'other' => q({0} grau Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(grau Fahrenheit),
						'other' => q({0} grau Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
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
						'name' => q(newton-metru),
						'other' => q({0} newton-metru),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-metru),
						'other' => q({0} newton-metru),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pe-libra),
						'other' => q({0} pe-libra),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pe-libra),
						'other' => q({0} pe-libra),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ákri-pé),
						'other' => q({0} ákri-pé),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ákri-pé),
						'other' => q({0} ákri-pé),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(baril),
						'other' => q({0} baril),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(baril),
						'other' => q({0} baril),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentilitru),
						'other' => q({0} sentilitru),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentilitru),
						'other' => q({0} sentilitru),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sentímetru kúbiku),
						'other' => q({0} sentímetru kúbiku),
						'per' => q({0} pur sentímetru kúbiku),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sentímetru kúbiku),
						'other' => q({0} sentímetru kúbiku),
						'per' => q({0} pur sentímetru kúbiku),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pé kúbiku),
						'other' => q({0} pé kúbiku),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pé kúbiku),
						'other' => q({0} pé kúbiku),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(pulegada kúbiku),
						'other' => q({0} pulegada kúbiku),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(pulegada kúbiku),
						'other' => q({0} pulegada kúbiku),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilómetru kúbiku),
						'other' => q({0} kilómetru kúbiku),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilómetru kúbiku),
						'other' => q({0} kilómetru kúbiku),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metru kúbiku),
						'other' => q({0} metru kúbiku),
						'per' => q({0} pur metru kúbiku),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metru kúbiku),
						'other' => q({0} metru kúbiku),
						'per' => q({0} pur metru kúbiku),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milha kúbiku),
						'other' => q({0} milha kúbiku),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milha kúbiku),
						'other' => q({0} milha kúbiku),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jarda kúbiku),
						'other' => q({0} jarda kúbiku),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jarda kúbiku),
						'other' => q({0} jarda kúbiku),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(xávina),
						'other' => q({0} xávina),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(xávina),
						'other' => q({0} xávina),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(xávina métriku),
						'other' => q({0} xávina métriku),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(xávina métriku),
						'other' => q({0} xávina métriku),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desilitru),
						'other' => q({0} desilitru),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desilitru),
						'other' => q({0} desilitru),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(kudjer di subrimeza),
						'other' => q({0} kudjer di subrimeza),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(kudjer di subrimeza),
						'other' => q({0} kudjer di subrimeza),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(kudjer di subrimeza britániku),
						'other' => q({0} kudjer di subrimeza britániku),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(kudjer di subrimeza britániku),
						'other' => q({0} kudjer di subrimeza britániku),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drakma fluídu),
						'other' => q({0} drakma fluídu),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drakma fluídu),
						'other' => q({0} drakma fluídu),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ónsa fluídu),
						'other' => q({0} ónsa fluídu),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ónsa fluídu),
						'other' => q({0} ónsa fluídu),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(ónsa fluídu britániku),
						'other' => q({0} ónsa fluídu britániku),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(ónsa fluídu britániku),
						'other' => q({0} ónsa fluídu britániku),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galãu),
						'other' => q({0} galãu),
						'per' => q({0} pur galãu),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galãu),
						'other' => q({0} galãu),
						'per' => q({0} pur galãu),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galãu britániku),
						'other' => q({0} galãu britániku),
						'per' => q({0} pur galãu britániku),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galãu britániku),
						'other' => q({0} galãu britániku),
						'per' => q({0} pur galãu britániku),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ektolitru),
						'other' => q({0} ektolitru),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ektolitru),
						'other' => q({0} ektolitru),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(kopu di xot),
						'other' => q({0} kopu di xot),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(kopu di xot),
						'other' => q({0} kopu di xot),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litru),
						'other' => q({0} litru),
						'per' => q({0} pur litru),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litru),
						'other' => q({0} litru),
						'per' => q({0} pur litru),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitru),
						'other' => q({0} megalitru),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitru),
						'other' => q({0} megalitru),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitru),
						'other' => q({0} mililitru),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitru),
						'other' => q({0} mililitru),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pitada),
						'other' => q({0} pitada),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pitada),
						'other' => q({0} pitada),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint),
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint),
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pint métriku),
						'other' => q({0} pint métriku),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pint métriku),
						'other' => q({0} pint métriku),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kuart),
						'other' => q({0} kuart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kuart),
						'other' => q({0} kuart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kuart britániku),
						'other' => q({0} kuart britániku),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kuart britániku),
						'other' => q({0} kuart britániku),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(kudjer di sopa),
						'other' => q({0} kudjer di sopa),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(kudjer di sopa),
						'other' => q({0} kudjer di sopa),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kudjer di xá),
						'other' => q({0} kudjer di xá),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kudjer di xá),
						'other' => q({0} kudjer di xá),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'other' => q({0}kg),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direson),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direson),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arkmin),
						'other' => q({0} arkmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arkmin),
						'other' => q({0} arkmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arksig),
						'other' => q({0} arksig),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arksig),
						'other' => q({0} arksig),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grau),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grau),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(vol),
						'other' => q({0} vol),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(vol),
						'other' => q({0} vol),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
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
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol/litru),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol/litru),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parti/milhãu),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parti/milhãu),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litru/100km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litru/100km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milha/gal brit.),
						'other' => q({0} mpg brit.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milha/gal brit.),
						'other' => q({0} mpg brit.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sék.),
						'other' => q({0} sék.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sék.),
						'other' => q({0} sék.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dia),
						'other' => q({0} dia),
						'per' => q({0}/dia),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dia),
						'other' => q({0} dia),
						'per' => q({0}/dia),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dék.),
						'other' => q({0} dék.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dék.),
						'other' => q({0} dék.),
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
					'duration-minute' => {
						'name' => q(min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mes),
						'other' => q({0} mes),
						'per' => q({0}/mes),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mes),
						'other' => q({0} mes),
						'per' => q({0}/mes),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sig.),
						'other' => q({0} sig.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sig.),
						'other' => q({0} sig.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sim.),
						'other' => q({0} sim.),
						'per' => q({0}/sim.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sim.),
						'other' => q({0} sim.),
						'per' => q({0}/sim.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(anu),
						'other' => q({0} anu),
						'per' => q({0}/anu),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(anu),
						'other' => q({0} anu),
						'per' => q({0}/anu),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Cal),
						'other' => q({0} Cal),
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
					'energy-therm-us' => {
						'name' => q(thm SU),
						'other' => q({0} thm SU),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm SU),
						'other' => q({0} thm SU),
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
					'length-foot' => {
						'name' => q(pe),
						'other' => q({0} pe),
						'per' => q({0}/pe),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pe),
						'other' => q({0} pe),
						'per' => q({0}/pe),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(anu-lus),
						'other' => q({0} anu-lus),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(anu-lus),
						'other' => q({0} anu-lus),
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
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grãu),
						'other' => q({0} grãu),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grãu),
						'other' => q({0} grãu),
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
					'mass-ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
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
					'temperature-celsius' => {
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(xáv),
						'other' => q({0} xáv),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(xáv),
						'other' => q({0} xáv),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(xávm),
						'other' => q({0} xávm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(xávm),
						'other' => q({0} xávm),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dstspn brit.),
						'other' => q({0} dstspn brit.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dstspn brit.),
						'other' => q({0} dstspn brit.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drakma fl.),
						'other' => q({0} drakma fl.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drakma fl.),
						'other' => q({0} drakma fl.),
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
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz brit.),
						'other' => q({0} fl oz brit.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz brit.),
						'other' => q({0} fl oz brit.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal brit.),
						'other' => q({0} gal brit.),
						'per' => q({0}/gal brit.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal brit.),
						'other' => q({0} gal brit.),
						'per' => q({0}/gal brit.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(kopu x.),
						'other' => q({0} kopu x.),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(kopu x.),
						'other' => q({0} kopu x.),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pit.),
						'other' => q({0} pit.),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pit.),
						'other' => q({0} pit.),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ptm),
						'other' => q({0} ptm),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ptm),
						'other' => q({0} ptm),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt brit.),
						'other' => q({0} qt brit.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt brit.),
						'other' => q({0} qt brit.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ks),
						'other' => q({0} ks),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ks),
						'other' => q({0} ks),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kx),
						'other' => q({0} kx),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kx),
						'other' => q({0} kx),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Sin|S|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Nãu|N)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} i {1}),
				2 => q({0} i {1}),
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
					'other' => '0 mil',
				},
				'10000' => {
					'other' => '00 mil',
				},
				'100000' => {
					'other' => '000 mil',
				},
				'1000000' => {
					'other' => '0 milhãu',
				},
				'10000000' => {
					'other' => '00 milhãu',
				},
				'100000000' => {
					'other' => '000 milhãu',
				},
				'1000000000' => {
					'other' => '0 mil milhãu',
				},
				'10000000000' => {
					'other' => '00 mil milhãu',
				},
				'100000000000' => {
					'other' => '000 mil milhãu',
				},
				'1000000000000' => {
					'other' => '0 bilhãu',
				},
				'10000000000000' => {
					'other' => '00 bilhãu',
				},
				'100000000000000' => {
					'other' => '000 bilhãu',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0 mil',
				},
				'10000' => {
					'other' => '00 mil',
				},
				'100000' => {
					'other' => '000 mil',
				},
				'1000000' => {
					'other' => '0 M',
				},
				'10000000' => {
					'other' => '00 M',
				},
				'100000000' => {
					'other' => '000 M',
				},
				'1000000000' => {
					'other' => '0 MM',
				},
				'10000000000' => {
					'other' => '00 MM',
				},
				'100000000000' => {
					'other' => '000 MM',
				},
				'1000000000000' => {
					'other' => '0 Bi',
				},
				'10000000000000' => {
					'other' => '00 Bi',
				},
				'100000000000000' => {
					'other' => '000 Bi',
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
						'negative' => '(#,##0.00 ¤)',
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
				'currency' => q(Diren di Emiradus Arabi Unidu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kuanza),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Dola australianu),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar di Barain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franku borundes),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Rial brazileru),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula di Botsuana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dola kanadianu),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franku kongoles),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franku suisu),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Iuan xines),
			},
		},
		'CVE' => {
			symbol => '​',
			display_name => {
				'currency' => q(Skudu Kabuverdianu),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franku di Djibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Kuroa dinamarkeza),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar arjelinu),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Libra ejípsiu),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nafka di Eritreia),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bir etiópiku),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Libra britániku),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi di Gana \(1979–2007\)),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Sili),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dola di Ong Kong),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupia indoneziu),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupia indianu),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Ieni japones),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Xelin kenianu),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franku di Komoris),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won sul-koreanu),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dola liberianu),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti di Lezotu),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar líbiu),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Diren marokinu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariari di Madagaskar),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ougia \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ougia),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia di Maurisias),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kuaxa di Malaui),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Pezu mexikanu),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikal),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dola namibianu),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Kuroa norueges),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty polaku),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rublu rusu),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franku ruandes),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Rial saudita),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia di Seixelis),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Libra sudanes),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Libra sudanes antigu \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Kuroa sueku),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Libra di Santa Ilena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone di Sera Leoa),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone di Sera Leoa \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Xelin somalianu),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra di San Tume i Prínsipi \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra di San Tume i Prínsipi),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilanjeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht tailandes),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar tunizianu),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira turku),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dola Novu di Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Xelin di Tanzánia),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Xelin ugandensi),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dola merkanu),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franku CFA \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franku CFA \(BCEAO\)),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mueda diskonxedu),
				'other' => q(\(mueda diskonxedu\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand sulafrikanu),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kuaxa zambianu \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kuaxa zambianu),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dola di Zimbabue \(1980–2008\)),
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
							'Jan',
							'Feb',
							'Mar',
							'Abr',
							'Mai',
							'Jun',
							'Jul',
							'Ago',
							'Set',
							'Otu',
							'Nuv',
							'Diz'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janeru',
							'Febreru',
							'Marsu',
							'Abril',
							'Maiu',
							'Junhu',
							'Julhu',
							'Agostu',
							'Setenbru',
							'Otubru',
							'Nuvenbru',
							'Dizenbru'
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
						mon => 'sig',
						tue => 'ter',
						wed => 'kua',
						thu => 'kin',
						fri => 'ses',
						sat => 'sab',
						sun => 'dum'
					},
					short => {
						mon => 'si',
						tue => 'te',
						wed => 'ku',
						thu => 'ki',
						fri => 'se',
						sat => 'sa',
						sun => 'du'
					},
					wide => {
						mon => 'sigunda-fera',
						tue => 'tersa-fera',
						wed => 'kuarta-fera',
						thu => 'kinta-fera',
						fri => 'sesta-fera',
						sat => 'sábadu',
						sun => 'dumingu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'S',
						tue => 'T',
						wed => 'K',
						thu => 'K',
						fri => 'S',
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
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					wide => {0 => '1º trimestri',
						1 => '2º trimestri',
						2 => '3º trimestri',
						3 => '4º trimestri'
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
					'am' => q{am},
					'pm' => q{pm},
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
				'0' => 'AK',
				'1' => 'DK'
			},
			wide => {
				'0' => 'antis di Kristu',
				'1' => 'dispos di Kristu'
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
			'full' => q{EEEE, d 'di' MMMM 'di' y G},
			'long' => q{d 'di' MMMM 'di' y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'di' MMMM 'di' y},
			'long' => q{d 'di' MMMM 'di' y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
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
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d 'di' MMMM},
			MMMMd => q{d 'di' MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			mmss => q{mm:ss},
			y => q{y},
			yM => q{LL/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{MM/y},
			yMMM => q{LLL y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL 'di' y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'di' y},
			yyyy => q{y G},
			yyyyM => q{LL/y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ 'di' y G},
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
			GyMd => q{dd/MM/y GGGGG},
			Hmsv => q{HH:mm:ss (v)},
			Hmv => q{HH:mm (v)},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d 'di' MMMM},
			MMMMW => q{W'º' 'simana' 'di' MMMM},
			MMMMd => q{d 'di' MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a (v)},
			hmv => q{h:mm a (v)},
			mmss => q{mm:ss},
			yM => q{LL/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{LL/y},
			yMMM => q{LLL y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL 'di' y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'di' y},
			yw => q{w'º' 'simana' 'di' Y},
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
				G => q{LL/y GGGGG – LL/y GGGGG},
				M => q{LL/y – LL/y GGGGG},
				y => q{LL/y – LL/y GGGGG},
			},
			GyMEd => {
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
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
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			M => {
				M => q{L – L},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
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
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{LL/y – LL/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{LLL – LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'di' y G},
				y => q{LLLL 'di' y – LLLL 'di' y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'gregorian' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{LL/y GGGGG – LL/y GGGGG},
				M => q{LL/y – LL/y GGGGG},
				y => q{LL/y – LL/y GGGGG},
			},
			GyMEd => {
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
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
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
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
				M => q{L – L},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMMd => {
				M => q{dd/MM – dd/MM},
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
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{LL/y – LL/y},
				y => q{LL/y – LL/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{LLL – LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'di' y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
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
		regionFormat => q(Ora di {0}),
		regionFormat => q(Ora di Veron di {0}),
		regionFormat => q(Ora Padron di {0}),
		'Africa_Central' => {
			long => {
				'standard' => q#Ora di Áfrika Sentral#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora di Áfrika Oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ora di Sul di Áfrika#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ora di Veron di Áfrika Osidental#,
				'generic' => q#Ora di Áfrika Osidental#,
				'standard' => q#Ora Padron di Áfrika Osidental#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Ora di Veron di Alaska#,
				'generic' => q#Ora di Alaska#,
				'standard' => q#Ora Padron di Alaska#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adaki#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankoraji#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angila#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Baía di Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbadus#,
		},
		'America/Belize' => {
			exemplarCity => q#Belizi#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon#,
		},
		'America/Boise' => {
			exemplarCity => q#Boiz#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaiman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Xikagu#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Xiuáua#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kréston#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasau#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupi#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatimala#,
		},
		'America/Havana' => {
			exemplarCity => q#Avana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianápolis#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Managua' => {
			exemplarCity => q#Manágua#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinika#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Sidadi di Méxiku#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/New_York' => {
			exemplarCity => q#Nova Iorki#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota di Norti#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota di Norti#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota di Norti#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamá#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Portu di Spanha#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portu Riku#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santu Dumingu#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#San Bartolomeu#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Kristovan#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lúsia#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Bisenti#,
		},
		'America/Toronto' => {
			exemplarCity => q#Torontu#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankuver#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Uínipeg#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ora di Veron Sentral#,
				'generic' => q#Ora Sentral#,
				'standard' => q#Ora Padron Sentral#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ora di Veron Oriental#,
				'generic' => q#Ora Oriental#,
				'standard' => q#Ora Padron Oriental#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ora di Veron di Montanha#,
				'generic' => q#Ora di Montanha#,
				'standard' => q#Ora Padron di Montanha#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ora di Veron di Pasífiku#,
				'generic' => q#Ora di Pasífiku#,
				'standard' => q#Ora Padron di Pasífiku#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ora di Veron di Atlántiku#,
				'generic' => q#Ora di Atlántiku#,
				'standard' => q#Ora Padron di Atlántiku#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ora di Veron di Austrália Sentral#,
				'generic' => q#Ora di Austrália Sentral#,
				'standard' => q#Ora Padron di Austrália Sentral#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ora di Veron di Austrália Sentru-Osidental#,
				'generic' => q#Ora di Austrália Sentru-Osidental#,
				'standard' => q#Ora Padron di Austrália Sentru-Osidental#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ora di Veron di Austrália Oriental#,
				'generic' => q#Ora di Austrália Oriental#,
				'standard' => q#Ora Padron di Austrália Oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ora di Veron di Austrália Osidental#,
				'generic' => q#Ora di Austrália Osidental#,
				'standard' => q#Ora Padron di Austrália Osidental#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Ora di Veron de Kabu Verdi#,
				'generic' => q#Ora di Kabu Verdi#,
				'standard' => q#Ora Padron di Kabu Verdi#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Ora di Veron di Kuba#,
				'generic' => q#Ora di Kuba#,
				'standard' => q#Ora Padron di Kuba#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Ora Universal Kordenadu#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Sidadi diskonxedu#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Ora Padron di Irlanda#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Ora di Veron Britániku#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora di Veron di Europa Sentral#,
				'generic' => q#Ora di Europa Sentral#,
				'standard' => q#Ora Padron di Europa Sentral#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora di Veron di Europa Oriental#,
				'generic' => q#Ora di Europa Oriental#,
				'standard' => q#Ora Padron di Europa Oriental#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora di Veron di Europa Osidental#,
				'generic' => q#Ora di Europa Osidental#,
				'standard' => q#Ora Padron di Europa Osidental#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ora Médiu di Greenwich#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ora di Veron di Gronelándia Oriental#,
				'generic' => q#Ora di Gronelándia Oriental#,
				'standard' => q#Ora Padron di Gronelándia Oriental#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Ora di Veron di Gronelándia Osidental#,
				'generic' => q#Ora di Gronelándia Osidental#,
				'standard' => q#Ora Padron di Gronelándia Osidental#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Ora di Veron di Avaí i Aleutas#,
				'generic' => q#Ora di Avaí i Aleutas#,
				'standard' => q#Ora Padron di Avaí i Aleutas#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Ora di Veron di Pasífiku Mexikanu#,
				'generic' => q#Ora di Pasífiku Mexikanu#,
				'standard' => q#Ora Padron di Pasífiku Mexikanu#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ora di Veron di Tera Nova#,
				'generic' => q#Ora di Tera Nova#,
				'standard' => q#Ora Padron di Tera Nova#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ora di Veron di San Pedru i Mikelon#,
				'generic' => q#Ora di San Pedru i Mikelon#,
				'standard' => q#Ora Padron di San Pedru i Mikelon#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Ora di Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
