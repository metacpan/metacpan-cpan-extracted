=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Se - Package for language Northern Sami

=cut

package Locale::CLDR::Locales::Se;
# This file auto generated from Data\common\main\se.xml
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
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(eret →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nolla),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(okta),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(guokte),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(golbma),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(njeallje),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(vihtta),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(guhtta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(čieža),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(gávcci),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ovcci),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(logi),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→­nuppe­lohkái),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­logi[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←­čuođi[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←­duhát[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljon[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljard[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljon[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biljard[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(eret →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(←←­čuođi[­→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
			},
		},
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ace' => 'acehgiella',
 				'af' => 'afrikánsagiella',
 				'an' => 'aragoniagiella',
 				'ang' => 'boares eaŋgalasgiella',
 				'ar' => 'arábagiella',
 				'ast' => 'asturiagiella',
 				'be' => 'vilges-ruoššagiella',
 				'bg' => 'bulgáriagiella',
 				'bn' => 'bengalgiella',
 				'bo' => 'tibetagiella',
 				'br' => 'bretonagiella',
 				'bs' => 'bosniagiella',
 				'ca' => 'katalánagiella',
 				'chm' => 'marigiella',
 				'co' => 'corsicagiella',
 				'cs' => 'čeahkagiella',
 				'cy' => 'kymragiella',
 				'da' => 'dánskkagiella',
 				'de' => 'duiskkagiella',
 				'dv' => 'divehigiella',
 				'dz' => 'dzongkhagiella',
 				'el' => 'greikkagiella',
 				'en' => 'eaŋgalsgiella',
 				'es' => 'spánskkagiella',
 				'et' => 'esttegiella',
 				'fa' => 'persijagiella',
 				'fi' => 'suomagiella',
 				'fil' => 'filippiinnagiella',
 				'fj' => 'fidjigiella',
 				'fo' => 'fearagiella',
 				'fr' => 'fránskkagiella',
 				'fy' => 'oarjifriisagiella',
 				'ga' => 'iirragiella',
 				'gu' => 'gujaratagiella',
 				'gv' => 'manksgiella',
 				'ha' => 'haussagiella',
 				'haw' => 'hawaiigiella',
 				'hi' => 'hindigiella',
 				'hr' => 'kroátiagiella',
 				'ht' => 'haitigiella',
 				'hu' => 'ungárgiella',
 				'hy' => 'armeenagiella',
 				'id' => 'indonesiagiella',
 				'is' => 'islánddagiella',
 				'it' => 'itáliagiella',
 				'ja' => 'japánagiella',
 				'jv' => 'javagiella',
 				'ka' => 'georgiagiella',
 				'kk' => 'kazakgiella',
 				'km' => 'kambodiagiella',
 				'ko' => 'koreagiella',
 				'krl' => 'gárjilgiella',
 				'ku' => 'kurdigiella',
 				'kv' => 'komigiella',
 				'kw' => 'kornagiella',
 				'la' => 'láhtengiella',
 				'lb' => 'luxemburggagiella',
 				'lo' => 'laogiella',
 				'lt' => 'liettuvagiella',
 				'lv' => 'látviagiella',
 				'mdf' => 'mokšagiella',
 				'mi' => 'maorigiella',
 				'mk' => 'makedoniagiella',
 				'mn' => 'mongoliagiella',
 				'mt' => 'maltagiella',
 				'my' => 'burmagiella',
 				'myv' => 'ersagiella',
 				'nb' => 'girjedárogiella',
 				'ne' => 'nepaligiella',
 				'nl' => 'hollánddagiella',
 				'nn' => 'ođđadárogiella',
 				'no' => 'dárogiella',
 				'oc' => 'oksitánagiella',
 				'pa' => 'panjabigiella',
 				'pl' => 'polskkagiella',
 				'pt' => 'portugálagiella',
 				'rm' => 'romanšgiella',
 				'ro' => 'romániagiella',
 				'ru' => 'ruoššagiella',
 				'sc' => 'sardigiella',
 				'scn' => 'sisiliagiella',
 				'se' => 'davvisámegiella',
 				'sel' => 'selkupagiella',
 				'sh' => 'serbokroatiagiella',
 				'sk' => 'slovákiagiella',
 				'sl' => 'slovenagiella',
 				'sm' => 'samoagiella',
 				'sma' => 'lullisámegiella',
 				'smj' => 'julevsámegiella',
 				'smn' => 'anárašgiella',
 				'sms' => 'nuortalašgiella',
 				'sq' => 'albánagiella',
 				'sr' => 'serbiagiella',
 				'sv' => 'ruoŧagiella',
 				'swb' => 'shimaorigiella',
 				'th' => 'ŧaigiella',
 				'tr' => 'durkagiella',
 				'ty' => 'tahitigiella',
 				'udm' => 'udmurtagiella',
 				'uk' => 'ukrainagiella',
 				'und' => 'dovdameahttun giella',
 				'ur' => 'urdugiella',
 				'vi' => 'vietnamgiella',
 				'wa' => 'vallonagiella',
 				'yue' => 'kantongiella',
 				'zh' => 'kiinnágiella',
 				'zh_Hans' => 'álki kiinágiella',
 				'zh_Hant' => 'árbevirolaš kiinnágiella',

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
			'Arab' => 'arába',
 			'Cyrl' => 'kyrillalaš',
 			'Grek' => 'greikkalaš',
 			'Hang' => 'hangul',
 			'Hani' => 'kiinnaš',
 			'Hans' => 'álki',
 			'Hant' => 'árbevirolaš',
 			'Hira' => 'hiragana',
 			'Kana' => 'katakana',
 			'Latn' => 'láhtenaš',
 			'Zxxx' => 'orrut chállojuvvot',
 			'Zzzz' => 'dovdameahttun chállin',

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
			'001' => 'máilbmi',
 			'002' => 'Afrihkká',
 			'003' => 'dávvi-Amerihkká ja gaska-Amerihkká',
 			'005' => 'mátta-Amerihkká',
 			'009' => 'Oseania',
 			'011' => 'oarji-Afrihkká',
 			'013' => 'gaska-Amerihkká',
 			'014' => 'nuorta-Afrihkká',
 			'015' => 'davvi-Afrihkká',
 			'017' => 'gaska-Afrihkká',
 			'018' => 'mátta-Afrihkká',
 			'019' => 'Amerihkká',
 			'021' => 'dávvi-Amerihkká',
 			'029' => 'Karibia',
 			'030' => 'nuorta-Ásia',
 			'034' => 'mátta-Ásia',
 			'035' => 'mátta-nuorta-Ásia',
 			'039' => 'mátta-Eurohpá',
 			'053' => 'Austrália ja Ođđa-Selánda',
 			'054' => 'Melanesia',
 			'057' => 'Mikronesia guovllus',
 			'061' => 'Polynesia',
 			'142' => 'Ásia',
 			'143' => 'gaska-Ásia',
 			'145' => 'oarji-Ásia',
 			'150' => 'Eurohpá',
 			'151' => 'nuorta-Eurohpá',
 			'154' => 'davvi-Eurohpá',
 			'155' => 'oarji-Eurohpá',
 			'419' => 'lulli-Amerihkká',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Ovttastuvvan Arábaemiráhtat',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua ja Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albánia',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antárktis',
 			'AR' => 'Argentina',
 			'AS' => 'Amerihká Samoa',
 			'AT' => 'Nuortariika',
 			'AU' => 'Austrália',
 			'AW' => 'Aruba',
 			'AX' => 'Ålánda',
 			'AZ' => 'Aserbaižan',
 			'BA' => 'Bosnia-Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgária',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Vuolleeatnamat Karibe',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet-sullot',
 			'BW' => 'Botswana',
 			'BY' => 'Vilges-Ruošša',
 			'BZ' => 'Belize',
 			'CA' => 'Kanáda',
 			'CC' => 'Cocos-sullot',
 			'CD' => 'Kongo-Kinshasa',
 			'CF' => 'Gaska-Afrihká dásseváldi',
 			'CG' => 'Kongo-Brazzaville',
 			'CH' => 'Šveica',
 			'CI' => 'Elfenbenariddu',
 			'CK' => 'Cook-sullot',
 			'CL' => 'Čiile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kiinná',
 			'CO' => 'Kolombia',
 			'CP' => 'Clipperton-sullot',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Juovllat-sullot',
 			'CY' => 'Kypros',
 			'CZ' => 'Čeahkka',
 			'DE' => 'Duiska',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Dánmárku',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikána dásseváldi',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta ja Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estlánda',
 			'EG' => 'Egypta',
 			'EH' => 'Oarje-Sahára',
 			'ER' => 'Eritrea',
 			'ES' => 'Spánia',
 			'ET' => 'Etiopia',
 			'EU' => 'Eurohpa Uniovdna',
 			'FI' => 'Suopma',
 			'FJ' => 'Fijisullot',
 			'FK' => 'Falklandsullot',
 			'FM' => 'Mikronesia',
 			'FO' => 'Fearsullot',
 			'FR' => 'Frankriika',
 			'GA' => 'Gabon',
 			'GB' => 'Stuorra-Británnia',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Frankriikka Guayana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Kalaallit Nunaat',
 			'GM' => 'Gámbia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekvatoriála Guinea',
 			'GR' => 'Greika',
 			'GS' => 'Lulli Georgia ja Lulli Sandwich-sullot',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong',
 			'HM' => 'Heard- ja McDonald-sullot',
 			'HN' => 'Honduras',
 			'HR' => 'Kroátia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungár',
 			'IC' => 'Kanáriasullot',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlánda',
 			'IL' => 'Israel',
 			'IM' => 'Mann-sullot',
 			'IN' => 'India',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islánda',
 			'IT' => 'Itália',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordánia',
 			'JP' => 'Japána',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgisistan',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoros',
 			'KN' => 'Saint Kitts ja Nevis',
 			'KP' => 'Davvi-Korea',
 			'KR' => 'Mátta-Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Cayman-sullot',
 			'KZ' => 'Kasakstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lietuva',
 			'LU' => 'Luxembourg',
 			'LV' => 'Látvia',
 			'LY' => 'Libya',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldávia',
 			'ME' => 'Montenegro',
 			'MF' => 'Frankriikka Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallsullot',
 			'ML' => 'Mali',
 			'MM' => 'Burma',
 			'MN' => 'Mongolia',
 			'MO' => 'Makáo',
 			'MP' => 'Davvi-Mariánat',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretánia',
 			'MS' => 'Montserrat',
 			'MT' => 'Málta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediivvat',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malesia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Ođđa-Kaledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolksullot',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Vuolleeatnamat',
 			'NO' => 'Norga',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Ođđa-Selánda',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Frankriikka Polynesia',
 			'PG' => 'Papua-Ođđa-Guinea',
 			'PH' => 'Filippiinnat',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Saint Pierre ja Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestina',
 			'PT' => 'Portugála',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'RE' => 'Réunion',
 			'RO' => 'Románia',
 			'RS' => 'Serbia',
 			'RU' => 'Ruošša',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi-Arábia',
 			'SB' => 'Salomon-sullot',
 			'SC' => 'Seychellsullot',
 			'SD' => 'Davvisudan',
 			'SE' => 'Ruoŧŧa',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbárda ja Jan Mayen',
 			'SK' => 'Slovákia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somália',
 			'SR' => 'Surinam',
 			'SS' => 'Máttasudan',
 			'ST' => 'São Tomé ja Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Vuolleeatnamat Saint Martin',
 			'SY' => 'Syria',
 			'SZ' => 'Svazieana',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks ja Caicos-sullot',
 			'TD' => 'Tčad',
 			'TG' => 'Togo',
 			'TH' => 'Thaieana',
 			'TJ' => 'Tažikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Nuorta-Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Durka',
 			'TT' => 'Trinidad ja Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzánia',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'US' => 'Amerihká ovttastuvvan stáhtat',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikána',
 			'VC' => 'Saint Vincent ja Grenadine',
 			'VE' => 'Venezuela',
 			'VG' => 'Brittania Virgin-sullot',
 			'VI' => 'AOS Virgin-sullot',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis ja Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Mátta-Afrihká',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'dovdameahttun guovlu',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'FONIPA' => 'IPA',
 			'FONUPA' => 'UPA',
 			'FONXSAMP' => 'X-SAMPA',
 			'HEPBURN' => 'Hepburn',
 			'PINYIN' => 'pinyin',
 			'WADEGILE' => 'Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kaleandar',
 			'collation' => 'ortnet',
 			'currency' => 'valuhtta',
 			'numbers' => 'numerála',

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
 				'buddhist' => q{buddhista kaleander},
 				'chinese' => q{kiinna},
 				'gregorian' => q{gregoria kaleander},
 			},
 			'collation' => {
 				'pinyin' => q{pinyin ortnet},
 				'traditional' => q{árbevirolaš ortnet},
 			},
 			'numbers' => {
 				'fullwide' => q{viddis oarjelohkosátni},
 				'latn' => q{oarjelohkosátni},
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
			'metric' => q{SI állan},
 			'UK' => q{SB állan},
 			'US' => q{AOS állan},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'giella: {0}',
 			'script' => 'chállin: {0}',
 			'region' => 'guovlu: {0}',

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
			auxiliary => qr{[à ç éè í ńñ óò q ú w x yü ø æ å äã ö]},
			index => ['A', 'Á', 'B', 'C', 'Č', 'D', 'Đ', 'EÉ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'Ŧ', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž', 'Ø', 'Æ', 'Å', 'Ä', 'Ö'],
			main => qr{[a á b c č d đ e f g h i j k l m n ŋ o p r s š t ŧ u v z ž]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Á', 'B', 'C', 'Č', 'D', 'Đ', 'EÉ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'Ŧ', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž', 'Ø', 'Æ', 'Å', 'Ä', 'Ö'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} Maapallo gravitaatiovoima),
						'other' => q({0} Maapallo gravitaatiovoimat),
						'two' => q({0} Maapallo gravitaatiovoimat),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} Maapallo gravitaatiovoima),
						'other' => q({0} Maapallo gravitaatiovoimat),
						'two' => q({0} Maapallo gravitaatiovoimat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} jorbbas minuhta),
						'other' => q({0} jorbbas minuhtta),
						'two' => q({0} jorbbas minuhtta),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} jorbbas minuhta),
						'other' => q({0} jorbbas minuhtta),
						'two' => q({0} jorbbas minuhtta),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} jorbbas sekunda),
						'other' => q({0} jorbbas sekundda),
						'two' => q({0} jorbbas sekundda),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} jorbbas sekunda),
						'other' => q({0} jorbbas sekundda),
						'two' => q({0} jorbbas sekundda),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} grádat),
						'other' => q({0} grádat),
						'two' => q({0} grádat),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} grádat),
						'other' => q({0} grádat),
						'two' => q({0} grádat),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} Amerihká tynnyrinala),
						'other' => q({0} Amerihká tynnyrinala),
						'two' => q({0} Amerihká tynnyrinala),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} Amerihká tynnyrinala),
						'other' => q({0} Amerihká tynnyrinala),
						'two' => q({0} Amerihká tynnyrinala),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} hehtaari),
						'other' => q({0} hehtaaria),
						'two' => q({0} hehtaaria),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} hehtaari),
						'other' => q({0} hehtaaria),
						'two' => q({0} hehtaaria),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} neliöjuolgi),
						'other' => q({0} neliöjuolgi),
						'two' => q({0} neliöjuolgi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} neliöjuolgi),
						'other' => q({0} neliöjuolgi),
						'two' => q({0} neliöjuolgi),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} neliökilomehter),
						'other' => q({0} neliökilomehtera),
						'two' => q({0} neliökilomehtera),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} neliökilomehter),
						'other' => q({0} neliökilomehtera),
						'two' => q({0} neliökilomehtera),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} neliömehter),
						'other' => q({0} neliömehtera),
						'two' => q({0} neliömehtera),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} neliömehter),
						'other' => q({0} neliömehtera),
						'two' => q({0} neliömehtera),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} eangas neliömiil),
						'other' => q({0} eangas neliömiila),
						'two' => q({0} eangas neliömiila),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} eangas neliömiil),
						'other' => q({0} eangas neliömiila),
						'two' => q({0} eangas neliömiila),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} nuorti),
						'north' => q({0} davvi),
						'south' => q({0} lulli),
						'west' => q({0} oarji),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} nuorti),
						'north' => q({0} davvi),
						'south' => q({0} lulli),
						'west' => q({0} oarji),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} jándor),
						'other' => q({0} jándora),
						'per' => q({0} juohke jándor),
						'two' => q({0} jándora),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} jándor),
						'other' => q({0} jándora),
						'per' => q({0} juohke jándor),
						'two' => q({0} jándora),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} diibmu),
						'other' => q({0} diibmur),
						'per' => q({0} juohke diibmu),
						'two' => q({0} diimmur),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} diibmu),
						'other' => q({0} diibmur),
						'per' => q({0} juohke diibmu),
						'two' => q({0} diimmur),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekundda),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundda),
						'two' => q({0} mikrosekundda),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekundda),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundda),
						'two' => q({0} mikrosekundda),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} millisekunda),
						'other' => q({0} millisekundda),
						'two' => q({0} millisekundda),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} millisekunda),
						'other' => q({0} millisekundda),
						'two' => q({0} millisekundda),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} minuhta),
						'other' => q({0} minuhtta),
						'per' => q({0} juohke minuhta),
						'two' => q({0} minuhtta),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} minuhta),
						'other' => q({0} minuhtta),
						'per' => q({0} juohke minuhta),
						'two' => q({0} minuhtta),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} mánotbadji),
						'other' => q({0} mánotbadji),
						'per' => q({0} juohke mánotbadji),
						'two' => q({0} mánotbaji),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} mánotbadji),
						'other' => q({0} mánotbadji),
						'per' => q({0} juohke mánotbadji),
						'two' => q({0} mánotbaji),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekundda),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundda),
						'two' => q({0} nanosekundda),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekundda),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundda),
						'two' => q({0} nanosekundda),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} sekunda),
						'other' => q({0} sekundda),
						'per' => q({0} juohke sekunda),
						'two' => q({0} sekundda),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} sekunda),
						'other' => q({0} sekundda),
						'per' => q({0} juohke sekunda),
						'two' => q({0} sekundda),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} váhku),
						'other' => q({0} váhkku),
						'per' => q({0} juohke váhku),
						'two' => q({0} váhkku),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} váhku),
						'other' => q({0} váhkku),
						'per' => q({0} juohke váhku),
						'two' => q({0} váhkku),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} jahki),
						'other' => q({0} jahkki),
						'per' => q({0} juohke jahki),
						'two' => q({0} jahkki),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} jahki),
						'other' => q({0} jahkki),
						'per' => q({0} juohke jahki),
						'two' => q({0} jahkki),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0} sentimehter),
						'other' => q({0} sentimehtera),
						'per' => q({0} juohke sentimehter),
						'two' => q({0} sentimehtera),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0} sentimehter),
						'other' => q({0} sentimehtera),
						'per' => q({0} juohke sentimehter),
						'two' => q({0} sentimehtera),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimehtera),
						'one' => q({0} desimehter),
						'other' => q({0} desimehtera),
						'two' => q({0} desimehtera),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimehtera),
						'one' => q({0} desimehter),
						'other' => q({0} desimehtera),
						'two' => q({0} desimehtera),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0} juohke juolgi),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0} juohke juolgi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q({0} juohke bealgi),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0} juohke bealgi),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0} kilomehter),
						'other' => q({0} kilomehtera),
						'per' => q({0} juohke kilomehter),
						'two' => q({0} kilomehtera),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0} kilomehter),
						'other' => q({0} kilomehtera),
						'per' => q({0} juohke kilomehter),
						'two' => q({0} kilomehtera),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} chuovgat jagi),
						'other' => q({0} chuovgat jagi),
						'two' => q({0} chuovgat jagi),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} chuovgat jagi),
						'other' => q({0} chuovgat jagi),
						'two' => q({0} chuovgat jagi),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} mehter),
						'other' => q({0} mehtera),
						'per' => q({0} juohke mehter),
						'two' => q({0} mehtera),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} mehter),
						'other' => q({0} mehtera),
						'per' => q({0} juohke mehter),
						'two' => q({0} mehtera),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikromehtera),
						'one' => q({0} mikromehter),
						'other' => q({0} mikromehtera),
						'two' => q({0} mikromehtera),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikromehtera),
						'one' => q({0} mikromehter),
						'other' => q({0} mikromehtera),
						'two' => q({0} mikromehtera),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} eangas miil),
						'other' => q({0} eangas miila),
						'two' => q({0} eangas miila),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} eangas miil),
						'other' => q({0} eangas miila),
						'two' => q({0} eangas miila),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0} millimehter),
						'other' => q({0} millimehtera),
						'two' => q({0} millimehtera),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0} millimehter),
						'other' => q({0} millimehtera),
						'two' => q({0} millimehtera),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomehtera),
						'one' => q({0} nanomehter),
						'other' => q({0} nanomehtera),
						'two' => q({0} nanomehtera),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomehtera),
						'one' => q({0} nanomehter),
						'other' => q({0} nanomehtera),
						'two' => q({0} nanomehtera),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pikomehter),
						'other' => q({0} pikomehtera),
						'two' => q({0} pikomehtera),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pikomehter),
						'other' => q({0} pikomehtera),
						'two' => q({0} pikomehtera),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} eangas yard),
						'other' => q({0} eangas yard),
						'two' => q({0} eangas yard),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} eangas yard),
						'other' => q({0} eangas yard),
						'two' => q({0} eangas yard),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} juohke gram),
						'two' => q({0} gram),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} juohke gram),
						'two' => q({0} gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} juohke kilogram),
						'two' => q({0} kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} juohke kilogram),
						'two' => q({0} kilogram),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} eangas tonna à 907kg),
						'other' => q({0} eangas tonna à 907kg),
						'two' => q({0} eangas tonna à 907kg),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} eangas tonna à 907kg),
						'other' => q({0} eangas tonna à 907kg),
						'two' => q({0} eangas tonna à 907kg),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0} tonna),
						'other' => q({0} tonna),
						'two' => q({0} tonna),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0} tonna),
						'other' => q({0} tonna),
						'two' => q({0} tonna),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} juohke {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} juohke {1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} hevosvoima),
						'other' => q({0} hevosvoima),
						'two' => q({0} hevosvoima),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} hevosvoima),
						'other' => q({0} hevosvoima),
						'two' => q({0} hevosvoima),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
						'two' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
						'two' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} watt),
						'other' => q({0} watt),
						'two' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} watt),
						'other' => q({0} watt),
						'two' => q({0} watt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0} hehtopascal),
						'other' => q({0} hehtopascal),
						'two' => q({0} hehtopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hehtopascal),
						'other' => q({0} hehtopascal),
						'two' => q({0} hehtopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} bealgi kvikksølv),
						'other' => q({0} bealgi kvikksølv),
						'two' => q({0} bealgi kvikksølv),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} bealgi kvikksølv),
						'other' => q({0} bealgi kvikksølv),
						'two' => q({0} bealgi kvikksølv),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} millibar),
						'other' => q({0} millibar),
						'two' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} millibar),
						'other' => q({0} millibar),
						'two' => q({0} millibar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0} kilomehter kohti diibmu),
						'other' => q({0} kilomehtera kohti diibmu),
						'two' => q({0} kilomehtera kohti diibmu),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} kilomehter kohti diibmu),
						'other' => q({0} kilomehtera kohti diibmu),
						'two' => q({0} kilomehtera kohti diibmu),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} mehter kohti sekunti),
						'other' => q({0} mehtera kohti sekunti),
						'two' => q({0} mehtera kohti sekunti),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} mehter kohti sekunti),
						'other' => q({0} mehtera kohti sekunti),
						'two' => q({0} mehtera kohti sekunti),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} eangas miil kohti diibmu),
						'other' => q({0} eangas miila kohti diibmu),
						'two' => q({0} eangas miila kohti diibmu),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} eangas miil kohti diibmu),
						'other' => q({0} eangas miila kohti diibmu),
						'two' => q({0} eangas miila kohti diibmu),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} grádat Celsius),
						'other' => q({0} grádat Celsius),
						'two' => q({0} grádat Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} grádat Celsius),
						'other' => q({0} grádat Celsius),
						'two' => q({0} grádat Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} grádat Fahrenheit),
						'other' => q({0} grádat Fahrenheit),
						'two' => q({0} grádat Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} grádat Fahrenheit),
						'other' => q({0} grádat Fahrenheit),
						'two' => q({0} grádat Fahrenheit),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} kubikkilomehter),
						'other' => q({0} kubikkilomehtera),
						'two' => q({0} kubikkilomehtera),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} kubikkilomehter),
						'other' => q({0} kubikkilomehtera),
						'two' => q({0} kubikkilomehtera),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} eangas kubikkmiil),
						'other' => q({0} eangas kubikkmiila),
						'two' => q({0} eangas kubikkmiila),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} eangas kubikkmiil),
						'other' => q({0} eangas kubikkmiila),
						'two' => q({0} eangas kubikkmiila),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} lihtar),
						'other' => q({0} lihtara),
						'per' => q({0} juohke lithar),
						'two' => q({0} lihtara),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} lihtar),
						'other' => q({0} lihtara),
						'per' => q({0} juohke lithar),
						'two' => q({0} lihtara),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
						'two' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
						'two' => q({0}m/s²),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'two' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'two' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'two' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'two' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'two' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'two' => q({0}m²),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}N),
						'north' => q({0}D),
						'south' => q({0}L),
						'west' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}N),
						'north' => q({0}D),
						'south' => q({0}L),
						'west' => q({0}O),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}d),
						'other' => q({0}d),
						'two' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}d),
						'other' => q({0}d),
						'two' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
						'two' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
						'two' => q({0}h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
						'two' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
						'two' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0}v),
						'other' => q({0}v),
						'two' => q({0}v),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0}v),
						'other' => q({0}v),
						'two' => q({0}v),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}j),
						'other' => q({0}j),
						'two' => q({0}j),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}j),
						'other' => q({0}j),
						'two' => q({0}j),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0} nm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
						'two' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
						'two' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(eangas tonna),
						'one' => q({0} e.ton.),
						'other' => q({0} e.ton.),
						'two' => q({0} e.ton.),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(eangas tonna),
						'one' => q({0} e.ton.),
						'other' => q({0} e.ton.),
						'two' => q({0} e.ton.),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}hv),
						'other' => q({0}hv),
						'two' => q({0}hv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}hv),
						'other' => q({0}hv),
						'two' => q({0}hv),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'two' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'two' => q({0}mbar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q({0}cL),
						'other' => q({0}cL),
						'two' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0}cL),
						'other' => q({0}cL),
						'two' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q({0}dL),
						'other' => q({0}dL),
						'two' => q({0}dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0}dL),
						'other' => q({0}dL),
						'two' => q({0}dL),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0}hL),
						'other' => q({0}hL),
						'two' => q({0}hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0}hL),
						'other' => q({0}hL),
						'two' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'two' => q({0}L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'two' => q({0}L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0}ML),
						'other' => q({0}ML),
						'two' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0}ML),
						'other' => q({0}ML),
						'two' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0}mL),
						'other' => q({0}mL),
						'two' => q({0}mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}mL),
						'other' => q({0}mL),
						'two' => q({0}mL),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(Maapallo gravitaatiovoimat),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(Maapallo gravitaatiovoimat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(jorbbas minuhtta),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(jorbbas minuhtta),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(jorbbas sekundda),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(jorbbas sekundda),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grádat),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grádat),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(Amerihká tynnyrinala),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(Amerihká tynnyrinala),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hehtaaria),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hehtaaria),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(neliöjuolgi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(neliöjuolgi),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(neliökilomehtera),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(neliökilomehtera),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(neliömehtera),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(neliömehtera),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(eangas neliömiila),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(eangas neliömiila),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} N),
						'north' => q({0} D),
						'south' => q({0} L),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} N),
						'north' => q({0} D),
						'south' => q({0} L),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(jándora),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(jándora),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(diibmur),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(diibmur),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekundda),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekundda),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuhtta),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuhtta),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mánotbadji),
						'one' => q({0} mán),
						'other' => q({0} mán),
						'per' => q({0}/mán),
						'two' => q({0} mán),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mánotbadji),
						'one' => q({0} mán),
						'other' => q({0} mán),
						'per' => q({0}/mán),
						'two' => q({0} mán),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekundda),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekundda),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(váhkku),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
						'two' => q({0} v),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(váhkku),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
						'two' => q({0} v),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(jahkki),
						'one' => q({0} jah),
						'other' => q({0} jah),
						'per' => q({0}/jah),
						'two' => q({0} jah),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(jahkki),
						'one' => q({0} jah),
						'other' => q({0} jah),
						'per' => q({0}/jah),
						'two' => q({0} jah),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimehtera),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimehtera),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(juolgi),
						'one' => q({0} juolgi),
						'other' => q({0} juolgi),
						'per' => q({0}/juolgi),
						'two' => q({0} juolgi),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(juolgi),
						'one' => q({0} juolgi),
						'other' => q({0} juolgi),
						'per' => q({0}/juolgi),
						'two' => q({0} juolgi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(bealgi),
						'one' => q({0} bealgi),
						'other' => q({0} bealgi),
						'per' => q({0}/bealgi),
						'two' => q({0} bealgi),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(bealgi),
						'one' => q({0} bealgi),
						'other' => q({0} bealgi),
						'per' => q({0}/bealgi),
						'two' => q({0} bealgi),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomehtera),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomehtera),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(chuovgat jagi),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(chuovgat jagi),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mehtera),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mehtera),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(eangas miila),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(eangas miila),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(miila),
						'one' => q({0} miil),
						'other' => q({0} miila),
						'two' => q({0} miila),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(miila),
						'one' => q({0} miil),
						'other' => q({0} miila),
						'two' => q({0} miila),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimehtera),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimehtera),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikomehtera),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikomehtera),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(eangas yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(eangas yard),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unssi),
						'one' => q({0} unssi),
						'other' => q({0} unssi),
						'two' => q({0} unssi),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unssi),
						'one' => q({0} unssi),
						'other' => q({0} unssi),
						'two' => q({0} unssi),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pauna),
						'one' => q({0} pauna),
						'other' => q({0} pauna),
						'two' => q({0} pauna),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pauna),
						'one' => q({0} pauna),
						'other' => q({0} pauna),
						'two' => q({0} pauna),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(eangas tonna à 907kg),
						'one' => q({0} eang.ton. à 907kg),
						'other' => q({0} eang.ton. à 907kg),
						'two' => q({0} eang.ton. à 907kg),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(eangas tonna à 907kg),
						'one' => q({0} eang.ton. à 907kg),
						'other' => q({0} eang.ton. à 907kg),
						'two' => q({0} eang.ton. à 907kg),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonna),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonna),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hevosvoima),
						'one' => q({0} hv),
						'other' => q({0} hv),
						'two' => q({0} hv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hevosvoima),
						'one' => q({0} hv),
						'other' => q({0} hv),
						'two' => q({0} hv),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hehtopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hehtopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(bealgi kvikksølv),
						'one' => q({0} bealgi Hg),
						'other' => q({0} bealgi Hg),
						'two' => q({0} bealgi Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(bealgi kvikksølv),
						'one' => q({0} bealgi Hg),
						'other' => q({0} bealgi Hg),
						'two' => q({0} bealgi Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilomehtera kohti diibmu),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilomehtera kohti diibmu),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mehtera kohti sekunti),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mehtera kohti sekunti),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(eangas miila kohti diibmu),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(eangas miila kohti diibmu),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(grádat Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(grádat Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(grádat Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(grádat Fahrenheit),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kubikkilomehtera),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kubikkilomehtera),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(eangas kubikkmiila),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(eangas kubikkmiila),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lihtara),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lihtara),
						'per' => q({0}/L),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jo|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ii|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} ja {1}),
				2 => q({0} ja {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(·10^),
			'group' => q( ),
			'minusSign' => q(−),
			'superscriptingExponent' => q(·),
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
					'one' => '0 duhát',
					'other' => '0 duháhat',
					'two' => '0 duháhat',
				},
				'10000' => {
					'one' => '00 duhát',
					'other' => '00 duháhat',
					'two' => '00 duháhat',
				},
				'100000' => {
					'one' => '000 duhát',
					'other' => '000 duháhat',
					'two' => '000 duháhat',
				},
				'1000000' => {
					'one' => '0 miljona',
					'other' => '0 miljonat',
					'two' => '0 miljonat',
				},
				'10000000' => {
					'one' => '00 miljona',
					'other' => '00 miljonat',
					'two' => '00 miljonat',
				},
				'100000000' => {
					'one' => '000 miljona',
					'other' => '000 miljonat',
					'two' => '000 miljonat',
				},
				'1000000000' => {
					'one' => '0 miljardi',
					'other' => '0 miljardit',
					'two' => '0 miljardit',
				},
				'10000000000' => {
					'one' => '00 miljardi',
					'other' => '00 miljardit',
					'two' => '00 miljardit',
				},
				'100000000000' => {
					'one' => '000 miljardi',
					'other' => '000 miljardit',
					'two' => '000 miljardit',
				},
				'1000000000000' => {
					'one' => '0 biljona',
					'other' => '0 biljonat',
					'two' => '0 biljonat',
				},
				'10000000000000' => {
					'one' => '00 biljona',
					'other' => '00 biljonat',
					'two' => '00 biljonat',
				},
				'100000000000000' => {
					'one' => '000 biljona',
					'other' => '000 biljonat',
					'two' => '000 biljonat',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 dt',
					'other' => '0 dt',
				},
				'10000' => {
					'one' => '00 dt',
					'other' => '00 dt',
				},
				'100000' => {
					'one' => '000 dt',
					'other' => '000 dt',
				},
				'1000000' => {
					'one' => '0 mn',
					'other' => '0 mn',
				},
				'10000000' => {
					'one' => '00 mn',
					'other' => '00 mn',
				},
				'100000000' => {
					'one' => '000 mn',
					'other' => '000 mn',
				},
				'1000000000' => {
					'one' => '0 md',
					'other' => '0 md',
				},
				'10000000000' => {
					'one' => '00 md',
					'other' => '00 md',
				},
				'100000000000' => {
					'one' => '000 md',
					'other' => '000 md',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
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
		'DKK' => {
			symbol => 'Dkr',
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(suoma márkki),
			},
		},
		'GBP' => {
			symbol => 'GB£',
		},
		'ISK' => {
			symbol => 'Ikr',
		},
		'NOK' => {
			symbol => 'kr',
			display_name => {
				'currency' => q(norgga kruvdno),
			},
		},
		'SEK' => {
			symbol => 'Skr',
			display_name => {
				'currency' => q(ruoŧŧa kruvdno),
			},
		},
		'THB' => {
			symbol => '฿',
		},
		'XAG' => {
			display_name => {
				'currency' => q(uns silba),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(uns golli),
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
							'ođđj',
							'guov',
							'njuk',
							'cuo',
							'mies',
							'geas',
							'suoi',
							'borg',
							'čakč',
							'golg',
							'skáb',
							'juov'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ođđajagemánnu',
							'guovvamánnu',
							'njukčamánnu',
							'cuoŋománnu',
							'miessemánnu',
							'geassemánnu',
							'suoidnemánnu',
							'borgemánnu',
							'čakčamánnu',
							'golggotmánnu',
							'skábmamánnu',
							'juovlamánnu'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'O',
							'G',
							'N',
							'C',
							'M',
							'G',
							'S',
							'B',
							'Č',
							'G',
							'S',
							'J'
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
						mon => 'vuos',
						tue => 'maŋ',
						wed => 'gask',
						thu => 'duor',
						fri => 'bear',
						sat => 'láv',
						sun => 'sotn'
					},
					wide => {
						mon => 'vuossárga',
						tue => 'maŋŋebárga',
						wed => 'gaskavahkku',
						thu => 'duorasdat',
						fri => 'bearjadat',
						sat => 'lávvardat',
						sun => 'sotnabeaivi'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'V',
						tue => 'M',
						wed => 'G',
						thu => 'D',
						fri => 'B',
						sat => 'L',
						sun => 'S'
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
					'am' => q{i.b.},
					'pm' => q{e.b.},
				},
				'wide' => {
					'am' => q{iđitbeaivet},
					'pm' => q{eahketbeaivet},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{iđitbeaivi},
					'pm' => q{eahketbeaivi},
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
				'0' => 'o.Kr.',
				'1' => 'm.Kr.'
			},
			wide => {
				'0' => 'ovdal Kristtusa',
				'1' => 'maŋŋel Kristtusa'
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
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
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
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
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
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;−HH:mm),
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q({0} áigi),
		regionFormat => q({0} geassiáigi),
		regionFormat => q({0} dábálašáigi),
		fallbackFormat => q({0} ({1})),
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthélemy#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#dovdameahttun áigeavádat#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#gaska-Eurohpá geassiáigi#,
				'generic' => q#gaska-Eurohpá áigi#,
				'standard' => q#gaska-Eurohpá dábálašáigi#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#nuorti-Eurohpá geassiáigi#,
				'generic' => q#nuorti-Eurohpá áigi#,
				'standard' => q#nuorti-Eurohpá dábálašáigi#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#oarje-Eurohpá geassiáigi#,
				'generic' => q#oarje-Eurohpá áigi#,
				'standard' => q#oarje-Eurohpá dábálašáigi#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich gaskka áigi#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva-geassiáigi#,
				'generic' => q#Moskva-áigi#,
				'standard' => q#Moskva-dábálašáigi#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
