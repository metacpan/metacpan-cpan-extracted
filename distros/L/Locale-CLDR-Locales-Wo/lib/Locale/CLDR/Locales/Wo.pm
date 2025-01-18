=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Wo - Package for language Wolof

=cut

package Locale::CLDR::Locales::Wo;
# This file auto generated from Data\common\main\wo.xml
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
				'af' => 'Afrikaans',
 				'am' => 'Amharik',
 				'ar' => 'Arabic',
 				'ar_001' => 'Araab',
 				'as' => 'Asame',
 				'az' => 'Aserbayjane',
 				'ba' => 'Baskir',
 				'ban' => 'Bali',
 				'be' => 'Belaris',
 				'bem' => 'Bemba',
 				'bg' => 'Bilgaar',
 				'bn' => 'Baŋla',
 				'bo' => 'Tibetan',
 				'br' => 'Breton',
 				'bs' => 'Bosñak',
 				'ca' => 'Katalan',
 				'ceb' => 'Sibiyanoo',
 				'chm' => 'Mari',
 				'chr' => 'Ceroki',
 				'ckb' => 'Kurdi gu Diggu',
 				'co' => 'Kors',
 				'cs' => 'Cek',
 				'cy' => 'Wels',
 				'da' => 'Danuwa',
 				'de' => 'Almaa',
 				'de_AT' => 'Almaa bu Ótiriis',
 				'de_CH' => 'Almaa bu Kawe bu Swis',
 				'dsb' => 'Sorab-Suuf',
 				'dv' => 'Diweyi',
 				'dz' => 'Dsongkaa',
 				'el' => 'Gereg',
 				'en' => 'Àngale',
 				'en_AU' => 'Àngale bu Óstraali',
 				'en_CA' => 'Àngale bu Kanadaa',
 				'en_GB' => 'Àngale bu Grànd Brëtaañ',
 				'en_GB@alt=short' => 'Àngale (RI)',
 				'en_US' => 'Àngale bu Amerik',
 				'en_US@alt=short' => 'Àngale (ES)',
 				'eo' => 'Esperantoo',
 				'es' => 'Español',
 				'es_419' => 'Español bu Amerik Latin',
 				'es_ES' => 'Español bu Tugël',
 				'es_MX' => 'Español bu Meksik',
 				'et' => 'Estoñiye',
 				'eu' => 'Bask',
 				'fa' => 'Pers',
 				'ff' => 'Pël',
 				'fi' => 'Feylànde',
 				'fil' => 'Filipiye',
 				'fo' => 'Feroos',
 				'fr' => 'Farañse',
 				'fr_CA' => 'Frañse bu Kanadaa',
 				'fr_CH' => 'Frañse bu Swis',
 				'ga' => 'Irlànde',
 				'gd' => 'Galuwaa bu Ekos',
 				'gl' => 'Galisiye',
 				'gn' => 'Garani',
 				'gu' => 'Gujarati',
 				'ha' => 'Hawsa',
 				'haw' => 'Hawaye',
 				'he' => 'Ebrë',
 				'hi' => 'Endo',
 				'hi_Latn' => 'Hindī',
 				'hi_Latn@alt=variant' => 'Hindī bu Àngale',
 				'hil' => 'Hiligaynon',
 				'hr' => 'Krowat',
 				'hsb' => 'Sorab-Kaw',
 				'ht' => 'Kereyolu Ayti',
 				'hu' => 'Ongruwaa',
 				'hy' => 'Armaniye',
 				'hz' => 'Herero',
 				'ibb' => 'Ibibiyo',
 				'id' => 'Endonesiye',
 				'ig' => 'Igbo',
 				'is' => 'Islànde',
 				'it' => 'Italiye',
 				'iu' => 'Inuktitit',
 				'ja' => 'Sapone',
 				'ka' => 'Sorsiye',
 				'kk' => 'Kasax',
 				'km' => 'Xmer',
 				'kn' => 'Kannadaa',
 				'ko' => 'Koreye',
 				'kok' => 'Konkani',
 				'kr' => 'Kanuri',
 				'kru' => 'Kuruks',
 				'ks' => 'Kashmiri',
 				'ku' => 'Kurdi',
 				'ky' => 'Kirgiis',
 				'la' => 'Latin',
 				'lb' => 'Liksàmbursuwaa',
 				'lo' => 'Laaw',
 				'lt' => 'Lituyaniye',
 				'lv' => 'Letoniye',
 				'men' => 'Mende',
 				'mg' => 'Malagasi',
 				'mi' => 'Mawri',
 				'mk' => 'Maseduwaane',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongoliye',
 				'mni' => 'Manipuri',
 				'moh' => 'Mowak',
 				'mr' => 'Marati',
 				'ms' => 'Malay',
 				'mt' => 'Malt',
 				'my' => 'Birmes',
 				'ne' => 'Nepale',
 				'niu' => 'Niweyan',
 				'nl' => 'Neyerlànde',
 				'nl_BE' => 'Belsig',
 				'no' => 'Nerwesiye',
 				'ny' => 'Sewa',
 				'oc' => 'Ositan',
 				'om' => 'Oromo',
 				'or' => 'Oja',
 				'pa' => 'Punjabi',
 				'pap' => 'Papiyamento',
 				'pl' => 'Polone',
 				'ps' => 'Pasto',
 				'pt' => 'Purtugees',
 				'pt_BR' => 'Purtugees bu Bresil',
 				'pt_PT' => 'Portugees bu Tugël',
 				'qu' => 'Kesuwa',
 				'quc' => 'Kishe',
 				'rm' => 'Romaas',
 				'ro' => 'Rumaniyee',
 				'ru' => 'Rus',
 				'rw' => 'Kinyarwànda',
 				'sa' => 'Sanskrit',
 				'sah' => 'Saxa',
 				'sat' => 'Santali',
 				'sd' => 'Sindi',
 				'se' => 'Penku Sami',
 				'si' => 'Sinala',
 				'sk' => 'Eslowaki (Eslowak)',
 				'sl' => 'Esloweniye',
 				'sma' => 'Sami gu Saalum',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Eskolt Sami',
 				'so' => 'Somali (làkk)',
 				'sq' => 'Albane',
 				'sr' => 'Serb',
 				'sv' => 'Suweduwaa',
 				'syr' => 'Siryak',
 				'ta' => 'Tamil',
 				'te' => 'Telugu',
 				'tg' => 'Tajis',
 				'th' => 'Tay',
 				'ti' => 'Tigriña',
 				'tk' => 'Tirkmen',
 				'to' => 'Tongan',
 				'tr' => 'Tirk',
 				'tt' => 'Tatar',
 				'tzm' => 'Tamasis gu Digg Atlaas',
 				'ug' => 'Uygur',
 				'uk' => 'Ikreniye',
 				'und' => 'Làkk wuñ xamul',
 				'ur' => 'Urdu',
 				'uz' => 'Usbek',
 				've' => 'Wenda',
 				'vi' => 'Wiyetnaamiye',
 				'wo' => 'Wolof',
 				'yi' => 'Yidis',
 				'yo' => 'Yoruba',
 				'zh' => 'Sinuwaa',
 				'zh_Hans' => 'Sinuwaa buñ woyofal',
 				'zh_Hant' => 'Sinuwaa bu cosaan',

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
			'Arab' => 'Araab',
 			'Cyrl' => 'Sirilik',
 			'Hans' => 'Buñ woyofal',
 			'Hans@alt=stand-alone' => 'Han buñ woyofal',
 			'Hant' => 'Cosaan',
 			'Hant@alt=stand-alone' => 'Han u cosaan',
 			'Jpan' => 'Nihon no',
 			'Kore' => 'hangug-ui',
 			'Latn' => 'Latin',
 			'Zxxx' => 'Luñ bindul',
 			'Zzzz' => 'Mbind muñ xamul',

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
			'001' => 'àddina',
 			'002' => 'Africa',
 			'003' => 'North America',
 			'005' => 'Amerique du Sud',
 			'009' => 'Oseani',
 			'011' => 'Sowwu Afrique',
 			'013' => 'Amerique Centrale',
 			'014' => 'Penku Afrique',
 			'015' => 'Afrique du Nord',
 			'017' => 'Moyen Afrique',
 			'018' => 'Afrique du Sud',
 			'019' => 'Amerika',
 			'021' => 'amerique du nord',
 			'029' => 'Caraïbe',
 			'030' => 'Asie penku',
 			'034' => 'Asie du Sud',
 			'035' => 'Asie Sud-est',
 			'039' => 'Sud Europe',
 			'053' => 'Ostralasi',
 			'054' => 'Melanesi',
 			'057' => 'Mikronesi',
 			'061' => 'Polineesi',
 			'142' => 'Asia',
 			'143' => 'Asie centrale',
 			'145' => 'Asie sowwu jàng',
 			'150' => 'Europe',
 			'151' => 'Europe bu penku',
 			'154' => 'Europe du nord',
 			'155' => 'Europe sowwu jàng',
 			'202' => 'Afrique sub-saharienne',
 			'419' => 'Amerique Latine',
 			'AC' => 'Ile Ascension',
 			'AD' => 'Andoor',
 			'AE' => 'Emira Arab Ini',
 			'AF' => 'Afganistaŋ',
 			'AG' => 'Antiguwa ak Barbuda',
 			'AI' => 'Angiiy',
 			'AL' => 'Albani',
 			'AM' => 'Armeni',
 			'AO' => 'Àngolaa',
 			'AQ' => 'Antarktik',
 			'AR' => 'Arsàntin',
 			'AS' => 'Samowa bu Amerig',
 			'AT' => 'Ótiriis',
 			'AU' => 'Ostarali',
 			'AW' => 'Aruba',
 			'AX' => 'Duni Aalànd',
 			'AZ' => 'Aserbayjaŋ',
 			'BA' => 'Bosni Ersegowin',
 			'BB' => 'Barbad',
 			'BD' => 'Bengalades',
 			'BE' => 'Belsig',
 			'BF' => 'Burkina Faaso',
 			'BG' => 'Bilgari',
 			'BH' => 'Bahreyin',
 			'BI' => 'Burundi',
 			'BJ' => 'Benee',
 			'BL' => 'Saŋ Bartalemi',
 			'BM' => 'Bermid',
 			'BN' => 'Burney',
 			'BO' => 'Boliwi',
 			'BQ' => 'Pays-Bas bu Caraïbe',
 			'BR' => 'Beresil',
 			'BS' => 'Bahamas',
 			'BT' => 'Butaŋ',
 			'BV' => 'Dunu Buwet',
 			'BW' => 'Botswana',
 			'BY' => 'Belaris',
 			'BZ' => 'Belis',
 			'CA' => 'Kanadaa',
 			'CC' => 'Duni Koko (Kilin)',
 			'CD' => 'Kongo (R K D)',
 			'CF' => 'Repiblik Sàntar Afrik',
 			'CG' => 'Réewum Kongo',
 			'CH' => 'Siwis',
 			'CI' => 'Kodiwaar',
 			'CK' => 'Duni Kuuk',
 			'CL' => 'Sili',
 			'CM' => 'Kamerun',
 			'CN' => 'Siin',
 			'CO' => 'Kolombi',
 			'CP' => 'Ile Clipperton',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kabo Werde',
 			'CW' => 'Kursawo',
 			'CX' => 'Dunu Kirismas',
 			'CY' => 'Siipar',
 			'CZ' => 'Réewum Cek',
 			'DE' => 'Almaañ',
 			'DG' => 'Garsiya',
 			'DJ' => 'Jibuti',
 			'DK' => 'Danmàrk',
 			'DM' => 'Dominik',
 			'DO' => 'Repiblik Dominiken',
 			'DZ' => 'Alseri',
 			'EA' => 'Ceuta & Melilla',
 			'EC' => 'Ekwaatër',
 			'EE' => 'Estoni',
 			'EG' => 'Esipt',
 			'EH' => 'Sahara bu sowwu',
 			'ER' => 'Eritere',
 			'ES' => 'Españ',
 			'ET' => 'Ecopi',
 			'EU' => 'EZ',
 			'EZ' => 'Eurozone',
 			'FI' => 'Finlànd',
 			'FJ' => 'Fijji',
 			'FK' => 'Duni Falkland',
 			'FM' => 'Mikoronesi',
 			'FO' => 'Duni Faro',
 			'FR' => 'Faraans',
 			'GA' => 'Gaboŋ',
 			'GB' => 'Ruwaayom Ini',
 			'GD' => 'Garanad',
 			'GE' => 'Seworsi',
 			'GF' => 'Guyaan Farañse',
 			'GG' => 'Gernase',
 			'GH' => 'Gana',
 			'GI' => 'Sibraltaar',
 			'GL' => 'Girinlànd',
 			'GM' => 'Gàmbi',
 			'GN' => 'Gine',
 			'GP' => 'Guwaadelup',
 			'GQ' => 'Gine Ekuwatoriyal',
 			'GR' => 'Gerees',
 			'GS' => 'Seworsi di Sid ak Duni Sàndwiis di Sid',
 			'GT' => 'Guwatemala',
 			'GU' => 'Guwam',
 			'GW' => 'Gine-Bisaawóo',
 			'GY' => 'Giyaan',
 			'HK' => 'Ooŋ Koŋ',
 			'HM' => 'Duni Hërd ak Duni MakDonald',
 			'HN' => 'Onduraas',
 			'HR' => 'Korowasi',
 			'HT' => 'Ayti',
 			'HU' => 'Ongari',
 			'IC' => 'Ile Canary',
 			'ID' => 'Indonesi',
 			'IE' => 'Irlànd',
 			'IL' => 'Israyel',
 			'IM' => 'Dunu Maan',
 			'IN' => 'End',
 			'IO' => 'Terituwaaru Brëtaañ ci Oseyaa Enjeŋ',
 			'IQ' => 'Irag',
 			'IR' => 'Iraŋ',
 			'IS' => 'Islànd',
 			'IT' => 'Itali',
 			'JE' => 'Serse',
 			'JM' => 'Samayig',
 			'JO' => 'Sordani',
 			'JP' => 'Sàppoŋ',
 			'KE' => 'Keeña',
 			'KG' => 'Kirgistaŋ',
 			'KH' => 'Kàmboj',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoor',
 			'KN' => 'Saŋ Kits ak Newis',
 			'KP' => 'Kore Noor',
 			'KR' => 'Corée du Sud',
 			'KW' => 'Kowet',
 			'KY' => 'Duni Kaymaŋ',
 			'KZ' => 'Kasaxstaŋ',
 			'LA' => 'Lawos',
 			'LB' => 'Libaa',
 			'LC' => 'Saŋ Lusi',
 			'LI' => 'Liktensteyin',
 			'LK' => 'Siri Lànka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Litiyani',
 			'LU' => 'Liksàmbur',
 			'LV' => 'Letoni',
 			'LY' => 'Libi',
 			'MA' => 'Marog',
 			'MC' => 'Monako',
 			'MD' => 'Moldawi',
 			'ME' => 'Montenegoro',
 			'MF' => 'Saŋ Marteŋ',
 			'MG' => 'Madagaskaar',
 			'MH' => 'Duni Marsaal',
 			'MK' => 'Maseduwaan bëj Gànnaar',
 			'ML' => 'Mali',
 			'MM' => 'Miyanmaar',
 			'MN' => 'Mongoli',
 			'MO' => 'Makaawo',
 			'MP' => 'Duni Mariyaan Noor',
 			'MQ' => 'Martinik',
 			'MR' => 'Mooritani',
 			'MS' => 'Mooseraa',
 			'MT' => 'Malt',
 			'MU' => 'Moriis',
 			'MV' => 'Maldiiw',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malesi',
 			'MZ' => 'Mosàmbig',
 			'NA' => 'Namibi',
 			'NC' => 'Nuwel Kaledoni',
 			'NE' => 'Niiseer',
 			'NF' => 'Dunu Norfolk',
 			'NG' => 'Niseriya',
 			'NI' => 'Nikaraguwa',
 			'NL' => 'Peyi Baa',
 			'NO' => 'Norwees',
 			'NP' => 'Nepaal',
 			'NR' => 'Nawru',
 			'NU' => 'Niw',
 			'NZ' => 'Nuwel Selànd',
 			'OM' => 'Omaan',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesi Farañse',
 			'PG' => 'Papuwasi Gine Gu Bees',
 			'PH' => 'Filipin',
 			'PK' => 'Pakistaŋ',
 			'PL' => 'Poloñ',
 			'PM' => 'Saŋ Peer ak Mikeloŋ',
 			'PN' => 'Duni Pitkayirn',
 			'PR' => 'Porto Riko',
 			'PS' => 'réew yu Palestine',
 			'PS@alt=short' => 'Palestine',
 			'PT' => 'Portigaal',
 			'PW' => 'Palaw',
 			'PY' => 'Paraguwe',
 			'QA' => 'Kataar',
 			'QO' => 'Oceanie',
 			'RE' => 'Reeñoo',
 			'RO' => 'Rumani',
 			'RS' => 'Serbi',
 			'RU' => 'Risi',
 			'RW' => 'Ruwànda',
 			'SA' => 'Arabi Sawudi',
 			'SB' => 'Duni Salmoon',
 			'SC' => 'Seysel',
 			'SD' => 'Sudaŋ',
 			'SE' => 'Suwed',
 			'SG' => 'Singapuur',
 			'SH' => 'Saŋ Eleen',
 			'SI' => 'Esloweni',
 			'SJ' => 'Swalbaar ak Jan Mayen',
 			'SK' => 'Eslowaki',
 			'SL' => 'Siyera Lewon',
 			'SM' => 'San Marino',
 			'SN' => 'Senegaal',
 			'SO' => 'Somali',
 			'SR' => 'Sirinam',
 			'SS' => 'Sudaŋ di Sid',
 			'ST' => 'Sawo Tome ak Pirinsipe',
 			'SV' => 'El Salwadoor',
 			'SX' => 'Sin Marten',
 			'SY' => 'Siri',
 			'SZ' => 'Suwasilànd',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Duni Tirk ak Kaykos',
 			'TD' => 'Càdd',
 			'TF' => 'Teer Ostraal gu Fraas',
 			'TG' => 'Togo',
 			'TH' => 'Taylànd',
 			'TJ' => 'Tajikistaŋ',
 			'TK' => 'Tokoloo',
 			'TL' => 'Timor Leste',
 			'TL@alt=variant' => 'Timor oriental',
 			'TM' => 'Tirkmenistaŋ',
 			'TN' => 'Tinisi',
 			'TO' => 'Tonga',
 			'TR' => 'Tirki',
 			'TT' => 'Tirinite ak Tobago',
 			'TV' => 'Tuwalo',
 			'TW' => 'Taywan',
 			'TZ' => 'Taŋsani',
 			'UA' => 'Ikeren',
 			'UG' => 'Ugànda',
 			'UM' => 'Duni Amerig Utar meer',
 			'UN' => 'United Nations',
 			'US' => 'Etaa Sini',
 			'UY' => 'Uruge',
 			'UZ' => 'Usbekistaŋ',
 			'VA' => 'Site bu Watikaa',
 			'VC' => 'Saŋ Weesaa ak Garanadin',
 			'VE' => 'Wenesiyela',
 			'VG' => 'Duni Wirsin yu Brëtaañ',
 			'VI' => 'Duni Wirsin yu Etaa-sini',
 			'VN' => 'Wiyetnam',
 			'VU' => 'Wanuatu',
 			'WF' => 'Walis ak Futuna',
 			'WS' => 'Samowa',
 			'XA' => 'Pseudo-aksan',
 			'XB' => 'Pseudo-bidi',
 			'XK' => 'Kosowo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayot',
 			'ZA' => 'Afrik di Sid',
 			'ZM' => 'Sàmbi',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Gox buñ xamul',

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
 				'gregorian' => q{Arminaatu Gregoriyee},
 				'iso8601' => q{ISO-8601 Calendar},
 			},
 			'collation' => {
 				'standard' => q{SSO (Toftalin wiñ gën a xam)},
 			},
 			'numbers' => {
 				'latn' => q{Siifari Tugal},
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
			'metric' => q{Metrik},

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
			auxiliary => qr{[ã h v z]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a à b c d e é ë f g i j k l m n ñ ŋ o ó p q r s t u w x y]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'other' => q({0} g-force),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} g-force),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'other' => q(Bft {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'other' => q(Bft {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'other' => q({0}B),
					},
				},
				'short' => {
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
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:waaw|wa|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:déedet|dé|no|n)$' }
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
					'other' => '0 thousand',
				},
				'10000' => {
					'other' => '00 thousand',
				},
				'100000' => {
					'other' => '000 thousand',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => 'Vote 00M',
				},
				'100000000' => {
					'other' => 'Vote 000M',
				},
				'1000000000' => {
					'other' => '0B',
				},
				'10000000000' => {
					'other' => '00B',
				},
				'100000000000' => {
					'other' => 'Vote 000G',
				},
			},
			'short' => {
				'1000000000' => {
					'other' => '0B',
				},
				'10000000000' => {
					'other' => '00B',
				},
				'100000000000' => {
					'other' => '000B',
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
				'currency' => q(United Arab Emirates Dirham),
				'other' => q(UAE dirhams),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghan Afghani),
				'other' => q(Afghan Afghanis),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albanian Lek),
				'other' => q(Albanian lekë),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenian Dram),
				'other' => q(Armenian drams),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Netherlands Antillean Guilder),
				'other' => q(Netherlands Antillean guilders),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolan Kwanza),
				'other' => q(Angolan kwanzas),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentine Peso),
				'other' => q(Argentine pesos),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Australian Dollar),
				'other' => q(Australian dollars),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruban Florin),
				'other' => q(Aruban florin),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbaijani Manat),
				'other' => q(Azerbaijani manats),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnia-Herzegovina Convertible Mark),
				'other' => q(Bosnia-Herzegovina convertible marks),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadian Dollar),
				'other' => q(Barbadian dollars),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladeshi Taka),
				'other' => q(Bangladeshi takas),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgarian Lev),
				'other' => q(Bulgarian leva),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahraini Dinar),
				'other' => q(Bahraini dinars),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundian Franc),
				'other' => q(Burundian francs),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Vote BMD),
				'other' => q(Bermudan dollars),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei Dollar),
				'other' => q(Brunei dollars),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivian Boliviano),
				'other' => q(Bolivian bolivianos),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real bu Bresil),
				'other' => q(Real yu Bresil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamian Dollar),
				'other' => q(Bahamian dollars),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutanese Ngultrum),
				'other' => q(Bhutanese ngultrums),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswanan Pula),
				'other' => q(Botswanan pulas),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Belarusian Ruble),
				'other' => q(Belarusian rubles),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize Dollar),
				'other' => q(Belize dollars),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Vote CAD),
				'other' => q(Canadian dollars),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Congolese Franc),
				'other' => q(Congolese francs),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Swiss Franc),
				'other' => q(Swiss francs),
			},
		},
		'CLP' => {
			symbol => 'Vote $',
			display_name => {
				'currency' => q(Chilean Peso),
				'other' => q(Chilean pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Chinese Yuan \(offshore\)),
				'other' => q(Chinese yuan \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan bu Siin),
				'other' => q(Yuan yu Siin),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Colombian Peso),
				'other' => q(Colombian pesos),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rican Colón),
				'other' => q(Costa Rican colóns),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Cuban Convertible Peso),
				'other' => q(Cuban convertible pesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Cuban Peso),
				'other' => q(Cuban pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Cape Verdean Escudo),
				'other' => q(Cape Verdean escudos),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Czech Koruna),
				'other' => q(Czech korunas),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djiboutian Franc),
				'other' => q(Djiboutian francs),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danish Krone),
				'other' => q(Danish kroner),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominican Peso),
				'other' => q(Dominican pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerian Dinar),
				'other' => q(Algerian dinars),
			},
		},
		'EGP' => {
			symbol => 'EGPP',
			display_name => {
				'currency' => q(Egyptian Pound),
				'other' => q(Egyptian pounds),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrean Nakfa),
				'other' => q(Eritrean nakfas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopian Birr),
				'other' => q(Ethiopian birrs),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fijian Dollar),
				'other' => q(Fijian dollars),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(FKPS),
				'other' => q(Falkland Islands pounds),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pound bu Grànd Brëtaañ),
				'other' => q(Pound yu Grànd Brëtaañ),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgian Lari),
				'other' => q(Georgian laris),
			},
		},
		'GHS' => {
			symbol => 'GHS.',
			display_name => {
				'currency' => q(Ghanaian Cedi),
				'other' => q(Ghanaian cedis),
			},
		},
		'GIP' => {
			symbol => 'GIIP',
			display_name => {
				'currency' => q(Vote GIP),
				'other' => q(GIPS),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambian Dalasi),
				'other' => q(Gambian dalasis),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinean Franc),
				'other' => q(Guinean francs),
			},
		},
		'GTQ' => {
			symbol => 'GT Q',
			display_name => {
				'currency' => q(GT),
				'other' => q(Guatemalan quetzals),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyanaese Dollar),
				'other' => q(Guyanaese dollars),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hong Kong Dollar),
				'other' => q(Hong Kong dollars),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduran Lempira),
				'other' => q(Honduran lempiras),
			},
		},
		'HRK' => {
			symbol => 'HRKS',
			display_name => {
				'currency' => q(Croatian Kuna),
				'other' => q(Croatian kunas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haitian Gourde),
				'other' => q(Haitian gourdes),
			},
		},
		'HUF' => {
			symbol => 'Vote Ft',
			display_name => {
				'currency' => q(Hungarian Forint),
				'other' => q(Hungarian forints),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesian Rupiah),
				'other' => q(Indonesian rupiahs),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Israeli New Shekel),
				'other' => q(Israeli new shekels),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupee bu End),
				'other' => q(Rupee yu End),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iraqi Dinar),
				'other' => q(Iraqi dinars),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iranian Rial),
				'other' => q(Iranian rials),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Icelandic Króna),
				'other' => q(Icelandic krónur),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaican Dollar),
				'other' => q(Jamaican dollars),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordanian Dinar),
				'other' => q(Jordanian dinars),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen bu Sapoŋ),
				'other' => q(Yen yu Sapoŋ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenyan Shilling),
				'other' => q(Kenyan shillings),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kyrgystani Som),
				'other' => q(Kyrgystani soms),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Cambodian Riel),
				'other' => q(Cambodian riels),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Comorian Franc),
				'other' => q(Comorian francs),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(North Korean Won),
				'other' => q(North Korean won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(South Korean Won),
				'other' => q(South Korean won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwaiti Dinar),
				'other' => q(Kuwaiti dinars),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Cayman Islands Dollar),
				'other' => q(Cayman Islands dollars),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazakhstani Tenge),
				'other' => q(Kazakhstani tenges),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laotian Kip),
				'other' => q(Laotian kips),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Lebanese Pound),
				'other' => q(Lebanese pounds),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankan Rupee),
				'other' => q(Sri Lankan rupees),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberian Dollar),
				'other' => q(Liberian dollars),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
				'other' => q(Lesotho lotis),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyan Dinar),
				'other' => q(Libyan dinars),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroccan dirhams),
				'other' => q(Moroccan dirhams),
			},
		},
		'MDL' => {
			symbol => 'Vote MDL',
			display_name => {
				'currency' => q(Moldovan Leu),
				'other' => q(Moldovan lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagasy Ariary),
				'other' => q(Malagasy ariaries),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Macedonian Denar),
				'other' => q(Macedonian denari),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmar Kyat),
				'other' => q(Myanmar kyats),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongolian Tugrik),
				'other' => q(Mongolian tugriks),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macanese Pataca),
				'other' => q(Macanese patacas),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritanian Ouguiya),
				'other' => q(Mauritanian ouguiyas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritian Rupee),
				'other' => q(Mauritian rupees),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivian Rufiyaa),
				'other' => q(Maldivian rufiyaas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawian Kwacha),
				'other' => q(Malawian kwachas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexican Peso),
				'other' => q(Mexican pesos),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaysian Ringgit),
				'other' => q(Malaysian ringgits),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambican Metical),
				'other' => q(Mozambican meticals),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibian Dollar),
				'other' => q(Namibian dollars),
			},
		},
		'NGN' => {
			symbol => 'NGN.',
			display_name => {
				'currency' => q(Nigerian Naira),
				'other' => q(Nigerian nairas),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguan Córdoba),
				'other' => q(Nicaraguan córdobas),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norwegian Krone),
				'other' => q(Norwegian kroner),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalese Rupee),
				'other' => q(Nepalese rupees),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(New Zealand Dollar),
				'other' => q(New Zealand dollars),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omani Rial),
				'other' => q(Omani rials),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamanian Balboa),
				'other' => q(Panamanian balboas),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruvian Sols),
				'other' => q(Peruvian soles),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua New Guinean Kina),
				'other' => q(Papua New Guinean kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Philippine Peso),
				'other' => q(Philippine pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistani Rupee),
				'other' => q(Pakistani rupees),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polish Zloty),
				'other' => q(Polish zlotys),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayan Guaranis),
				'other' => q(Paraguayan guaranis),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatari Riyal),
				'other' => q(Qatari riyals),
			},
		},
		'RON' => {
			symbol => 'Vote lei',
			display_name => {
				'currency' => q(Romanian Leu),
				'other' => q(Romanian lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbian Dinar),
				'other' => q(Serbian dinars),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Ruble bi Rsis),
				'other' => q(Ruble yu Risi),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwandan Franc),
				'other' => q(Rwandan francs),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Riyal),
				'other' => q(Saudi riyals),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomon Islands Dollar),
				'other' => q(Solomon Islands dollars),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellois Rupee),
				'other' => q(Seychellois rupees),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudanese Pound),
				'other' => q(Sudanese pounds),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Swedish Krona),
				'other' => q(Swedish kronor),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapore Dollar),
				'other' => q(Singapore dollars),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena Pound),
				'other' => q(St. Helena pounds),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leonean Leone),
				'other' => q(Sierra Leonean leones),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leonean Leone \(1964—2022\)),
				'other' => q(Sierra Leonean leones \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali Shilling),
				'other' => q(Somali shillings),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinamese Dollar),
				'other' => q(Surinamese dollars),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(South Sudanese Pound),
				'other' => q(South Sudanese pounds),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé & Príncipe Dobra),
				'other' => q(São Tomé & Príncipe dobras),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Syrian Pound),
				'other' => q(Syrian pounds),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazi Lilangeni),
				'other' => q(Swazi emalangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Thai Baht),
				'other' => q(Thai baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tajikistani Somoni),
				'other' => q(Tajikistani somonis),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistani Manat),
				'other' => q(Turkmenistani manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisian Dinar),
				'other' => q(Tunisian dinars),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongan Paʻanga),
				'other' => q(Tongan paʻanga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkish Lira),
				'other' => q(Turkish Lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad & Tobago Dollar),
				'other' => q(Trinidad & Tobago dollars),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(New Taiwan Dollar),
				'other' => q(New Taiwan dollars),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzanian Shilling),
				'other' => q(Tanzanian shillings),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(UAHS),
				'other' => q(Ukrainian hryvnias),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandan Shilling),
				'other' => q(Ugandan shillings),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dolaaru US),
				'other' => q(Dolaari US),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayan Peso),
				'other' => q(Uruguayan pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Uzbekistani Som),
				'other' => q(Uzbekistani som),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezuelan Bolívar),
				'other' => q(Venezuelan bolívars),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vietnamese Dong),
				'other' => q(Vietnamese dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu Vatu),
				'other' => q(Vanuatu vatus),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoan Tala),
				'other' => q(Samoan tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Central African CFA Franc),
				'other' => q(Central African CFA francs),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(East Caribbean Dollar),
				'other' => q(East Caribbean dollars),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franc CFA bu Afrik Sowwu-jant),
				'other' => q(Franc CFA yu Afrik Sowwu-jant),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP Franc),
				'other' => q(CFP francs),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Xaalis buñ Xamul),
				'other' => q(\(xaalis buñ xamul\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yemeni Rial),
				'other' => q(Yemeni rials),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(South African Rand),
				'other' => q(South African rand),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambian Kwacha),
				'other' => q(Zambian kwachas),
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
							'Sam',
							'Few',
							'Mar',
							'Awr',
							'Mee',
							'Suw',
							'Sul',
							'Ut',
							'Sàt',
							'Okt',
							'Now',
							'Des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Samwiyee',
							'Fewriyee',
							'Mars',
							'Awril',
							'Mee',
							'Suwe',
							'Sulet',
							'Ut',
							'Sàttumbar',
							'Oktoobar',
							'Nowàmbar',
							'Desàmbar'
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
						mon => 'Alt',
						tue => 'Tal',
						wed => 'Àla',
						thu => 'Alx',
						fri => 'Àjj',
						sat => 'Ase',
						sun => 'Dib'
					},
					wide => {
						mon => 'Altine',
						tue => 'Talaata',
						wed => 'Àlarba',
						thu => 'Alxamis',
						fri => 'Àjjuma',
						sat => 'Aseer',
						sun => 'Dibéer'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'Alt',
						tue => 'Tal',
						wed => 'Àla',
						thu => 'Alx',
						fri => 'Àjj',
						sat => 'Ase',
						sun => 'Dib'
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
					abbreviated => {0 => '1er Tri',
						1 => '2e Tri',
						2 => '3e Tri',
						3 => '4e Tri'
					},
					wide => {0 => '1er Trimestar',
						1 => '2e Trimestar',
						2 => '3e Trimestar',
						3 => '4e Trimestar'
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
					'am' => q{Sub},
					'pm' => q{Ngo},
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
				'0' => 'JC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'av. JC'
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
			'full' => q{EEEE, d MMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{dd-MM-y},
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
			'full' => q{{1} - {0}},
			'long' => q{{1} - {0}},
			'medium' => q{{1} - {0}},
			'short' => q{{1} - {0}},
		},
		'gregorian' => {
			'full' => q{{1} - {0}},
			'long' => q{{1} - {0}},
			'medium' => q{{1} - {0}},
			'short' => q{{1} - {0}},
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
			GyMMM => q{MMM, y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d/MM/y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM, y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			GyMd => q{dd-MM-y GGGGG},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
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
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Afghanistan' => {
			long => {
				'standard' => q#waxtu Afganistan#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Waxtu Afrique Centrale#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Waxtu Afrique sowwu jant#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Afrique du Sud#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Afrique du sowwu jant#,
				'generic' => q#Waxtu sowwu Afrique#,
				'standard' => q#Waxtu buñ miin ci sowwu Afrique#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Waxtu bëccëg ci Alaska#,
				'generic' => q#Waxtu Alaska#,
				'standard' => q#Waxtu buñ miin ci Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Waxtu ete bu Amazon#,
				'generic' => q#Waxtu Amazon#,
				'standard' => q#Waxtu buñ jagleel Amazon#,
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q#CDT (waxtu bëccëgu sàntaraal#,
				'generic' => q#CT (waxtu sàntaral)#,
				'standard' => q#CST (waxtu estàndaaru sàntaraal)#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#EDT (waxtu bëccëgu penku)#,
				'generic' => q#ET waxtu penku#,
				'standard' => q#EST (waxtu estàndaaru penku)#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#MDT (waxtu bëccëgu tundu)#,
				'generic' => q#MT (waxtu tundu)#,
				'standard' => q#MST (waxtu estàndaaru tundu)#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#PDT (waxtu bëccëgu pasifik)#,
				'generic' => q#PT (waxtu pasifik)#,
				'standard' => q#PST (waxtu estàndaaru pasifik)#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia waxtu bëccëg#,
				'generic' => q#Waxtu Apia#,
				'standard' => q#Waxtu buñ miin ci Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Waxtu bëccëg ci Araab#,
				'generic' => q#Waxtu araab yi#,
				'standard' => q#Waxtu buñ miin ci Araab#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Waxtu ete bu Argentine#,
				'generic' => q#Waxtu Arsantiin#,
				'standard' => q#Waxtu buñ miin ci Arsantiin#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#waxtu ete bu sowwu Argentine#,
				'generic' => q#waxtu sowwu Argentine#,
				'standard' => q#Waxtu buñ miin ci sowwu Argentine#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Waxtu ete bu Armeni#,
				'generic' => q#Waxtu Armeni#,
				'standard' => q#Waxtu buñ miin ci Armeni#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ADT (waxtu bëccëgu atlàntik)#,
				'generic' => q#AT (waxtu atlàntik)#,
				'standard' => q#AST (waxtu estàndaaru penku)#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Waxtu bëccëg ci diggu Australie#,
				'generic' => q#Waxtu Australie bu diggi bi#,
				'standard' => q#Waxtu buñ miin ci Australie#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Waxtu bëccëg ci diggu sowwu Australie#,
				'generic' => q#Waxtu sowwu Australie#,
				'standard' => q#Waxtu buñ miin ci diggu sowwu Australie#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Waxtu buñ miin ci penku Australie#,
				'generic' => q#waxtu penku Australie#,
				'standard' => q#Waxtu penku bu Australie#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Waxtu bëccëg bu sowwu Australie#,
				'generic' => q#waxtu Australie bu bëtu Soow#,
				'standard' => q#Waxtu buñ miin ci sowwu Australie#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Waxtu ete bu Azerbaïdjan#,
				'generic' => q#Azerbaïdjan Waxtu#,
				'standard' => q#Waxtu Azerbaïdjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azores waxtu ete#,
				'generic' => q#Waxtu Azores#,
				'standard' => q#Waxtu buñ miin ci Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Waxtu ete bu Bangladesh#,
				'generic' => q#Waxtu Bangladesh#,
				'standard' => q#Waxtu buñ miin ci Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#waxtu Bhoutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Waxtu Bolivie#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia summer time#,
				'generic' => q#Waxtu Bresil#,
				'standard' => q#Brasilia time#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Cape Verde ci jamonoy ete#,
				'generic' => q#Cape Verde#,
				'standard' => q#Cape Verde waxtu#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro Standard Time#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham Daylight Time#,
				'generic' => q#waxtu Chatham#,
				'standard' => q#Chatham Standard Time#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Waxtu ete bu Sili#,
				'generic' => q#Waxtu Sili#,
				'standard' => q#Waxtu buñ miin ci Sili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chine waxtu bëccëg#,
				'generic' => q#Waxtu Chine#,
				'standard' => q#Waxtu buñ miin ci Chine#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#waxtu ile bu noel#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Waxtu ile Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Jamonoy ete ci Kolombi#,
				'generic' => q#Waxtu Kolombi#,
				'standard' => q#Waxtu buñ miin ci Kolombi#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Ile Cook xaaju ete#,
				'generic' => q#Waxtu Ile Cook#,
				'standard' => q#Waxtu buñ miin ci Ile Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cuba waxtu bëccëg#,
				'generic' => q#Waxtu Cuba#,
				'standard' => q#waxtu buñ miin ci Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Waxtu Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Timor oriental#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Jamonoy ete ci Ile de Pâques#,
				'generic' => q#Waxtu ile bu Pâques#,
				'standard' => q#Waxtu buñ miin ci Ile de Pâques#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#waxtu Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#CUT (waxtu iniwelsel yuñ boole)#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Dëkk buñ xamul#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#waxtu Irlande#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Waxtu ete bu Grande Bretagne#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#CEST (waxtu ete wu ëroop sàntaraal)#,
				'generic' => q#CTE (waxtu ëroop sàntaraal)#,
				'standard' => q#CEST (waxtu estàndaaru ëroop sàntaraal)#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#EEST (waxtu ete wu ëroop u penku)#,
				'generic' => q#EET (waxtu ëroop u penku)#,
				'standard' => q#EEST (waxtu estàndaaru ëroop u penku)#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#waxtu penku Europe#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#WEST (waxtu ete wu ëroop u sowwu-jant)#,
				'generic' => q#WET (waxtu ëroop u sowwu-jant#,
				'standard' => q#WEST (waxtu estàndaaru ëroop u sowwu-jant)#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Jamonoy ete ci ile Falkland#,
				'generic' => q#Falkland time#,
				'standard' => q#Falkland waxtu buñ miin#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Jamonoy ete ci Fiji#,
				'generic' => q#waxtu Fidji#,
				'standard' => q#Fidji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Guyane française#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Waxtu Sud ak Antarctique bu Français#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#GMT (waxtu Greenwich)#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#waxtu galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Waxtu Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgie waxtu ete#,
				'generic' => q#Waxtu Georgie#,
				'standard' => q#Georgie waxtu#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#waxtu ile Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Waxtu ete bu penku Greenland#,
				'generic' => q#waxtu penku Greenland#,
				'standard' => q#Waxtu buñ miin ci penku Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#waxtu ete bu sowwu Groenland#,
				'generic' => q#waxtu sowwu Greenland#,
				'standard' => q#waxtu buñ miin ci sowwu Groenland#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Waxtu Golf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Waxtu Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Waxtu bëccëg bu Hawaii-Aleutian#,
				'generic' => q#Waxtu Hawaii-Aleutian#,
				'standard' => q#Waxtu buñ jagleel Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Jamonoy ete ci Hong Kong#,
				'generic' => q#waxtu Hong Kong#,
				'standard' => q#waxtu buñ miin ci Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd waxtu ete#,
				'generic' => q#Hovd waxtu#,
				'standard' => q#Hovd waxtu standard#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Waxtu Inde#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Waxtu géeju Inde#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#waxtu Indochine#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Waxtu Enndonesi bu diggi bi#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#waxtu penku Enndonesi#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#waxtu sowwu Enndonesi#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Waxtu bëccëg ci Iran#,
				'generic' => q#Waxtu Iran#,
				'standard' => q#Iran waxtu buñ miin#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Waxtu ete bu Irkutsk#,
				'generic' => q#Waxtu rkutsk#,
				'standard' => q#waxtu Irkutsk time#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel waxtu bëccëg#,
				'generic' => q#Waxtu Israel#,
				'standard' => q#Waxtu buñ miin ci Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japon waxtu bëccëg#,
				'generic' => q#Japon#,
				'standard' => q#Waxtu japon#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Waxtu Kazakhstaan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Kazakhstan penku#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Kazakhstan bu sowwu jant#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#waxtu bëccëg ci Kore#,
				'generic' => q#waxtu Kore#,
				'standard' => q#waxtu buñ miin ci Kore#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Waxtu Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk ci jamonoy ete#,
				'generic' => q#Waxtu Krasnoyarsk#,
				'standard' => q#Krasnoyarsk waxtu#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Waxtu Kirgistan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Waxtu Ile Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#ord Howe Daylight Time#,
				'generic' => q#Lord Howe Time#,
				'standard' => q#Lord Howe waxtu buñ miin#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Waxtu ete bu Magadan#,
				'generic' => q#Waxtu Magadaan#,
				'standard' => q#Magadan, waxtu#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysie#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Waxtu Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Waxtu Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Waxtu Ile Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Waxtu ete bu Maurice#,
				'generic' => q#waxtu Maurice#,
				'standard' => q#Waxtu buñ miin ci Maurice#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#waxtu Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Waxtu bëccëg ci Pacific Mexique#,
				'generic' => q#waxtu pasifik bu Mexik#,
				'standard' => q#Waxtu buñ miin ci pasifik bu Mexico#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaan Baatar time#,
				'generic' => q#Ulaan Baatar#,
				'standard' => q#Ulaanbatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Waxtu ete bu Moscou#,
				'generic' => q#Waxtu Moscow#,
				'standard' => q#Moscow Waxtu#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#waxtu Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#waxtu Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#waxtu Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Waxtu ete bu Nouvelle Caledonie#,
				'generic' => q#Waxtu New Caledonie#,
				'standard' => q#Waxtu buñ miin ci Caledonie bu bees#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Nouvelle-Zélande#,
				'generic' => q#Waxtu Nouvelle-Zélande#,
				'standard' => q#Waxtu buñ miin ci Nouvelle-Zélande#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Terre-Neuve#,
				'generic' => q#waxtu Terre-Neuve#,
				'standard' => q#Terre Neuve#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Waxtu Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#waxtu bëccëg ci ile Norfolk#,
				'generic' => q#waxtu ile Norfolk#,
				'standard' => q#Waxtu buñ miin ci Ile Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de noronha temps d’été#,
				'generic' => q#Fernando de noronha#,
				'standard' => q#Vernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk ci jamonoy ete#,
				'generic' => q#Waxtu Nowosibirsk#,
				'standard' => q#Novosibirsk waxtu#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk waxtu ete#,
				'generic' => q#Waxtu Omsk#,
				'standard' => q#Waxtu buñ miin ci Omsk#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Waxtu ete bu Pakistan#,
				'generic' => q#Waxtu Pakistan#,
				'standard' => q#Waxtu buñ miin ci Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#waxtu Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papouasie-Nouvelle-Guiné#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguay waxtu ete#,
				'generic' => q#Waxtu Paraguay#,
				'standard' => q#paraguay waxtu#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru waxtu ete#,
				'generic' => q#Peru waxtu#,
				'standard' => q#Peru waxtu buñ miin#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Jamonoy ete ci Philippines#,
				'generic' => q#filippines waxtu#,
				'standard' => q#waxtu buñ miin ci filipiin#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#waxtu ile Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint Pierre and Miquelon#,
				'generic' => q#Saint Pierre ak Miquelon#,
				'standard' => q#Saint Pierre & Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Waxtu Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Waxtu Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#waxtu Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#waxtu ndaje#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Waxtu Rotera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin Sakhalin#,
				'generic' => q#waxtu Saxalin#,
				'standard' => q#Saxalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa waxtu bëccëg#,
				'generic' => q#waxtu Samoa#,
				'standard' => q#Samoa Standard Time#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Waxtu Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#waxtu buñ miin ci Singapuur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Waxtu Ile Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Georgie du Sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Waxtu Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#waxtu syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#waxtu Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei waxtu leeralu bis#,
				'generic' => q#Waxtu Taipei#,
				'standard' => q#Waxtu buñ miin ci Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Waxtu Tajikistaan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau time#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Jamonoy ete ci Tonga#,
				'generic' => q#Waxtu Tonga#,
				'standard' => q#Tonga waxtu buñ miin#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Waxtu Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Waxtu ete bu Turkmenistan#,
				'generic' => q#Waxtu Turkmenistan#,
				'standard' => q#Waxtu buñ miin#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Waxtu Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguay waxtu ete#,
				'generic' => q#Waxtu Urugway#,
				'standard' => q#Uruguay waxtu buñ miin#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Waxtu ete bu Ouzbékistan#,
				'generic' => q#Waxtu Ouzbékistan#,
				'standard' => q#Waxtu buñ miin ci Ouzbékistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Waxtu ete bu Vanuatu#,
				'generic' => q#Waxtu Vanuatu#,
				'standard' => q#Waxtu miin#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Waxtu Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok ci jamonoy ete#,
				'generic' => q#Waxtu Vladivostok#,
				'standard' => q#Vladivostok ci waxtu#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Jamonoy ete bu Volgograd#,
				'generic' => q#Waxtu Volgograd#,
				'standard' => q#Volgograd waxtu buñ miin#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Waxtu Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Waxtu Ile Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis & Futuna Time#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Waxtu ete bu Yakutsk#,
				'generic' => q#Yakutsk Waxtu#,
				'standard' => q#Waxtu Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jamonoy ete#,
				'generic' => q#Waxtu Yekaterinburg#,
				'standard' => q#Yekatérinbourg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Waxtu Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
