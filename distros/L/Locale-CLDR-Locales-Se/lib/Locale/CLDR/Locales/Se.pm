=encoding utf8

=head1

Locale::CLDR::Locales::Se - Package for language Northern Sami

=cut

package Locale::CLDR::Locales::Se;
# This file auto generated from Data\common\main\se.xml
#	on Sun  7 Oct 10:57:12 am GMT

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
		use bignum;
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
 			'GB@alt=short' => 'Stuorra-Británnia',
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
 			'HK@alt=short' => 'Hongkong',
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
 			'MK' => 'Makedonia',
 			'ML' => 'Mali',
 			'MM' => 'Burma',
 			'MN' => 'Mongolia',
 			'MO' => 'Makáo',
 			'MO@alt=short' => 'Makáo',
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
 			'PS@alt=short' => 'Palestina',
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
			auxiliary => qr{[à ç é è í ń ñ ó ò q ú w x y ü ø æ å ä ã ö]},
			index => ['A', 'Á', 'B', 'C', 'Č', 'D', 'Đ', 'E', 'É', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'Ŧ', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž', 'Ø', 'Æ', 'Å', 'Ä', 'Ö'],
			main => qr{[a á b c č d đ e f g h i j k l m n ŋ o p r s š t ŧ u v z ž]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Á', 'B', 'C', 'Č', 'D', 'Đ', 'E', 'É', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'Ŧ', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž', 'Ø', 'Æ', 'Å', 'Ä', 'Ö'], };
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
	default		=> qq{”},
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
	default		=> qq{’},
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
						'name' => q(Amerihká tynnyrinala),
						'one' => q({0} Amerihká tynnyrinala),
						'other' => q({0} Amerihká tynnyrinala),
						'two' => q({0} Amerihká tynnyrinala),
					},
					'arc-minute' => {
						'name' => q(jorbbas minuhtta),
						'one' => q({0} jorbbas minuhta),
						'other' => q({0} jorbbas minuhtta),
						'two' => q({0} jorbbas minuhtta),
					},
					'arc-second' => {
						'name' => q(jorbbas sekundda),
						'one' => q({0} jorbbas sekunda),
						'other' => q({0} jorbbas sekundda),
						'two' => q({0} jorbbas sekundda),
					},
					'celsius' => {
						'name' => q(grádat Celsius),
						'one' => q({0} grádat Celsius),
						'other' => q({0} grádat Celsius),
						'two' => q({0} grádat Celsius),
					},
					'centimeter' => {
						'name' => q(sentimehtera),
						'one' => q({0} sentimehter),
						'other' => q({0} sentimehtera),
						'per' => q({0} juohke sentimehter),
						'two' => q({0} sentimehtera),
					},
					'coordinate' => {
						'east' => q({0} nuorti),
						'north' => q({0} davvi),
						'south' => q({0} lulli),
						'west' => q({0} oarji),
					},
					'cubic-kilometer' => {
						'name' => q(kubikkilomehtera),
						'one' => q({0} kubikkilomehter),
						'other' => q({0} kubikkilomehtera),
						'two' => q({0} kubikkilomehtera),
					},
					'cubic-mile' => {
						'name' => q(eangas kubikkmiila),
						'one' => q({0} eangas kubikkmiil),
						'other' => q({0} eangas kubikkmiila),
						'two' => q({0} eangas kubikkmiila),
					},
					'day' => {
						'name' => q(jándora),
						'one' => q({0} jándor),
						'other' => q({0} jándora),
						'per' => q({0} juohke jándor),
						'two' => q({0} jándora),
					},
					'decimeter' => {
						'name' => q(desimehtera),
						'one' => q({0} desimehter),
						'other' => q({0} desimehtera),
						'two' => q({0} desimehtera),
					},
					'degree' => {
						'name' => q(grádat),
						'one' => q({0} grádat),
						'other' => q({0} grádat),
						'two' => q({0} grádat),
					},
					'fahrenheit' => {
						'name' => q(grádat Fahrenheit),
						'one' => q({0} grádat Fahrenheit),
						'other' => q({0} grádat Fahrenheit),
						'two' => q({0} grádat Fahrenheit),
					},
					'foot' => {
						'name' => q(juolgi),
						'one' => q({0} juolgi),
						'other' => q({0} juolgi),
						'per' => q({0} juohke juolgi),
						'two' => q({0} juolgi),
					},
					'g-force' => {
						'name' => q(Maapallo gravitaatiovoimat),
						'one' => q({0} Maapallo gravitaatiovoima),
						'other' => q({0} Maapallo gravitaatiovoimat),
						'two' => q({0} Maapallo gravitaatiovoimat),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} juohke gram),
						'two' => q({0} gram),
					},
					'hectare' => {
						'name' => q(hehtaaria),
						'one' => q({0} hehtaari),
						'other' => q({0} hehtaaria),
						'two' => q({0} hehtaaria),
					},
					'hectopascal' => {
						'name' => q(hehtopascal),
						'one' => q({0} hehtopascal),
						'other' => q({0} hehtopascal),
						'two' => q({0} hehtopascal),
					},
					'horsepower' => {
						'name' => q(hevosvoima),
						'one' => q({0} hevosvoima),
						'other' => q({0} hevosvoima),
						'two' => q({0} hevosvoima),
					},
					'hour' => {
						'name' => q(diibmur),
						'one' => q({0} diibmu),
						'other' => q({0} diibmur),
						'per' => q({0} juohke diibmu),
						'two' => q({0} diimmur),
					},
					'inch' => {
						'name' => q(bealgi),
						'one' => q({0} bealgi),
						'other' => q({0} bealgi),
						'per' => q({0} juohke bealgi),
						'two' => q({0} bealgi),
					},
					'inch-hg' => {
						'name' => q(bealgi kvikksølv),
						'one' => q({0} bealgi kvikksølv),
						'other' => q({0} bealgi kvikksølv),
						'two' => q({0} bealgi kvikksølv),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} juohke kilogram),
						'two' => q({0} kilogram),
					},
					'kilometer' => {
						'name' => q(kilomehtera),
						'one' => q({0} kilomehter),
						'other' => q({0} kilomehtera),
						'per' => q({0} juohke kilomehter),
						'two' => q({0} kilomehtera),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomehtera kohti diibmu),
						'one' => q({0} kilomehter kohti diibmu),
						'other' => q({0} kilomehtera kohti diibmu),
						'two' => q({0} kilomehtera kohti diibmu),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
						'two' => q({0} kilowatt),
					},
					'light-year' => {
						'name' => q(chuovgat jagi),
						'one' => q({0} chuovgat jagi),
						'other' => q({0} chuovgat jagi),
						'two' => q({0} chuovgat jagi),
					},
					'liter' => {
						'name' => q(lihtara),
						'one' => q({0} lihtar),
						'other' => q({0} lihtara),
						'per' => q({0} juohke lithar),
						'two' => q({0} lihtara),
					},
					'meter' => {
						'name' => q(mehtera),
						'one' => q({0} mehter),
						'other' => q({0} mehtera),
						'per' => q({0} juohke mehter),
						'two' => q({0} mehtera),
					},
					'meter-per-second' => {
						'name' => q(mehtera kohti sekunti),
						'one' => q({0} mehter kohti sekunti),
						'other' => q({0} mehtera kohti sekunti),
						'two' => q({0} mehtera kohti sekunti),
					},
					'metric-ton' => {
						'name' => q(tonna),
						'one' => q({0} tonna),
						'other' => q({0} tonna),
						'two' => q({0} tonna),
					},
					'micrometer' => {
						'name' => q(mikromehtera),
						'one' => q({0} mikromehter),
						'other' => q({0} mikromehtera),
						'two' => q({0} mikromehtera),
					},
					'microsecond' => {
						'name' => q(mikrosekundda),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundda),
						'two' => q({0} mikrosekundda),
					},
					'mile' => {
						'name' => q(eangas miila),
						'one' => q({0} eangas miil),
						'other' => q({0} eangas miila),
						'two' => q({0} eangas miila),
					},
					'mile-per-hour' => {
						'name' => q(eangas miila kohti diibmu),
						'one' => q({0} eangas miil kohti diibmu),
						'other' => q({0} eangas miila kohti diibmu),
						'two' => q({0} eangas miila kohti diibmu),
					},
					'mile-scandinavian' => {
						'name' => q(miila),
						'one' => q({0} miil),
						'other' => q({0} miila),
						'two' => q({0} miila),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
						'two' => q({0} millibar),
					},
					'millimeter' => {
						'name' => q(millimehtera),
						'one' => q({0} millimehter),
						'other' => q({0} millimehtera),
						'two' => q({0} millimehtera),
					},
					'millisecond' => {
						'name' => q(millisekundda),
						'one' => q({0} millisekunda),
						'other' => q({0} millisekundda),
						'two' => q({0} millisekundda),
					},
					'minute' => {
						'name' => q(minuhtta),
						'one' => q({0} minuhta),
						'other' => q({0} minuhtta),
						'per' => q({0} juohke minuhta),
						'two' => q({0} minuhtta),
					},
					'month' => {
						'name' => q(mánotbadji),
						'one' => q({0} mánotbadji),
						'other' => q({0} mánotbadji),
						'per' => q({0} juohke mánotbadji),
						'two' => q({0} mánotbaji),
					},
					'nanometer' => {
						'name' => q(nanomehtera),
						'one' => q({0} nanomehter),
						'other' => q({0} nanomehtera),
						'two' => q({0} nanomehtera),
					},
					'nanosecond' => {
						'name' => q(nanosekundda),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundda),
						'two' => q({0} nanosekundda),
					},
					'ounce' => {
						'name' => q(unssi),
						'one' => q({0} unssi),
						'other' => q({0} unssi),
						'two' => q({0} unssi),
					},
					'per' => {
						'1' => q({0} juohke {1}),
					},
					'picometer' => {
						'name' => q(pikomehtera),
						'one' => q({0} pikomehter),
						'other' => q({0} pikomehtera),
						'two' => q({0} pikomehtera),
					},
					'pound' => {
						'name' => q(pauna),
						'one' => q({0} pauna),
						'other' => q({0} pauna),
						'two' => q({0} pauna),
					},
					'second' => {
						'name' => q(sekundda),
						'one' => q({0} sekunda),
						'other' => q({0} sekundda),
						'per' => q({0} juohke sekunda),
						'two' => q({0} sekundda),
					},
					'square-foot' => {
						'name' => q(neliöjuolgi),
						'one' => q({0} neliöjuolgi),
						'other' => q({0} neliöjuolgi),
						'two' => q({0} neliöjuolgi),
					},
					'square-kilometer' => {
						'name' => q(neliökilomehtera),
						'one' => q({0} neliökilomehter),
						'other' => q({0} neliökilomehtera),
						'two' => q({0} neliökilomehtera),
					},
					'square-meter' => {
						'name' => q(neliömehtera),
						'one' => q({0} neliömehter),
						'other' => q({0} neliömehtera),
						'two' => q({0} neliömehtera),
					},
					'square-mile' => {
						'name' => q(eangas neliömiila),
						'one' => q({0} eangas neliömiil),
						'other' => q({0} eangas neliömiila),
						'two' => q({0} eangas neliömiila),
					},
					'ton' => {
						'name' => q(eangas tonna à 907kg),
						'one' => q({0} eangas tonna à 907kg),
						'other' => q({0} eangas tonna à 907kg),
						'two' => q({0} eangas tonna à 907kg),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
						'two' => q({0} watt),
					},
					'week' => {
						'name' => q(váhkku),
						'one' => q({0} váhku),
						'other' => q({0} váhkku),
						'per' => q({0} juohke váhku),
						'two' => q({0} váhkku),
					},
					'yard' => {
						'name' => q(eangas yard),
						'one' => q({0} eangas yard),
						'other' => q({0} eangas yard),
						'two' => q({0} eangas yard),
					},
					'year' => {
						'name' => q(jahkki),
						'one' => q({0} jahki),
						'other' => q({0} jahkki),
						'per' => q({0} juohke jahki),
						'two' => q({0} jahkki),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					'celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
						'two' => q({0}cL),
					},
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
						'two' => q({0}cm),
					},
					'coordinate' => {
						'east' => q({0}N),
						'north' => q({0}D),
						'south' => q({0}L),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'per' => q({0}/cm³),
						'two' => q({0}cm³),
					},
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					'day' => {
						'one' => q({0}d),
						'other' => q({0}d),
						'per' => q({0}/d),
						'two' => q({0}d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
						'two' => q({0}dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
						'two' => q({0}°F),
					},
					'foot' => {
						'one' => q({0} juolgi),
						'other' => q({0} juolgi),
						'two' => q({0} juolgi),
					},
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					'gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
						'two' => q({0}g),
					},
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
						'two' => q({0}hL),
					},
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					'horsepower' => {
						'one' => q({0}hv),
						'other' => q({0}hv),
						'two' => q({0}hv),
					},
					'hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
						'per' => q({0}/h),
						'two' => q({0}h),
					},
					'inch' => {
						'one' => q({0} bealgi),
						'other' => q({0} bealgi),
						'two' => q({0} bealgi),
					},
					'inch-hg' => {
						'one' => q({0} bealgi Hg),
						'other' => q({0} bealgi Hg),
						'two' => q({0} bealgi Hg),
					},
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
						'two' => q({0}kg),
					},
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
						'per' => q({0}/km),
						'two' => q({0}km),
					},
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
					},
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					'light-year' => {
						'one' => q({0} ly),
						'other' => q({0} ly),
						'two' => q({0} ly),
					},
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
						'two' => q({0}L),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
						'two' => q({0}ML),
					},
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
						'two' => q({0}m),
					},
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
					},
					'meter-per-second-squared' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
						'two' => q({0}m/s²),
					},
					'metric-ton' => {
						'name' => q(tonna),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					'microgram' => {
						'one' => q({0}µg),
						'other' => q({0}µg),
						'two' => q({0}µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0}µm),
						'other' => q({0}µm),
						'two' => q({0}µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
						'two' => q({0} mi/h),
					},
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'two' => q({0}mbar),
					},
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
						'two' => q({0}mL),
					},
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/min),
						'two' => q({0}m),
					},
					'month' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/mán),
						'two' => q({0}m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					'ounce' => {
						'one' => q({0} unssi),
						'other' => q({0} unssi),
						'two' => q({0} unssi),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					'pound' => {
						'one' => q({0} pauna),
						'other' => q({0} pauna),
						'two' => q({0} pauna),
					},
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
						'two' => q({0}s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
						'two' => q({0}cm²),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'per' => q({0}/km²),
						'two' => q({0}km²),
					},
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
						'two' => q({0}m²),
					},
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'two' => q({0} mi²),
					},
					'ton' => {
						'name' => q(eangas tonna),
						'one' => q({0} e.ton.),
						'other' => q({0} e.ton.),
						'two' => q({0} e.ton.),
					},
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					'week' => {
						'one' => q({0}v),
						'other' => q({0}v),
						'per' => q({0}/v),
						'two' => q({0}v),
					},
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					'year' => {
						'one' => q({0}j),
						'other' => q({0}j),
						'per' => q({0}/jah),
						'two' => q({0}j),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(Amerihká tynnyrinala),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					'arc-minute' => {
						'name' => q(jorbbas minuhtta),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					'arc-second' => {
						'name' => q(jorbbas sekundda),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					'celsius' => {
						'name' => q(grádat Celsius),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
						'two' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(sentimehtera),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
						'two' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0} N),
						'north' => q({0} D),
						'south' => q({0} L),
						'west' => q({0} O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
						'two' => q({0} cm³),
					},
					'cubic-kilometer' => {
						'name' => q(kubikkilomehtera),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					'cubic-meter' => {
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
						'two' => q({0} m³),
					},
					'cubic-mile' => {
						'name' => q(eangas kubikkmiila),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					'day' => {
						'name' => q(jándora),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
						'two' => q({0} d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
						'two' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
						'two' => q({0} dm),
					},
					'degree' => {
						'name' => q(grádat),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(grádat Fahrenheit),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'two' => q({0}°F),
					},
					'foot' => {
						'name' => q(juolgi),
						'one' => q({0} juolgi),
						'other' => q({0} juolgi),
						'per' => q({0}/juolgi),
						'two' => q({0} juolgi),
					},
					'g-force' => {
						'name' => q(Maapallo gravitaatiovoimat),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
						'two' => q({0} g),
					},
					'hectare' => {
						'name' => q(hehtaaria),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
						'two' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hehtopascal),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					'horsepower' => {
						'name' => q(hevosvoima),
						'one' => q({0} hv),
						'other' => q({0} hv),
						'two' => q({0} hv),
					},
					'hour' => {
						'name' => q(diibmur),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
						'two' => q({0} h),
					},
					'inch' => {
						'name' => q(bealgi),
						'one' => q({0} bealgi),
						'other' => q({0} bealgi),
						'per' => q({0}/bealgi),
						'two' => q({0} bealgi),
					},
					'inch-hg' => {
						'name' => q(bealgi kvikksølv),
						'one' => q({0} bealgi Hg),
						'other' => q({0} bealgi Hg),
						'two' => q({0} bealgi Hg),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
						'two' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(kilomehtera),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
						'two' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomehtera kohti diibmu),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					'light-year' => {
						'name' => q(chuovgat jagi),
						'one' => q({0} ly),
						'other' => q({0} ly),
						'two' => q({0} ly),
					},
					'liter' => {
						'name' => q(lihtara),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/L),
						'two' => q({0} l),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
						'two' => q({0} ML),
					},
					'meter' => {
						'name' => q(mehtera),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
						'two' => q({0} m),
					},
					'meter-per-second' => {
						'name' => q(mehtera kohti sekunti),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
						'two' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(tonna),
						'one' => q({0} t),
						'other' => q({0} t),
						'two' => q({0} t),
					},
					'microgram' => {
						'one' => q({0} µg),
						'other' => q({0} µg),
						'two' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
						'two' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
						'two' => q({0} μs),
					},
					'mile' => {
						'name' => q(eangas miila),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					'mile-per-hour' => {
						'name' => q(eangas miila kohti diibmu),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
						'two' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(miila),
						'one' => q({0} miil),
						'other' => q({0} miila),
						'two' => q({0} miila),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					'milligram' => {
						'one' => q({0} mg),
						'other' => q({0} mg),
						'two' => q({0} mg),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
						'two' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(millimehtera),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(millisekundda),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					'minute' => {
						'name' => q(minuhtta),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
						'two' => q({0} min),
					},
					'month' => {
						'name' => q(mánotbadji),
						'one' => q({0} mán),
						'other' => q({0} mán),
						'per' => q({0}/mán),
						'two' => q({0} mán),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
						'two' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
						'two' => q({0} ns),
					},
					'ounce' => {
						'name' => q(unssi),
						'one' => q({0} unssi),
						'other' => q({0} unssi),
						'two' => q({0} unssi),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pikomehtera),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					'pound' => {
						'name' => q(pauna),
						'one' => q({0} pauna),
						'other' => q({0} pauna),
						'two' => q({0} pauna),
					},
					'second' => {
						'name' => q(sekundda),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
						'two' => q({0} s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
						'two' => q({0} cm²),
					},
					'square-foot' => {
						'name' => q(neliöjuolgi),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					'square-kilometer' => {
						'name' => q(neliökilomehtera),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
						'two' => q({0} km²),
					},
					'square-meter' => {
						'name' => q(neliömehtera),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
						'two' => q({0} m²),
					},
					'square-mile' => {
						'name' => q(eangas neliömiila),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'two' => q({0} mi²),
					},
					'ton' => {
						'name' => q(eangas tonna à 907kg),
						'one' => q({0} eang.ton. à 907kg),
						'other' => q({0} eang.ton. à 907kg),
						'two' => q({0} eang.ton. à 907kg),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					'week' => {
						'name' => q(váhkku),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
						'two' => q({0} v),
					},
					'yard' => {
						'name' => q(eangas yard),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					'year' => {
						'name' => q(jahkki),
						'one' => q({0} jah),
						'other' => q({0} jah),
						'per' => q({0}/jah),
						'two' => q({0} jah),
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
			'exponential' => q(·10^),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(−),
			'nan' => q(¤¤¤),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(·),
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
					'one' => '0 dt',
					'other' => '0 dt',
					'two' => '0 dt',
				},
				'10000' => {
					'one' => '00 dt',
					'other' => '00 dt',
					'two' => '00 dt',
				},
				'100000' => {
					'one' => '000 dt',
					'other' => '000 dt',
					'two' => '000 dt',
				},
				'1000000' => {
					'one' => '0 mn',
					'other' => '0 mn',
					'two' => '0 mn',
				},
				'10000000' => {
					'one' => '00 mn',
					'other' => '00 mn',
					'two' => '00 mn',
				},
				'100000000' => {
					'one' => '000 mn',
					'other' => '000 mn',
					'two' => '000 mn',
				},
				'1000000000' => {
					'one' => '0 md',
					'other' => '0 md',
					'two' => '0 md',
				},
				'10000000000' => {
					'one' => '00 md',
					'other' => '00 md',
					'two' => '00 md',
				},
				'100000000000' => {
					'one' => '000 md',
					'other' => '000 md',
					'two' => '000 md',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
					'two' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
					'two' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
					'two' => '000 bn',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
					'two' => '0 dt',
				},
				'10000' => {
					'one' => '00 dt',
					'other' => '00 dt',
					'two' => '00 dt',
				},
				'100000' => {
					'one' => '000 dt',
					'other' => '000 dt',
					'two' => '000 dt',
				},
				'1000000' => {
					'one' => '0 mn',
					'other' => '0 mn',
					'two' => '0 mn',
				},
				'10000000' => {
					'one' => '00 mn',
					'other' => '00 mn',
					'two' => '00 mn',
				},
				'100000000' => {
					'one' => '000 mn',
					'other' => '000 mn',
					'two' => '000 mn',
				},
				'1000000000' => {
					'one' => '0 md',
					'other' => '0 md',
					'two' => '0 md',
				},
				'10000000000' => {
					'one' => '00 md',
					'other' => '00 md',
					'two' => '00 md',
				},
				'100000000000' => {
					'one' => '000 md',
					'other' => '000 md',
					'two' => '000 md',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
					'two' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
					'two' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
					'two' => '000 bn',
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
		'DKK' => {
			symbol => 'Dkr',
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
				'two' => q(euro),
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
		'HKD' => {
			symbol => 'HK$',
		},
		'INR' => {
			symbol => '₹',
		},
		'ISK' => {
			symbol => 'Ikr',
		},
		'JPY' => {
			symbol => 'JP¥',
		},
		'MXN' => {
			symbol => 'MX$',
		},
		'NOK' => {
			symbol => 'kr',
			display_name => {
				'currency' => q(norgga kruvdno),
				'one' => q(norgga kruvdno),
				'other' => q(norgga kruvdno),
				'two' => q(norgga kruvdno),
			},
		},
		'SEK' => {
			symbol => 'Skr',
			display_name => {
				'currency' => q(ruoŧŧa kruvdno),
				'one' => q(ruoŧŧa kruvdno),
				'other' => q(ruoŧŧa kruvdno),
				'two' => q(ruoŧŧa kruvdno),
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
					narrow => {
						mon => 'V',
						tue => 'M',
						wed => 'G',
						thu => 'D',
						fri => 'B',
						sat => 'L',
						sun => 'S'
					},
					short => {
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
					abbreviated => {
						mon => 'vuos',
						tue => 'maŋ',
						wed => 'gask',
						thu => 'duor',
						fri => 'bear',
						sat => 'láv',
						sun => 'sotn'
					},
					narrow => {
						mon => 'V',
						tue => 'M',
						wed => 'G',
						thu => 'D',
						fri => 'B',
						sat => 'L',
						sun => 'S'
					},
					short => {
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
					wide => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
				},
				'stand-alone' => {
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
					wide => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
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
				'narrow' => {
					'pm' => q{e.b.},
					'am' => q{i.b.},
				},
				'wide' => {
					'am' => q{iđitbeaivet},
					'pm' => q{eahketbeaivet},
				},
				'abbreviated' => {
					'pm' => q{e.b.},
					'am' => q{i.b.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{i.b.},
					'pm' => q{e.b.},
				},
				'narrow' => {
					'am' => q{i.b.},
					'pm' => q{e.b.},
				},
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
			'full' => q{y MMMM d, EEEE},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMW => q{'week' W 'of' MMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{y-MM-dd, E},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{y MMMM},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{'week' w 'of' Y},
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
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
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
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
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthélemy#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
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
