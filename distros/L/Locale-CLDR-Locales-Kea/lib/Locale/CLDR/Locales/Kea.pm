=encoding utf8

=head1

Locale::CLDR::Locales::Kea - Package for language Kabuverdianu

=cut

package Locale::CLDR::Locales::Kea;
# This file auto generated from Data\common\main\kea.xml
#	on Sun  7 Oct 10:40:51 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
 				'ay' => 'aimara',
 				'az' => 'azerbaijanu',
 				'az@alt=short' => 'azeri',
 				'ba' => 'baxkir',
 				'ban' => 'balinese',
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
 				'ce' => 'txetxenu',
 				'cgg' => 'xiga',
 				'chr' => 'xeroki',
 				'ckb' => 'kurdu sentral',
 				'co' => 'kórsiku',
 				'cs' => 'txeku',
 				'cv' => 'txuvaxi',
 				'cy' => 'gales',
 				'da' => 'dinamarkes',
 				'dav' => 'taita',
 				'de' => 'alimãu',
 				'de_AT' => 'alimãu austriaku',
 				'de_CH' => 'altu alimãu suisu',
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
 				'en_GB' => 'ingles britaniku',
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
 				'fa' => 'persa',
 				'fi' => 'finlandes',
 				'fil' => 'filipinu',
 				'fj' => 'fijianu',
 				'fo' => 'faroes',
 				'fr' => 'franses',
 				'fr_CA' => 'franses kanadianu',
 				'fr_CH' => 'franses suisu',
 				'fy' => 'fríziu osidental',
 				'ga' => 'irlandes',
 				'gag' => 'gagauz',
 				'gl' => 'galegu',
 				'gn' => 'guarani',
 				'gsw' => 'alimãu suísu',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manks',
 				'ha' => 'auza',
 				'haw' => 'avaianu',
 				'he' => 'ebraiku',
 				'hi' => 'indi',
 				'hr' => 'kroata',
 				'hsb' => 'sórbiu altu',
 				'ht' => 'aitianu',
 				'hu' => 'úngaru',
 				'hy' => 'arméniu',
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
 				'kea' => 'kabuverdianu',
 				'khq' => 'koira txiini',
 				'ki' => 'kikuiu',
 				'kk' => 'kazak',
 				'kl' => 'groenlandes',
 				'kln' => 'kalenjin',
 				'km' => 'kmer',
 				'kn' => 'kanares',
 				'ko' => 'korianu',
 				'koi' => 'komi-permiak',
 				'kok' => 'konkani',
 				'ks' => 'kaxmira',
 				'ksf' => 'bafia',
 				'ku' => 'kurdu',
 				'kw' => 'kórniku',
 				'ky' => 'kirgiz',
 				'la' => 'latin',
 				'lb' => 'luxemburges',
 				'lg' => 'luganda',
 				'lo' => 'lausianu',
 				'lt' => 'lituanes',
 				'lv' => 'letãu',
 				'mg' => 'malgaxi',
 				'mi' => 'maori',
 				'mk' => 'masedóniu',
 				'ml' => 'malaialam',
 				'mr' => 'marati',
 				'ms' => 'maláiu',
 				'mt' => 'maltes',
 				'my' => 'birmanes',
 				'nb' => 'norueges bokmål',
 				'ne' => 'nepales',
 				'nl' => 'olandes',
 				'nl_BE' => 'flamengu',
 				'nmg' => 'kuazio',
 				'nn' => 'norueges nynorsk',
 				'om' => 'oromo',
 				'or' => 'odía',
 				'pa' => 'pandjabi',
 				'pl' => 'pulaku',
 				'ps' => 'paxto',
 				'pt' => 'purtuges',
 				'pt_BR' => 'purtuges brazileru',
 				'pt_PT' => 'purtuges europeu',
 				'qu' => 'kexua',
 				'quc' => 'kitxe',
 				'rm' => 'romanxi',
 				'ro' => 'rumenu',
 				'ro_MD' => 'rumenu moldáviku',
 				'ru' => 'rusu',
 				'rw' => 'kiniaruanda',
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
 				'tzm' => 'tamazait di Atlas Sentral',
 				'ug' => 'uigur',
 				'uk' => 'ukranianu',
 				'und' => 'língua diskonxedu',
 				'ur' => 'urdu',
 				'uz' => 'uzbeki',
 				'vi' => 'vietnamita',
 				'wo' => 'uolof',
 				'xh' => 'koza',
 				'yo' => 'ioruba',
 				'yue' => 'kantonese',
 				'zh' => 'xines',
 				'zh_Hans' => 'xines simplifikadu',
 				'zh_Hant' => 'xines tradisional',
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
 			'057' => 'Rejiãu di Mikronézia',
 			'061' => 'Polinézia',
 			'142' => 'Ázia',
 			'143' => 'Ázia Sentral',
 			'145' => 'Ázia Osidental',
 			'150' => 'Europa',
 			'151' => 'Europa Oriental',
 			'154' => 'Europa di Norti',
 			'155' => 'Europa Osidental',
 			'419' => 'Merka Latinu',
 			'AC' => 'Ilha di Asensãu',
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
 			'AZ' => 'Azerbaijãu',
 			'BA' => 'Bósnia i Erzegovina',
 			'BB' => 'Barbadus',
 			'BD' => 'Bangladexi',
 			'BE' => 'Béljika',
 			'BF' => 'Burkina Fasu',
 			'BG' => 'Bulgária',
 			'BH' => 'Barain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sãu Bartolomeu',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolívia',
 			'BQ' => 'Karaibas Olandezas',
 			'BR' => 'Brazil',
 			'BS' => 'Baamas',
 			'BT' => 'Butãu',
 			'BV' => 'Ilha Buve',
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
 			'CM' => 'Kamarõis',
 			'CN' => 'Xina',
 			'CO' => 'Kolômbia',
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
 			'EU' => 'Uniãu Europeia',
 			'FI' => 'Finlándia',
 			'FJ' => 'Fidji',
 			'FK' => 'Ilhas Malvinas',
 			'FK@alt=variant' => 'Ilhas Falkland (Ilhas Malvinas)',
 			'FM' => 'Mikronézia',
 			'FO' => 'Ilhas Faroe',
 			'FR' => 'Fransa',
 			'GA' => 'Gabãu',
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
 			'HK' => 'Rejiãu Administrativu Spesial di Hong Kong',
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
 			'JP' => 'Japãu',
 			'KE' => 'Kénia',
 			'KG' => 'Kirgistãu',
 			'KH' => 'Kambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Kamoris',
 			'KN' => 'Sãu Kristovãu i Nevis',
 			'KP' => 'Koreia di Norti',
 			'KR' => 'Koreia di Sul',
 			'KW' => 'Kueiti',
 			'KY' => 'Ilhas Kaimãu',
 			'KZ' => 'Kazakistãu',
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
 			'MF' => 'Sãu Martinhu di Fransa',
 			'MG' => 'Madagaskar',
 			'MH' => 'Ilhas Marxal',
 			'MK' => 'Masidónia',
 			'MK@alt=variant' => 'Masidónia (FYROM)',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar (Birmánia)',
 			'MN' => 'Mongólia',
 			'MO' => 'Rejiãu Administrativu Spesial di Makau',
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
 			'PK' => 'Pakistãu',
 			'PL' => 'Pulónia',
 			'PM' => 'San Piere i Mikelon',
 			'PN' => 'Pirkairn',
 			'PR' => 'Portu Riku',
 			'PS' => 'Palistina',
 			'PT' => 'Purtugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Katar',
 			'QO' => 'Ilhas di Oseania',
 			'RE' => 'Runiãu',
 			'RO' => 'Ruménia',
 			'RS' => 'Sérvia',
 			'RU' => 'Rúsia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arábia Saudita',
 			'SB' => 'Ilhas Salumãu',
 			'SC' => 'Seixelis',
 			'SD' => 'Sudãu',
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
 			'SS' => 'Sudãu di Sul',
 			'ST' => 'Sãu Tume i Prínsipi',
 			'SV' => 'El Salvador',
 			'SX' => 'Sãu Martinhu di Olanda',
 			'SY' => 'Síria',
 			'SZ' => 'Suazilándia',
 			'TA' => 'Tristan da Kunha',
 			'TC' => 'Ilhas Turkas i Kaikus',
 			'TD' => 'Txadi',
 			'TF' => 'Terras Franses di Sul',
 			'TG' => 'Togu',
 			'TH' => 'Tailándia',
 			'TJ' => 'Tadjikistãu',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Lesti',
 			'TM' => 'Turkumenistãu',
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
 			'US' => 'Stadus Unidos di Merka',
 			'US@alt=short' => 'S.U.',
 			'UY' => 'Uruguai',
 			'UZ' => 'Uzbekistãu',
 			'VA' => 'Vatikanu',
 			'VC' => 'Sãu Bisenti i Granadinas',
 			'VE' => 'Vinizuela',
 			'VG' => 'Ilhas Virjens Británikas',
 			'VI' => 'Ilhas Virjens Merkanas',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Ualis i Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kozovu',
 			'YE' => 'Iémen',
 			'YT' => 'Maiote',
 			'ZA' => 'Áfrika di Sul',
 			'ZM' => 'Zámbia',
 			'ZW' => 'Zimbábui',
 			'ZZ' => 'Rejiãu Diskonxedu',

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
 				'gregorian' => q{Kalendáriu Gregorianu},
 			},
 			'numbers' => {
 				'latn' => q{Númerus Arábikus},
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
 			'UK' => q{Ingles},
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
 			'region' => 'Rejiãu: {0}',

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
			auxiliary => qr{[á à ă â å ä ã ā æ c ç é è ĕ ê ë ẽ ē í ì ĭ î ï ĩ ī {n̈} ó ò ŏ ô ö õ ø ō œ q {rr} ú ù ŭ û ü ũ ū w ÿ]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'X', 'Z'],
			main => qr{[a b d {dj} e f g h i j k l {lh} m n ñ {nh} o p r s t {tx} u v x y z]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'X', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(ákri),
						'other' => q({0} ákri),
					},
					'acre-foot' => {
						'name' => q(ákri-pé),
						'other' => q({0} ákri-pé),
					},
					'arc-minute' => {
						'name' => q(minutu di arku),
						'other' => q({0} minutu di arku),
					},
					'arc-second' => {
						'name' => q(sigundu di arku),
						'other' => q({0} sigundu di arku),
					},
					'astronomical-unit' => {
						'name' => q(unidadi astronómiku),
						'other' => q({0} unidadi astronómiku),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
					},
					'centiliter' => {
						'name' => q(sentilitru),
						'other' => q({0} sentilitru),
					},
					'centimeter' => {
						'name' => q(sentímetru),
						'other' => q({0} sentímetru),
						'per' => q({0} pur sentímetru),
					},
					'century' => {
						'name' => q(sékulu),
						'other' => q({0} sékulu),
					},
					'cubic-centimeter' => {
						'name' => q(sentímetru kúbiku),
						'other' => q({0} sentímetru kúbiku),
					},
					'cubic-foot' => {
						'name' => q(pé kúbiku),
						'other' => q({0} pé kúbiku),
					},
					'cubic-inch' => {
						'name' => q(pulegada kúbiku),
						'other' => q({0} pulegada kúbiku),
					},
					'cubic-kilometer' => {
						'name' => q(kilómetru kúbiku),
						'other' => q({0} kilómetru kúbiku),
					},
					'cubic-meter' => {
						'name' => q(métru kúbiku),
						'other' => q({0} métru kúbiku),
					},
					'cubic-mile' => {
						'name' => q(milha kúbiku),
						'other' => q({0} milha kúbiku),
					},
					'cubic-yard' => {
						'name' => q(jarda kúbiku),
						'other' => q({0} jarda kúbiku),
					},
					'cup' => {
						'name' => q(xávina),
						'other' => q({0} xávina),
					},
					'day' => {
						'name' => q(dia),
						'other' => q({0} dia),
						'per' => q({0} pur dia),
					},
					'deciliter' => {
						'name' => q(desilitru),
						'other' => q({0} desilitru),
					},
					'decimeter' => {
						'name' => q(desímetru),
						'other' => q({0} desímetru),
					},
					'degree' => {
						'name' => q(grau),
						'other' => q({0} grau),
					},
					'fluid-ounce' => {
						'name' => q(ónsa fluídu),
						'other' => q({0} ónsa fluídu),
					},
					'foot' => {
						'name' => q(pe),
						'other' => q({0} pe),
						'per' => q({0} pur pe),
					},
					'g-force' => {
						'name' => q(forsa G),
						'other' => q({0} forsa G),
					},
					'gallon' => {
						'name' => q(galãu),
						'other' => q({0} galãu),
					},
					'gigabit' => {
						'name' => q(jigabit),
						'other' => q({0} jigabit),
					},
					'gigabyte' => {
						'name' => q(jigabyte),
						'other' => q({0} jigabyte),
					},
					'hectare' => {
						'name' => q(ektar),
						'other' => q({0} ektar),
					},
					'hectoliter' => {
						'name' => q(ektolitru),
						'other' => q({0} ektolitru),
					},
					'hour' => {
						'name' => q(ora),
						'other' => q({0} ora),
						'per' => q({0} pur ora),
					},
					'inch' => {
						'name' => q(pulegada),
						'other' => q({0} pulegada),
						'per' => q({0} pur pulegada),
					},
					'karat' => {
						'name' => q(kilati),
						'other' => q({0} kilati),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobyte),
						'other' => q({0} kilobyte),
					},
					'kilometer' => {
						'name' => q(kilómetru),
						'other' => q({0} kilómetru),
						'per' => q({0} pur kilómetru),
					},
					'kilometer-per-hour' => {
						'name' => q(kilómetru pur ora),
						'other' => q({0} kilómetru pur ora),
					},
					'light-year' => {
						'name' => q(anu-lus),
						'other' => q({0} anu-lus),
					},
					'liter' => {
						'name' => q(litru),
						'other' => q({0} litru),
					},
					'liter-per-100kilometers' => {
						'name' => q(litru pur 100 kilómetru),
						'other' => q({0} litru pur 100 kilómetru),
					},
					'liter-per-kilometer' => {
						'name' => q(litru pur kilómetru),
						'other' => q({0} litru pur kilómetru),
					},
					'lux' => {
						'name' => q(lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabyte),
						'other' => q({0} megabyte),
					},
					'megaliter' => {
						'name' => q(megalitru),
						'other' => q({0} megalitru),
					},
					'meter' => {
						'name' => q(metru),
						'other' => q({0} metru),
						'per' => q({0} pur metru),
					},
					'meter-per-second' => {
						'name' => q(métru pur sigundu),
						'other' => q({0} métru pur sigundu),
					},
					'meter-per-second-squared' => {
						'name' => q(métru pur sigundu kuadradu),
						'other' => q({0} métru pur sigundu kuadradu),
					},
					'micrometer' => {
						'name' => q(mikrómetru),
						'other' => q({0} mikrómetru),
					},
					'microsecond' => {
						'name' => q(mikrosigundu),
						'other' => q({0} mikrosigundu),
					},
					'mile' => {
						'name' => q(milha),
						'other' => q({0} milha),
					},
					'mile-per-gallon' => {
						'name' => q(milha pur galãu),
						'other' => q({0} milha pur galãu),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(milha pur galãu imperial),
						'other' => q({0} milha pur galãu imperial),
					},
					'mile-per-hour' => {
						'name' => q(milha pur ora),
						'other' => q({0} milha pur ora),
					},
					'mile-scandinavian' => {
						'name' => q(milha skandinavu),
						'other' => q({0} milha skandinavu),
					},
					'milligram-per-deciliter' => {
						'name' => q(miligrama pur desilitru),
						'other' => q({0} miligrama pur desilitru),
					},
					'milliliter' => {
						'name' => q(mililitru),
						'other' => q({0} mililitru),
					},
					'millimeter' => {
						'name' => q(milímetru),
						'other' => q({0} milímetru),
					},
					'millimole-per-liter' => {
						'name' => q(milimol pur litru),
						'other' => q({0} milimol pur litru),
					},
					'millisecond' => {
						'name' => q(milisigundu),
						'other' => q({0} milisigundu),
					},
					'minute' => {
						'name' => q(minutu),
						'other' => q({0} minutu),
						'per' => q({0} pur minutu),
					},
					'month' => {
						'name' => q(mes),
						'other' => q({0} mes),
						'per' => q({0} pur mes),
					},
					'nanometer' => {
						'name' => q(nanómetru),
						'other' => q({0} nanómetru),
					},
					'nanosecond' => {
						'name' => q(nanosigundu),
						'other' => q({0} nanosigundu),
					},
					'nautical-mile' => {
						'name' => q(milha náutiku),
						'other' => q({0} milha náutiku),
					},
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					'part-per-million' => {
						'name' => q(parti pur milhãu),
						'other' => q({0} parti pur milhãu),
					},
					'picometer' => {
						'name' => q(pikómetru),
						'other' => q({0} pikómetru),
					},
					'pint' => {
						'name' => q(pint),
						'other' => q({0} pint),
					},
					'quart' => {
						'name' => q(kuart),
						'other' => q({0} kuart),
					},
					'radian' => {
						'name' => q(radianu),
						'other' => q({0} radianu),
					},
					'revolution' => {
						'name' => q(volta),
						'other' => q({0} volta),
					},
					'second' => {
						'name' => q(sigundu),
						'other' => q({0} sigundu),
						'per' => q({0} pur sigundu),
					},
					'square-centimeter' => {
						'name' => q(sentímetru kuadradu),
						'other' => q({0} sentímetru kuadradu),
						'per' => q({0} pur sentímetru kuadradu),
					},
					'square-foot' => {
						'name' => q(pe kuadradu),
						'other' => q({0} pe kuadradu),
					},
					'square-inch' => {
						'name' => q(pulegada kuadradu),
						'other' => q({0} pulegada kuadradu),
						'per' => q({0} pur pulegada kuadradu),
					},
					'square-kilometer' => {
						'name' => q(kilómetru kuadradu),
						'other' => q({0} kilómetru kuadradu),
						'per' => q({0} pur kilómetru kuadradu),
					},
					'square-meter' => {
						'name' => q(metru kuadradu),
						'other' => q({0} metru kuadradu),
						'per' => q({0} pur metru kuadradu),
					},
					'square-mile' => {
						'name' => q(milha kuadradu),
						'other' => q({0} milha kuadradu),
						'per' => q({0} pur milha kuadradu),
					},
					'square-yard' => {
						'name' => q(jarda kuadradu),
						'other' => q({0} jarda kuadradu),
					},
					'tablespoon' => {
						'name' => q(kudjer di sopa),
						'other' => q({0} kudjer di sopa),
					},
					'teaspoon' => {
						'name' => q(kudjer di xá),
						'other' => q({0} kudjer di xá),
					},
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabyte),
						'other' => q({0} terabyte),
					},
					'watt' => {
						'name' => q(watt),
					},
					'week' => {
						'name' => q(simana),
						'other' => q({0} simana),
						'per' => q({0} pur simana),
					},
					'yard' => {
						'name' => q(jarda),
						'other' => q({0} jarda),
					},
					'year' => {
						'name' => q(anu),
						'other' => q({0} anu),
						'per' => q({0} pur anu),
					},
				},
				'narrow' => {
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
					},
					'day' => {
						'name' => q(dia),
						'other' => q({0} dia),
					},
					'gram' => {
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(ora),
						'other' => q({0} h),
					},
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'other' => q({0} km/h),
					},
					'liter' => {
						'name' => q(l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100km),
						'other' => q({0} l/100km),
					},
					'meter' => {
						'name' => q(m),
						'other' => q({0} m),
					},
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min.),
						'other' => q({0} min.),
					},
					'month' => {
						'name' => q(mes),
						'other' => q({0} mes),
					},
					'second' => {
						'name' => q(sig.),
						'other' => q({0} s),
					},
					'week' => {
						'name' => q(sim.),
						'other' => q({0} sim.),
					},
					'year' => {
						'name' => q(anu),
						'other' => q({0} anu),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(arkmin),
						'other' => q({0} arkmin),
					},
					'arc-second' => {
						'name' => q(arksig),
						'other' => q({0} arksig),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					'bit' => {
						'name' => q(b),
						'other' => q({0} b),
					},
					'byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					'calorie' => {
						'name' => q(cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'other' => q({0} CD),
					},
					'centiliter' => {
						'name' => q(cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(sék.),
						'other' => q({0} sék.),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'other' => q({0} m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(xáv.),
						'other' => q({0} xáv.),
					},
					'day' => {
						'name' => q(dia),
						'other' => q({0} dia),
						'per' => q({0}/dia),
					},
					'deciliter' => {
						'name' => q(dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(grau),
						'other' => q({0}°),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(pe),
						'other' => q({0} pe),
						'per' => q({0}/pe),
					},
					'g-force' => {
						'name' => q(G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
					},
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'other' => q({0} g),
					},
					'hectare' => {
						'name' => q(ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'other' => q({0} Hz),
					},
					'hour' => {
						'name' => q(ora),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'other' => q({0} inHg),
					},
					'karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(Kb),
						'other' => q({0} Kb),
					},
					'kilobyte' => {
						'name' => q(KB),
						'other' => q({0} KB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'other' => q({0} kcal),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'other' => q({0} kWh),
					},
					'light-year' => {
						'name' => q(anu-lus),
						'other' => q({0} anu-lus),
					},
					'liter' => {
						'name' => q(l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(litru/100km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lux),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(milha/gal imp.),
						'other' => q({0} mpg imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(milimol/litru),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					'month' => {
						'name' => q(mes),
						'other' => q({0} mes),
						'per' => q({0}/mes),
					},
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'other' => q({0} oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(parti/milhãu),
						'other' => q({0} ppm),
					},
					'picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'other' => q({0} lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(vol),
						'other' => q({0} vol),
					},
					'second' => {
						'name' => q(sig.),
						'other' => q({0} sig.),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(k.sp.),
						'other' => q({0} k.sp.),
					},
					'teaspoon' => {
						'name' => q(k.xá),
						'other' => q({0} k.xá),
					},
					'terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(volt),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watt),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(sim.),
						'other' => q({0} sim.),
						'per' => q({0}/sim.),
					},
					'yard' => {
						'name' => q(yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(anu),
						'other' => q({0} anu),
						'per' => q({0}/anu),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
			symbol => 'AED',
			display_name => {
				'currency' => q(Diren di Emiradus Arabi Unidu),
				'other' => q(Diren di Emiradus Arabi Unidu),
			},
		},
		'AFN' => {
			symbol => 'AFN',
		},
		'ALL' => {
			symbol => 'ALL',
		},
		'AMD' => {
			symbol => 'AMD',
		},
		'ANG' => {
			symbol => 'ANG',
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kuanza),
				'other' => q(Kuanza),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Dola australianu),
				'other' => q(Dola australianu),
			},
		},
		'AWG' => {
			symbol => 'AWG',
		},
		'AZN' => {
			symbol => 'AZN',
		},
		'BAM' => {
			symbol => 'BAM',
		},
		'BDT' => {
			symbol => '৳',
		},
		'BGN' => {
			symbol => 'BGN',
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar di Barain),
				'other' => q(Dinar di Barain),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Franku borundes),
				'other' => q(Franku borundes),
			},
		},
		'BND' => {
			symbol => '$',
		},
		'BOB' => {
			symbol => 'BOB',
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Rial brazileru),
				'other' => q(Rial brazileru),
			},
		},
		'BTN' => {
			symbol => 'BTN',
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula di Botsuana),
				'other' => q(Pula di Botsuana),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dola kanadianu),
				'other' => q(Dola kanadianu),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Franku kongoles),
				'other' => q(Franku kongoles),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Franku suisu),
				'other' => q(Franku suisu),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Iuan xines),
				'other' => q(Iuan xines),
			},
		},
		'CVE' => {
			symbol => '​',
			display_name => {
				'currency' => q(Skudu Kabuverdianu),
				'other' => q(Skudu Kabuverdianu),
			},
		},
		'CZK' => {
			symbol => 'CZK',
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Franku di Djibuti),
				'other' => q(Franku di Djibuti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Kuroa dinamarkeza),
				'other' => q(Kuroa dinamarkeza),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinar arjelinu),
				'other' => q(Dinar arjelinu),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Libra ejipsiu),
				'other' => q(Libra ejipsiu),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nafka di Eritreia),
				'other' => q(Nafka di Eritreia),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Bir etiopi),
				'other' => q(Bir etiopi),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'other' => q(Euro),
			},
		},
		'FJD' => {
			symbol => '$',
		},
		'FKP' => {
			symbol => 'FKP',
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Libra britaniku),
				'other' => q(Libra britaniku),
			},
		},
		'GEL' => {
			symbol => 'GEL',
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi di Gana),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi),
				'other' => q(Dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
		},
		'GNS' => {
			display_name => {
				'currency' => q(Sili),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dola di Ong Kong),
				'other' => q(Dola di Ong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
		},
		'HRK' => {
			symbol => 'HRK',
		},
		'HTG' => {
			symbol => 'HTG',
		},
		'HUF' => {
			symbol => 'HUF',
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Rupia indoneziu),
				'other' => q(Rupia indoneziu),
			},
		},
		'ILS' => {
			symbol => '₪',
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupia indianu),
				'other' => q(Rupia indianu),
			},
		},
		'IQD' => {
			symbol => 'IQD',
		},
		'IRR' => {
			symbol => 'IRR',
		},
		'ISK' => {
			symbol => 'ISK',
		},
		'JOD' => {
			symbol => 'JOD',
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Ieni japones),
				'other' => q(Ieni japones),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Xelin kenianu),
				'other' => q(Xelin kenianu),
			},
		},
		'KGS' => {
			symbol => 'KGS',
		},
		'KHR' => {
			symbol => '៛',
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Franku di Komoris),
				'other' => q(Franku di Komoris),
			},
		},
		'KPW' => {
			symbol => 'KPW',
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Won sul-koreanu),
				'other' => q(Won sul-koreanu),
			},
		},
		'KWD' => {
			symbol => 'KWD',
		},
		'KZT' => {
			symbol => '₸',
		},
		'LAK' => {
			symbol => '₭',
		},
		'LBP' => {
			symbol => 'LBP',
		},
		'LKR' => {
			symbol => 'LKR',
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dola liberianu),
				'other' => q(Dola liberianu),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti di Lezotu),
			},
		},
		'LTL' => {
			symbol => 'LTL',
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinar libiu),
				'other' => q(Dinar libiu),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Diren marokinu),
				'other' => q(Diren marokinu),
			},
		},
		'MDL' => {
			symbol => 'MDL',
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariari di Madagaskar),
				'other' => q(Ariari di Madagaskar),
			},
		},
		'MKD' => {
			symbol => 'MKD',
		},
		'MMK' => {
			symbol => 'MMK',
		},
		'MNT' => {
			symbol => '₮',
		},
		'MOP' => {
			symbol => 'MOP',
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Ougia \(1973–2017\)),
				'other' => q(Ougia \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ougia),
				'other' => q(Ougia),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia di Maurisias),
				'other' => q(Rupia di Maurisias),
			},
		},
		'MVR' => {
			symbol => 'MVR',
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kuaxa di Malaui),
				'other' => q(Kuaxa di Malaui),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Pezu mexikanu),
				'other' => q(Pezu mexikanu),
			},
		},
		'MYR' => {
			symbol => 'MYR',
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikal),
			},
		},
		'MZN' => {
			symbol => 'MZN',
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dola namibianu),
				'other' => q(Dola namibianu),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira),
				'other' => q(Naira),
			},
		},
		'NIO' => {
			symbol => 'NIO',
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Kuroa norueges),
				'other' => q(Kuroa norueges),
			},
		},
		'NPR' => {
			symbol => 'NPR',
		},
		'NZD' => {
			symbol => 'NZ$',
		},
		'OMR' => {
			symbol => 'OMR',
		},
		'PAB' => {
			symbol => 'PAB',
		},
		'PEN' => {
			symbol => 'PEN',
		},
		'PGK' => {
			symbol => 'PGK',
		},
		'PHP' => {
			symbol => '₱',
		},
		'PKR' => {
			symbol => 'PKR',
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloty polaku),
				'other' => q(Zloty polaku),
			},
		},
		'QAR' => {
			symbol => 'QAR',
		},
		'RSD' => {
			symbol => 'RSD',
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rublu rusu),
				'other' => q(Rublu rusu),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Franku ruandes),
				'other' => q(Franku ruandes),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Rial saudita),
				'other' => q(Rial saudita),
			},
		},
		'SBD' => {
			symbol => '$',
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupia di Seixelis),
				'other' => q(Rupia di Seixelis),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Libra sudanes),
				'other' => q(Libra sudanes),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Libra sudanes antigu),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Kuroa sueku),
				'other' => q(Kuroa sueku),
			},
		},
		'SGD' => {
			symbol => '$',
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Libra di Santa Ilena),
				'other' => q(Libra di Santa Ilena),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leone di Sera Leoa),
				'other' => q(Leone di Sera Leoa),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Xelin somalianu),
				'other' => q(Xelin somalianu),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Dobra di Sãu Tume i Prínsipi \(1977–2017\)),
				'other' => q(Dobra di Sãu Tume i Prinsipi \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra di Sãu Tume i Prínsipi),
				'other' => q(Dobra di Sãu Tume i Prinsipi),
			},
		},
		'SYP' => {
			symbol => 'SYP',
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilanjeni),
				'other' => q(Lilanjeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht tailandes),
				'other' => q(Baht tailandes),
			},
		},
		'TJS' => {
			symbol => 'TJS',
		},
		'TMT' => {
			symbol => 'TMT',
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinar tunizianu),
				'other' => q(Dinar tunizianu),
			},
		},
		'TOP' => {
			symbol => 'TOP',
		},
		'TRY' => {
			symbol => '₺',
			display_name => {
				'currency' => q(Lira turku),
				'other' => q(Lira turku),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dola Novu di Taiwan),
				'other' => q(Dola Novu di Taiwan),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Xelin di Tanzania),
				'other' => q(Xelin di Tanzania),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Xelin ugandensi),
				'other' => q(Xelin ugandensi),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Dola merkanu),
				'other' => q(Dola merkanu),
			},
		},
		'UZS' => {
			symbol => 'UZS',
		},
		'VEF' => {
			symbol => 'VEF',
		},
		'VND' => {
			symbol => '₫',
		},
		'VUV' => {
			symbol => 'VUV',
		},
		'WST' => {
			symbol => 'WST',
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Franku CFA \(BEAC\)),
				'other' => q(Franku CFA \(BEAC\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Franku CFA \(BCEAO\)),
				'other' => q(Franku CFA \(BCEAO\)),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mueda diskonxedu),
				'other' => q(\(mueda diskonxedu\)),
			},
		},
		'YER' => {
			symbol => 'YER',
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand sulafrikanu),
				'other' => q(Rand sulafrikanu),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kuaxa zambianu \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kuaxa zambianu),
				'other' => q(Kuaxa zambianu),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dola di Zimbabue),
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
					narrow => {
						mon => 'S',
						tue => 'T',
						wed => 'K',
						thu => 'K',
						fri => 'S',
						sat => 'S',
						sun => 'D'
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
						sat => 'sabadu',
						sun => 'dumingu'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'sig',
						tue => 'ter',
						wed => 'kua',
						thu => 'kin',
						fri => 'ses',
						sat => 'sab',
						sun => 'dum'
					},
					narrow => {
						mon => 'S',
						tue => 'T',
						wed => 'K',
						thu => 'K',
						fri => 'S',
						sat => 'S',
						sun => 'D'
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
					wide => {0 => '1º trimestri',
						1 => '2º trimestri',
						2 => '3º trimestri',
						3 => '4º trimestri'
					},
				},
				'stand-alone' => {
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
				'wide' => {
					'pm' => q{pm},
					'am' => q{am},
				},
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
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
				'0' => 'Antis di Kristu',
				'1' => 'Dispos di Kristu'
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
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'di' MMMM 'di' y},
			'long' => q{d 'di' MMMM 'di' y},
			'medium' => q{d MMM y},
			'short' => q{d/M/y},
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
			E => q{ccc},
			Ed => q{E, d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d 'di' MMMM},
			MMMMd => q{d 'di' MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{dd/MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM 'di' y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'di' y},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ 'di' y G},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss (v)},
			Hmv => q{HH:mm (v)},
			M => q{L},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d 'di' MMMM},
			MMMMd => q{d 'di' MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{dd/MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a (v)},
			hmv => q{h:mm a (v)},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM 'di' y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'di' y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
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
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM 'di' y G},
				y => q{MMMM 'di' y – MMMM 'di' y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMMd => {
				M => q{dd/MM – dd/MM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
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
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM 'di' y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
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
		gmtZeroFormat => q(GMT),
		regionFormat => q(Ora di {0}),
		regionFormat => q(Ora di {0} (verãu)),
		regionFormat => q(Ora di {0} (normal)),
		fallbackFormat => q({1} ({0})),
		'Africa_Central' => {
			long => {
				'standard' => q#Ora di Afrika Sentral#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora di Afrika Oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ora di Sul di Afrika#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ora di Verão di Afrika Osidental#,
				'generic' => q#Ora di Afrika Osidental#,
				'standard' => q#Ora Padrãu di Afrika Osidental#,
			},
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ora Sentral di Verãu#,
				'generic' => q#Ora Sentral#,
				'standard' => q#Ora Sentral Padrãu#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ora Oriental di Verãu#,
				'generic' => q#Ora Oriental#,
				'standard' => q#Ora Oriental Padrãu#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ora di Verãu di Montanha#,
				'generic' => q#Ora di Montanha#,
				'standard' => q#Ora di Montanha Padrãu#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ora di Pasifiku di Verãu#,
				'generic' => q#Ora di Pasifiku#,
				'standard' => q#Ora di Pasifiku Padrãu#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ora di Verãu di Atlantiku#,
				'generic' => q#Ora di Atlantiku#,
				'standard' => q#Ora Padrãu di Atlantiku#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ora di Verãu di Australia Sentral#,
				'generic' => q#Ora di Australia Sentral#,
				'standard' => q#Ora Padrãu di Australia Sentral#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ora di Verãu di Australia Sentru-Osidental#,
				'generic' => q#Ora di Autralia Sentru-Osidental#,
				'standard' => q#Ora Padrãu di Australia Sentru-Osidental#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ora di Verãu di Australia Oriental#,
				'generic' => q#Ora di Australia Oriental#,
				'standard' => q#Ora Padrãu di Australia Oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ora di Verãu di Australia Osidental#,
				'generic' => q#Ora di Australia Osidental#,
				'standard' => q#Ora Padrãu di Australia Osidental#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Sidadi Diskonxedu#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora di Verãu di Europa Sentral#,
				'generic' => q#Ora di Europa Sentral#,
				'standard' => q#Ora Padrãu di Europa Sentral#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora di Verãu di Europa Oriental#,
				'generic' => q#Ora di Europa Oriental#,
				'standard' => q#Ora Padrãu di Europa Oriental#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora di Verãu di Europa Osidental#,
				'generic' => q#Ora di Europa Osidental#,
				'standard' => q#Ora Padrãu di Europa Osidental#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
