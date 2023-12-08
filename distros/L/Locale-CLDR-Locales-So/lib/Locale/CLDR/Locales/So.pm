=encoding utf8

=head1 NAME

Locale::CLDR::Locales::So - Package for language Somali

=cut

package Locale::CLDR::Locales::So;
# This file auto generated from Data\common\main\so.xml
#	on Tue  5 Dec  1:31:30 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

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
				'af' => 'Afrikaanays',
 				'ak' => 'Akan',
 				'am' => 'Axmaari',
 				'ar' => 'Carabi',
 				'ar_001' => 'Carabiga rasmiga ah',
 				'as' => 'Asaamiis',
 				'az' => 'Azerbaijan',
 				'be' => 'Beleruusiyaan',
 				'bg' => 'Bulgeeriyaan',
 				'bn' => 'Bangladesh',
 				'br' => 'Bereton',
 				'bs' => 'Boosniya',
 				'ca' => 'Katalaan',
 				'cs' => 'Jeeg',
 				'cy' => 'Welsh',
 				'da' => 'Danmarkays',
 				'de' => 'Jarmal',
 				'de_CH' => 'Jarmal (Iswiiserlaand)',
 				'el' => 'Giriik',
 				'en' => 'Ingiriisi',
 				'en_AU' => 'Ingiriis Austaraaliyaan',
 				'en_CA' => 'Ingiriis Kanadiyaan',
 				'en_GB' => 'Ingiriis Biritish',
 				'en_GB@alt=short' => 'Ingiriiska Boqortooyada Midooday',
 				'en_US' => 'Ingiriis Maraykan',
 				'en_US@alt=short' => 'Ingiriisi (US)',
 				'eo' => 'Isberento',
 				'es' => 'Isbaanish',
 				'es_419' => 'Isbaanishka Laatiin Ameerika',
 				'es_ES' => 'Isbaanish (Isbayn)',
 				'et' => 'Istooniyaan',
 				'eu' => 'Basquu',
 				'fa' => 'Faarisi',
 				'fi' => 'Fiinlaandees',
 				'fil' => 'Tagalog',
 				'fo' => 'Farowsi',
 				'fr' => 'Faransiis',
 				'fr_CH' => 'Faransiis (Iswiiserlaand)',
 				'fy' => 'Firiisiyan Galbeed',
 				'ga' => 'Ayrish',
 				'gd' => 'Iskot Giilik',
 				'gl' => 'Galiisiyaan',
 				'gn' => 'Guraani',
 				'gu' => 'Gujaraati',
 				'ha' => 'Hawsa',
 				'he' => 'Cibri',
 				'hi' => 'Hindi',
 				'hr' => 'Koro’eeshiyaan',
 				'hu' => 'Hangariyaan',
 				'hy' => 'Armeeniyaan',
 				'ia' => 'Interlinguwa',
 				'id' => 'Indonesiyaan',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'is' => 'Ayslandays',
 				'it' => 'Talyaani',
 				'ja' => 'Jabaaniis',
 				'jv' => 'Jafaaniis',
 				'ka' => 'Joorijiyaan',
 				'km' => 'Kamboodhian',
 				'kn' => 'Kannadays',
 				'ko' => 'Kuuriyaan',
 				'ku' => 'Kurdishka',
 				'ky' => 'Kirgiis',
 				'la' => 'Laatiin',
 				'ln' => 'Lingala',
 				'lo' => 'Laothian',
 				'lt' => 'Lituwaanays',
 				'lv' => 'Laatfiyaan',
 				'mk' => 'Masadooniyaan',
 				'ml' => 'Malayalam',
 				'mn' => 'Mangooli',
 				'mr' => 'Maarati',
 				'ms' => 'Malaay',
 				'mt' => 'Maltiis',
 				'my' => 'Burmese',
 				'ne' => 'Nebaali',
 				'nl' => 'Holandays',
 				'nl_BE' => 'Af faleemi',
 				'nn' => 'Nowrwejiyan (naynoroski)',
 				'no' => 'Af Noorwiijiyaan',
 				'oc' => 'Okitaan',
 				'or' => 'Oriya',
 				'pa' => 'Bunjaabi',
 				'pl' => 'Boolish',
 				'ps' => 'Bashtuu',
 				'pt' => 'Boortaqiis',
 				'pt_BR' => 'Boortaqiiska Baraasiil',
 				'pt_PT' => 'Boortaqiis (Boortuqaal)',
 				'ro' => 'Romanka',
 				'ru' => 'Ruush',
 				'rw' => 'Rwanda',
 				'sa' => 'Sanskrit',
 				'sd' => 'SINDHI',
 				'sh' => 'Serbiyaan',
 				'si' => 'Sinhaleys',
 				'sk' => 'Isloofaak',
 				'sl' => 'Islofeeniyaan',
 				'so' => 'Soomaali',
 				'sq' => 'Albaaniyaan',
 				'sr' => 'Seerbiyaan',
 				'st' => 'Sesooto',
 				'sv' => 'Swiidhis',
 				'sw' => 'Sawaaxili',
 				'ta' => 'Tamiil',
 				'te' => 'Teluugu',
 				'th' => 'Taaylandays',
 				'ti' => 'Tigrinya',
 				'tk' => 'Turkumaanish',
 				'tlh' => 'Kiligoon',
 				'tr' => 'Turkish',
 				'tw' => 'Tiwiyan',
 				'ug' => 'UIGHUR',
 				'uk' => 'Yukreeniyaan',
 				'und' => 'Af aan la aqoon ama aan sax ahayn',
 				'ur' => 'Urduu',
 				'uz' => 'Usbakis',
 				'vi' => 'Fiitnaamays',
 				'xh' => 'Hoosta',
 				'yi' => 'Yadhish',
 				'yo' => 'Yoruuba',
 				'zh' => 'Jayniis Mandarin',
 				'zh_Hans' => 'Jayniis rasmiga ah',
 				'zh_Hant' => 'Jayniiskii hore',
 				'zu' => 'Zuulu',

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
			'Arab' => 'Carabi',
 			'Cyrl' => 'Siriylik',
 			'Hans' => 'La fududeeyay',
 			'Hans@alt=stand-alone' => 'Haan La fududeeyay',
 			'Hant' => 'Hore',
 			'Hant@alt=stand-alone' => 'Haanti hore',
 			'Jpan' => 'Jabaaniis',
 			'Kore' => 'Kuuriyaan',
 			'Latn' => 'Laatiin',
 			'Zxxx' => 'Aan la qorin',
 			'Zzzz' => 'Far aan la aqoon amase aan saxnayn',

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
			'001' => 'Dunida',
 			'002' => 'Afrika',
 			'003' => 'Waqooyi Ameerika',
 			'005' => 'Koonfur Ameerika',
 			'009' => 'Osheeniya',
 			'011' => 'Galbeeka Afrika',
 			'013' => 'Bartamaha Ameerika',
 			'014' => 'Afrikada Bari',
 			'015' => 'Waqooyiga Afrika',
 			'017' => 'Afrikada Dhexe',
 			'018' => 'Afrikada Koonfureed',
 			'019' => 'Ameerikaas',
 			'021' => 'Waqooyiga Ameerika',
 			'029' => 'Karibiyaan',
 			'030' => 'Aasiyada Bari',
 			'034' => 'Aasiyada Koonfureed',
 			'035' => 'Aasiyada Koonfur-galbeed',
 			'039' => 'Yurubta Koonfureed',
 			'053' => 'Austraalaasiya',
 			'054' => 'Melaneesiya',
 			'057' => 'Gobolka Aasiyada yar',
 			'061' => 'Booliyneesiya',
 			'142' => 'Aasiya',
 			'143' => 'Bartamaha Aasiya',
 			'145' => 'Aasiyada Galbeed',
 			'150' => 'Yurub',
 			'151' => 'Yurubta Bari',
 			'154' => 'Yurubta Waqooyi',
 			'155' => 'Yurubta Galbeed',
 			'202' => 'Afrikada ka hooseysa Saxaraha',
 			'419' => 'Laatiin Ameerika',
 			'AC' => 'Jasiiradda Asensiyoon',
 			'AD' => 'Andora',
 			'AE' => 'Imaaraadka Carabta ee Midoobay',
 			'AF' => 'Afgaanistaan',
 			'AG' => 'Antigua & Barbuuda',
 			'AI' => 'Anguula',
 			'AL' => 'Albaaniya',
 			'AM' => 'Armeeniya',
 			'AO' => 'Angoola',
 			'AQ' => 'Antaarktika',
 			'AR' => 'Arjentiina',
 			'AS' => 'Samowa Ameerika',
 			'AT' => 'Awsteriya',
 			'AU' => 'Awstaraaliya',
 			'AW' => 'Aruba',
 			'AX' => 'Jasiiradda Aland',
 			'AZ' => 'Asarbajan',
 			'BA' => 'Boosniya & Harsegofina',
 			'BB' => 'Baarbadoos',
 			'BD' => 'Bangladesh',
 			'BE' => 'Biljam',
 			'BF' => 'Burkiina Faaso',
 			'BG' => 'Bulgaariya',
 			'BH' => 'Baxreyn',
 			'BI' => 'Burundi',
 			'BJ' => 'Biniin',
 			'BL' => 'St. Baathelemiy',
 			'BM' => 'Barmuuda',
 			'BN' => 'Buruneeya',
 			'BO' => 'Boliifiya',
 			'BQ' => 'Karibiyaan Nadarlands',
 			'BR' => 'Baraasiil',
 			'BS' => 'Bahaamas',
 			'BT' => 'Buutan',
 			'BV' => 'Buufet Island',
 			'BW' => 'Botuswaana',
 			'BY' => 'Belarus',
 			'BZ' => 'Beliis',
 			'CA' => 'Kanada',
 			'CC' => 'Jasiiradda Kookoos',
 			'CD' => 'Jamhuuriyadda Dimuquraadiga Kongo',
 			'CD@alt=variant' => 'Jamhuuriyadda Dimuqaadiga Kongo',
 			'CF' => 'Jamhuuriyadda Afrikada Dhexe',
 			'CG' => 'Kongo',
 			'CG@alt=variant' => 'Jamhuuriyadda Kongo',
 			'CH' => 'Swiiserlaand',
 			'CI' => 'Ayfori Koost',
 			'CK' => 'Jasiiradda Kook',
 			'CL' => 'Jili',
 			'CM' => 'Kaameruun',
 			'CN' => 'Shiinaha',
 			'CO' => 'Kolombiya',
 			'CP' => 'Jasiiradda Kilibarton',
 			'CR' => 'Kosta Riika',
 			'CU' => 'Kuuba',
 			'CV' => 'Jasiiradda Kayb Faarde',
 			'CW' => 'Kurakaaw',
 			'CX' => 'Jasiiradda Kirismas',
 			'CY' => 'Qubrus',
 			'CZ' => 'Jekiya',
 			'CZ@alt=variant' => 'Jamhuuriyadda Jek',
 			'DE' => 'Jarmal',
 			'DG' => 'Diyeego Karsiya',
 			'DJ' => 'Jabuuti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominika',
 			'DO' => 'Jamhuuriyaddda Dominika',
 			'DZ' => 'Aljeeriya',
 			'EA' => 'Seyuta & Meliila',
 			'EC' => 'Ikuwadoor',
 			'EE' => 'Estooniya',
 			'EG' => 'Masar',
 			'EH' => 'Saxaraha Galbeed',
 			'ER' => 'Eritreeya',
 			'ES' => 'Isbeyn',
 			'ET' => 'Itoobiya',
 			'EU' => 'Midowga Yurub',
 			'EZ' => 'Yurusoon',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Jaziiradaha Fooklaan',
 			'FK@alt=variant' => 'Jasiiradaha Fookland',
 			'FM' => 'Mikroneesiya',
 			'FO' => 'Jasiiradda Faroo',
 			'FR' => 'Faransiis',
 			'GA' => 'Gaaboon',
 			'GB' => 'Boqortooyada Midowday',
 			'GB@alt=short' => 'GB',
 			'GD' => 'Giriinaada',
 			'GE' => 'Joorjiya',
 			'GF' => 'Faransiis Gini',
 			'GG' => 'Guurnsey',
 			'GH' => 'Gaana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambiya',
 			'GN' => 'Gini',
 			'GP' => 'Guadeluub',
 			'GQ' => 'Ekuwatooriyal Gini',
 			'GR' => 'Giriig',
 			'GS' => 'Jasiiradda Joorjiyada Koonfureed & Sandwij',
 			'GT' => 'Guwaatamaala',
 			'GU' => 'Guaam',
 			'GW' => 'Gini-Bisaaw',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Jasiiradda Haad & MakDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Korweeshiya',
 			'HT' => 'Haiti',
 			'HU' => 'Hangari',
 			'IC' => 'Jasiiradda Kanari',
 			'ID' => 'Indoneesiya',
 			'IE' => 'Ayrlaand',
 			'IL' => 'Israaʼiil',
 			'IM' => 'Jasiiradda Isle of Man',
 			'IN' => 'Hindiya',
 			'IO' => 'Dhul xadeedka Badweynta Hindiya ee Biritishka',
 			'IQ' => 'Ciraaq',
 			'IR' => 'Iiraan',
 			'IS' => 'Ayslaand',
 			'IT' => 'Talyaani',
 			'JE' => 'Jaarsey',
 			'JM' => 'Jamaaika',
 			'JO' => 'Urdun',
 			'JP' => 'Jabaan',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgistaan',
 			'KH' => 'Kamboodiya',
 			'KI' => 'Kiribati',
 			'KM' => 'Komooros',
 			'KN' => 'St. Kitts & Nefis',
 			'KP' => 'Kuuriyada Waqooyi',
 			'KR' => 'Kuuriyada Koonfureed',
 			'KW' => 'Kuwayt',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kasaakhistaan',
 			'LA' => 'Laos',
 			'LB' => 'Lubnaan',
 			'LC' => 'St. Lusia',
 			'LI' => 'Liyjtensteyn',
 			'LK' => 'Sirilaanka',
 			'LR' => 'Laybeeriya',
 			'LS' => 'Losooto',
 			'LT' => 'Lituweeniya',
 			'LU' => 'Luksemboorg',
 			'LV' => 'Latfiya',
 			'LY' => 'Liibya',
 			'MA' => 'Morooko',
 			'MC' => 'Moonako',
 			'MD' => 'Moldofa',
 			'ME' => 'Moontenegro',
 			'MF' => 'St. Maartin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Jasiiradda Maarshal',
 			'MK' => 'Masedooniya',
 			'ML' => 'Maali',
 			'MM' => 'Miyanmar',
 			'MN' => 'Mongooliya',
 			'MO' => 'Makaaw',
 			'MO@alt=short' => 'Makaaw',
 			'MP' => 'Jasiiradda Waqooyiga Mariaana',
 			'MQ' => 'Maartinik',
 			'MR' => 'Muritaaniya',
 			'MS' => 'Montserrat',
 			'MT' => 'Maalta',
 			'MU' => 'Murishiyoos',
 			'MV' => 'Maaldiqeen',
 			'MW' => 'Malaawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Musambiik',
 			'NA' => 'Namiibiya',
 			'NC' => 'Jasiiradda Niyuu Kaledooniya',
 			'NE' => 'Nayjer',
 			'NF' => 'Jasiiradda Noorfolk',
 			'NG' => 'Nayjeeriya',
 			'NI' => 'Nikaraaguwa',
 			'NL' => 'Nederlaands',
 			'NO' => 'Noorweey',
 			'NP' => 'Nebaal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Niyuusiilaand',
 			'OM' => 'Cumaan',
 			'PA' => 'Baanama',
 			'PE' => 'Beeru',
 			'PF' => 'Booliyneesiya Faransiiska',
 			'PG' => 'Babua Niyuu Gini',
 			'PH' => 'Filibiin',
 			'PK' => 'Bakistaan',
 			'PL' => 'Booland',
 			'PM' => 'Saint Pierre and Miquelon',
 			'PN' => 'Bitkairn',
 			'PR' => 'Bueerto Riiko',
 			'PS' => 'Falastiin Daanka galbeed iyo Qasa',
 			'PS@alt=short' => 'Falastiin',
 			'PT' => 'Bortugaal',
 			'PW' => 'Balaaw',
 			'PY' => 'Baraguaay',
 			'QA' => 'Qadar',
 			'QO' => 'Dhulxeebeedka Osheeniya',
 			'RE' => 'Réunion',
 			'RO' => 'Rumaaniya',
 			'RS' => 'Seerbiya',
 			'RU' => 'Ruush',
 			'RW' => 'Ruwanda',
 			'SA' => 'Sacuudi Carabiya',
 			'SB' => 'Jasiiradda Solomon',
 			'SC' => 'Sishelis',
 			'SD' => 'Suudaan',
 			'SE' => 'Iswidhan',
 			'SG' => 'Singaboor',
 			'SH' => 'Saint Helena',
 			'SI' => 'islofeeniya',
 			'SJ' => 'Jasiiradda Sfaldbaad & Jaan Mayen',
 			'SK' => 'Islofaakiya',
 			'SL' => 'Siraaliyoon',
 			'SM' => 'San Marino',
 			'SN' => 'Sinigaal',
 			'SO' => 'Soomaaliya',
 			'SR' => 'Surineym',
 			'SS' => 'Koonfur Suudaan',
 			'ST' => 'Sao Tome & Birincibal',
 			'SV' => 'El Salfadoor',
 			'SX' => 'Siint Maarteen',
 			'SY' => 'Suuriya',
 			'SZ' => 'Iswaasilaand',
 			'TA' => 'Tiristan da Kunha',
 			'TC' => 'Turks & Kaikos Island',
 			'TD' => 'Jaad',
 			'TF' => 'Dhul xadeedka Koonfureed ee Faransiiska',
 			'TG' => 'Toogo',
 			'TH' => 'Taylaand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelaaw',
 			'TL' => 'Timoor',
 			'TL@alt=variant' => 'Timoor Bari',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tuniisiya',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TT' => 'Tirinidaad & Tobago',
 			'TV' => 'Tufaalu',
 			'TW' => 'Taywaan',
 			'TZ' => 'Tansaaniya',
 			'UA' => 'Ukrayn',
 			'UG' => 'Ugaanda',
 			'UM' => 'Jasiiradaha ka baxsan Maraykanka',
 			'UN' => 'Qaramada Midoobay',
 			'US' => 'Maraykanka',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguwaay',
 			'UZ' => 'Uusbakistaan',
 			'VA' => 'Faatikaan',
 			'VC' => 'St. Finsent & Girenadiins',
 			'VE' => 'Fenisuweela',
 			'VG' => 'Biritish Farjin Island',
 			'VI' => 'U.S Fargin Island',
 			'VN' => 'Fiyetnaam',
 			'VU' => 'Fanuaatu',
 			'WF' => 'Walis & Futuna',
 			'WS' => 'Samoowa',
 			'XK' => 'Koosofo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Koonfur Afrika',
 			'ZM' => 'Saambiya',
 			'ZW' => 'Simbaabwe',
 			'ZZ' => 'Far aan la aqoon amase aan saxnayn',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Habeentiris',
 			'currency' => 'Lacag',

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
 				'gregorian' => q{Geregoriyaan},
 				'hebrew' => q{Habeentiriska yuhuudda},
 				'islamic' => q{Habeentiriska islaamka},
 				'iso8601' => q{iso8601},
 				'japanese' => q{Habeentiriska jabbaanka},
 			},
 			'collation' => {
 				'standard' => q{Istaandar},
 			},
 			'numbers' => {
 				'latn' => q{Laatiin},
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
 			'UK' => q{UK},
 			'US' => q{US},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Luuqad : {0}',
 			'script' => 'Qoraal: {0}',
 			'region' => 'Gobol : {0}',

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
			index => ['B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'Q', 'R', 'S', 'T', 'W', 'X', 'Y'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'Q', 'R', 'S', 'T', 'W', 'X', 'Y'], };
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
					'' => {
						'name' => q(Jihada),
					},
					'acre' => {
						'name' => q(aakres),
						'one' => q({0} aakre),
						'other' => q({0} aakres),
					},
					'acre-foot' => {
						'name' => q(akre-fiit),
						'one' => q({0} akre-fiit),
						'other' => q({0} akre-fiit),
					},
					'ampere' => {
						'name' => q(amberes),
						'one' => q({0} ambeer),
						'other' => q({0} ambeer),
					},
					'arc-minute' => {
						'name' => q(aarkminit),
						'one' => q({0} aarkminit),
						'other' => q({0} aarkminit),
					},
					'arc-second' => {
						'name' => q(aarksekond),
						'one' => q({0}aarksekond),
						'other' => q({0}aarksekond),
					},
					'astronomical-unit' => {
						'name' => q(unit-ka astronomikal),
						'one' => q(unit-ka astronomikal),
						'other' => q({0} unit-ka astronomikal),
					},
					'atmosphere' => {
						'name' => q(jawiga),
						'one' => q({0} jawiga),
						'other' => q({0} jawiga),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(beyt),
						'one' => q({0} beyt),
						'other' => q({0} beyt),
					},
					'calorie' => {
						'name' => q(kalooris),
						'one' => q({0} kalooris),
						'other' => q({0} kalooris),
					},
					'carat' => {
						'name' => q(karaats),
						'one' => q({0} karaats),
						'other' => q({0} karaats),
					},
					'celsius' => {
						'name' => q(degrii selsiyaas),
						'one' => q({0}°degrii selsiyaas),
						'other' => q({0}°degrii selsiyaas),
					},
					'centiliter' => {
						'name' => q(sentilitar),
						'one' => q({0} sentilitar),
						'other' => q({0} sentilitar),
					},
					'centimeter' => {
						'name' => q(Sentimitir),
						'one' => q({0} sentimitir),
						'other' => q({0} sentimitir),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(Qarniyaal),
						'one' => q(Qarni),
						'other' => q({0} Qarniyaal),
					},
					'coordinate' => {
						'east' => q({0} Bari),
						'north' => q({0} Waqooyi),
						'south' => q({0} Koonfur),
						'west' => q({0} galbeed),
					},
					'cubic-centimeter' => {
						'name' => q(sentimitir saddex jabbaaran),
						'one' => q({0} sentimitir saddex jabbaaran),
						'other' => q({0} sentimitir saddex jabbaaran),
						'per' => q({0}/sentimitir saddex jabbaaran),
					},
					'cubic-foot' => {
						'name' => q(fiit saddex jabbaaran),
						'one' => q({0} fiit saddex jabbaaran),
						'other' => q({0} fiit saddex jabbaaran),
					},
					'cubic-inch' => {
						'name' => q(inji saddex jabbaaran),
						'one' => q({0} inji saddex jabbaaran),
						'other' => q({0} inji saddex jabbaaran),
					},
					'cubic-kilometer' => {
						'name' => q(kiilomitir saddex jabbaaran),
						'one' => q({0} kiilomitir saddex jabbaaran),
						'other' => q({0} kiilomitir saddex jabaaran),
					},
					'cubic-meter' => {
						'name' => q(mitir saddex jabbaaran),
						'one' => q({0}),
						'other' => q({0} mitir saddex jabbaaran),
						'per' => q({0} mitir saddex jabbaaran),
					},
					'cubic-mile' => {
						'name' => q(meyl saddex jabbaaran),
						'one' => q({0} meyl saddex jabbaaran),
						'other' => q({0} meyl saddex jabbaaran),
					},
					'cubic-yard' => {
						'name' => q(yaardi saddex jabbaaran),
						'one' => q({0} yaardi saddex jabbaaran),
						'other' => q({0} yaardi saddex jabbaaran),
					},
					'cup' => {
						'name' => q(kaab),
						'one' => q({0} kaab),
						'other' => q({0} kaab),
					},
					'cup-metric' => {
						'name' => q(metrik kab),
						'one' => q(metrik kab),
						'other' => q({0} merik kab),
					},
					'day' => {
						'name' => q(Maalmo),
						'one' => q({0} maalin),
						'other' => q({0} maalmooyin),
						'per' => q({0} maalin kasta),
					},
					'deciliter' => {
						'name' => q(desilitar),
						'one' => q({0} desilitar),
						'other' => q({0} desilitar),
					},
					'decimeter' => {
						'name' => q(desimitir),
						'one' => q({0} desimitir),
						'other' => q({0} dsimitir),
					},
					'degree' => {
						'name' => q(darajo),
						'one' => q({0} darajo),
						'other' => q({0} darajo),
					},
					'fahrenheit' => {
						'name' => q(degrees Faahrenheyt),
						'one' => q({0} degrii Faahrenheyt),
						'other' => q({0} degrii Faahrenheyt),
					},
					'fluid-ounce' => {
						'name' => q(fuluud owns),
						'one' => q({0} fuluud owns),
						'other' => q({0} fuluud owns),
					},
					'foodcalorie' => {
						'name' => q(kalooris),
						'one' => q({0} kalooris),
						'other' => q({0} kalooris),
					},
					'foot' => {
						'name' => q(fiit),
						'one' => q(Fiit),
						'other' => q({0}Fiit),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(cadaadis dib ku riixaya),
						'one' => q({0} cadaadis dib ku riixaya),
						'other' => q({0} cadaadis dib ku riixaya),
					},
					'gallon' => {
						'name' => q(galoons),
						'one' => q({0}galoons),
						'other' => q({0} galoons),
						'per' => q({0}/gal US),
					},
					'gallon-imperial' => {
						'name' => q(imb.galoons),
						'one' => q({0} imb. galoon),
						'other' => q({0} imb. galoons),
						'per' => q({0} /imb.galoon),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					'gigabyte' => {
						'name' => q(gigabeyt),
						'one' => q({0} gigabeyt),
						'other' => q({0} gigabeyt),
					},
					'gigahertz' => {
						'name' => q(gigahaart),
						'one' => q({0} gigahaart),
						'other' => q({0} gigahaart),
					},
					'gigawatt' => {
						'name' => q(gigawaats),
						'one' => q({0} gigawaat),
						'other' => q({0} gigawaat),
					},
					'gram' => {
						'name' => q(garaam),
						'one' => q({0} garaam),
						'other' => q({0} garaam),
						'per' => q({0} garaam kasta),
					},
					'hectare' => {
						'name' => q(hektar),
						'one' => q(hektar),
						'other' => q({0} hektar),
					},
					'hectoliter' => {
						'name' => q(hektolitar),
						'one' => q({0} hektolitar),
						'other' => q({0} hektarlitar),
					},
					'hectopascal' => {
						'name' => q(hektobaskal),
						'one' => q({0}hektobaskals),
						'other' => q({0}hektobaskal),
					},
					'hertz' => {
						'name' => q(haarts),
						'one' => q({0} haarts),
						'other' => q({0} haarts),
					},
					'horsepower' => {
						'name' => q(korontadafardaha),
						'one' => q({0}korontadafardaha),
						'other' => q({0}korontadafardaha),
					},
					'hour' => {
						'name' => q(saacado),
						'one' => q({0} saacad),
						'other' => q({0} saacado),
						'per' => q({0} saacad/kasta),
					},
					'inch' => {
						'name' => q(Injis),
						'one' => q(Injis),
						'other' => q({0} injis),
						'per' => q({0} inji/kasta),
					},
					'inch-hg' => {
						'name' => q(inji maarkuri),
						'one' => q({0} inji maarkuri),
						'other' => q({0} inji maarkuri),
					},
					'joule' => {
						'name' => q(Juul),
						'one' => q({0} juul),
						'other' => q({0} juuls),
					},
					'karat' => {
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					'kelvin' => {
						'name' => q(kelfin),
						'one' => q({0} kelfin),
						'other' => q({0} kelfin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kiiloobeyt),
						'one' => q({0} kiilobeyt),
						'other' => q({0} kilobeyt),
					},
					'kilocalorie' => {
						'name' => q(kilokalooris),
						'one' => q({0} kilokalooris),
						'other' => q({0} kilokalooris),
					},
					'kilogram' => {
						'name' => q(kiilogaraam),
						'one' => q({0} kiilogaraam),
						'other' => q({0} kiilogaraam),
						'per' => q({0} kiilogaraam),
					},
					'kilohertz' => {
						'name' => q(kiilohaarts),
						'one' => q({0} kiilohaarts),
						'other' => q({0} kiilohaarts),
					},
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kiilojuul),
						'other' => q({0} kiilojuuls),
					},
					'kilometer' => {
						'name' => q(Kiilo mitir),
						'one' => q(Kiilo mitir),
						'other' => q({0}Kiilo mitir),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(kiilomitir saacaddiiba),
						'one' => q({0} kiiomitir saacaddiiba),
						'other' => q({0} kiilomitir saacaddiiba),
					},
					'kilowatt' => {
						'name' => q(kiilowaat),
						'one' => q({0} kiilowaat),
						'other' => q({0} kiilowaat),
					},
					'kilowatt-hour' => {
						'name' => q(kiilowaat- saacado),
						'one' => q({0} kiilowaat saacaddiiba),
						'other' => q({0} kiilowaat saacaddiiba),
					},
					'knot' => {
						'name' => q(gunnad),
						'one' => q({0} gunnad),
						'other' => q({0} gunnad),
					},
					'light-year' => {
						'name' => q(masaafada iftiinka),
						'one' => q(Masaafada Iftiinka),
						'other' => q({0}masaafad iftiinka),
					},
					'liter' => {
						'name' => q(litar),
						'one' => q({0} litar),
						'other' => q({0} litar),
						'per' => q({0} litar kasta),
					},
					'liter-per-100kilometers' => {
						'name' => q(litar baar 100 kiilomitir),
						'one' => q({0} litar baar 100 kiilomitir),
						'other' => q({0} litar baar 100 kiilomitir),
					},
					'liter-per-kilometer' => {
						'name' => q(litar baar kiilomitir),
						'one' => q(litar baarkiilomitir),
						'other' => q({0} litar baar kiilomitirlitar baar kiilomitir),
					},
					'lux' => {
						'name' => q(laks),
						'one' => q({0} laks),
						'other' => q({0} laks),
					},
					'megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabeyt),
						'one' => q({0} megabeyt),
						'other' => q({0} megabeyt),
					},
					'megahertz' => {
						'name' => q(meegahaarts),
						'one' => q({0} megahaarts),
						'other' => q({0} megahaarts),
					},
					'megaliter' => {
						'name' => q(megalitar),
						'one' => q({0} megalitar),
						'other' => q({0} megalitar),
					},
					'megawatt' => {
						'name' => q(meegawaat),
						'one' => q({0} meegawaat),
						'other' => q({0} meegawaat),
					},
					'meter' => {
						'name' => q(mitir),
						'one' => q({0} mitir),
						'other' => q({0} mitir),
						'per' => q({0} /m),
					},
					'meter-per-second' => {
						'name' => q(mitir il-biriqsi kasta),
						'one' => q(mitir il-biriqsi kasta),
						'other' => q({0} mitir ilbiriqsi kasta),
					},
					'meter-per-second-squared' => {
						'name' => q(mitir kasta daqiiqad labo jabbaaran),
						'one' => q(mitir kastadaqiiqad labo jabbaaran),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(metrik ton),
						'one' => q({0} metrik ton),
						'other' => q({0} metrik ton),
					},
					'microgram' => {
						'name' => q(mikrogaraam),
						'one' => q({0}mikrogaraam),
						'other' => q({0}mikrogaraam),
					},
					'micrometer' => {
						'name' => q(mikromitir),
						'one' => q({0} mikromitir),
						'other' => q({0} mikromitir),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(Meyl),
						'one' => q({0} meyl),
						'other' => q({0} meyl),
					},
					'mile-per-gallon' => {
						'name' => q(meyl baar galoon),
						'one' => q({0} meyl baar galoon),
						'other' => q({0} meyl baar galoon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(meyl baar imb.galoon),
						'one' => q({0} meyl baar imb.galoon),
						'other' => q({0} meyl baar imb.galoon),
					},
					'mile-per-hour' => {
						'name' => q(mely saacaddiiba),
						'one' => q({0} meyl saacaddiiba),
						'other' => q({0} meyl saacaddiiba),
					},
					'mile-scandinavian' => {
						'name' => q(meyl-iskandineyfiyaan),
						'one' => q({0} meyl-iskandineyfiyaan),
						'other' => q({0} meyl-iskanddineyfiyaan),
					},
					'milliampere' => {
						'name' => q(miliambeer),
						'one' => q({0}miliambeer),
						'other' => q({0}miliambeer),
					},
					'millibar' => {
						'name' => q(milibaars),
						'one' => q({0} milibaar),
						'other' => q({0} milibaar),
					},
					'milligram' => {
						'name' => q(miligaraam),
						'one' => q({0} miligaraam),
						'other' => q({0} miligaraam),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligaram baar desilitar),
						'one' => q({0} milligaram baar desilitar),
						'other' => q({0} milligaram baar desilitar),
					},
					'milliliter' => {
						'name' => q(mililitar),
						'one' => q({0} mililitar),
						'other' => q({0} mililitar),
					},
					'millimeter' => {
						'name' => q(milimitir),
						'one' => q({0} milimitir),
						'other' => q({0} milimitir),
					},
					'millimeter-of-mercury' => {
						'name' => q(milimeter ee maarkuri),
						'one' => q({0} milimeter ee maarkuri),
						'other' => q({0} milimeter ee maarkuri),
					},
					'millimole-per-liter' => {
						'name' => q(millimool baar litar),
						'one' => q({0} millimool baar litar),
						'other' => q({0} millimool baar litar),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(miliwaat),
						'one' => q({0} miliwaat),
						'other' => q({0} miliwaat),
					},
					'minute' => {
						'name' => q(daqiiqadooyin),
						'one' => q({0} daqiiqad),
						'other' => q({0} daqiiqad),
						'per' => q({0} daqiiqad/kasta),
					},
					'month' => {
						'name' => q(Bilooyin),
						'one' => q({0}Bil),
						'other' => q({0}Bil),
						'per' => q({0}Bil kasta),
					},
					'nanometer' => {
						'name' => q(nanomitir),
						'one' => q({0} nanomitir),
						'other' => q({0} nanomitir),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(Nuutikal meyl),
						'one' => q(nuutika meyl),
						'other' => q({0} nuutikal meyl),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(owns),
						'one' => q({0} owns),
						'other' => q({0} owns),
						'per' => q({0} owns kasta),
					},
					'ounce-troy' => {
						'name' => q(torooy owns),
						'one' => q({0} torooy owns),
						'other' => q({0} torooy owns),
					},
					'parsec' => {
						'name' => q(Barseks),
						'one' => q({0} barseks),
						'other' => q({0} barseks),
					},
					'part-per-million' => {
						'name' => q(baart baar milyan),
						'one' => q({0} baart baar milyan),
						'other' => q({0} baart baar milyan),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(boqolkiiba),
						'one' => q({0} boqolkiiba),
						'other' => q({0} boqolkiiba),
					},
					'permille' => {
						'name' => q(baarmiil),
						'one' => q({0} baarmiil),
						'other' => q({0} baarmiil),
					},
					'petabyte' => {
						'name' => q(betybeyt),
						'one' => q({0} betabeyt),
						'other' => q({0} betabeyt),
					},
					'picometer' => {
						'name' => q(Bikomitir),
						'one' => q({0} bikomitir),
						'other' => q({0} bikomitir),
					},
					'pint' => {
						'name' => q(bints),
						'one' => q({0} bints),
						'other' => q({0} bints),
					},
					'pint-metric' => {
						'name' => q(metrik bints),
						'one' => q({0} metrik bint),
						'other' => q({0} metrik bint),
					},
					'point' => {
						'name' => q(dhibicyo),
						'one' => q({0} dhibic),
						'other' => q({0} dhibic),
					},
					'pound' => {
						'name' => q(bownd),
						'one' => q({0} bownd),
						'other' => q({0} bownd),
						'per' => q({0} bowndkiiba),
					},
					'pound-per-square-inch' => {
						'name' => q(bownd baar inji labo jabbaaran),
						'one' => q({0} bownd baar inji labo jabbaaran),
						'other' => q({0} bownd baar inji labo jabbaaran),
					},
					'quart' => {
						'name' => q(kowaarts),
						'one' => q({0} kowaarts),
						'other' => q({0}kowaarts),
					},
					'radian' => {
						'name' => q(shucaac),
						'one' => q({0} shucaac),
						'other' => q({0} shucaac),
					},
					'revolution' => {
						'name' => q(wareeg),
						'one' => q({0} wareeg),
						'other' => q({0} wareeg),
					},
					'second' => {
						'name' => q(il-biriqsi),
						'one' => q({0} il-biriqsi),
						'other' => q({0} il-biriqsi),
						'per' => q({0} Il-biriqsi/Kasta),
					},
					'square-centimeter' => {
						'name' => q(sentimitir jabbaaran),
						'one' => q(sentimitir jabbaaran),
						'other' => q({0} sentimitir jabbaaran),
						'per' => q({0} sentimitir jabbaaran/ kasta),
					},
					'square-foot' => {
						'name' => q(fiit labo jabbaaran),
						'one' => q({0} fiit labo jabbaaran),
						'other' => q({0} fiit labo jabbaaran),
					},
					'square-inch' => {
						'name' => q(Injis labo jabbaaran),
						'one' => q({0} Inji labo jabbaaran),
						'other' => q({0} inji labo jabbaaran),
						'per' => q({0} Inji labo jabbaaran/kasta),
					},
					'square-kilometer' => {
						'name' => q(labo jabaaran kiilomitir),
						'one' => q({0} labo jabaaran kiilomitir),
						'other' => q({0} labo jabaaran kiilomitir),
						'per' => q({0} labo jabaaran kiilomitir kasta),
					},
					'square-meter' => {
						'name' => q(mitir jabbaaran),
						'one' => q({0} mitir jabbaaran),
						'other' => q({0} mitir jabbaaran),
						'per' => q({0} mitir jabbaaran/kasta),
					},
					'square-mile' => {
						'name' => q(meyl jabbaaran),
						'one' => q({0} meyl jabbaaran),
						'other' => q({0} meyl jabbaaran),
						'per' => q({0} meyl jabbaaran/kasta),
					},
					'square-yard' => {
						'name' => q(yaardi labo jabbaaran),
						'one' => q({0} yaardi labo jabbaaran),
						'other' => q({0} yaardi labo jabbaaran),
					},
					'tablespoon' => {
						'name' => q(malgacad),
						'one' => q({0} malgacad),
						'other' => q({0} malgacad),
					},
					'teaspoon' => {
						'name' => q(malgacadda shaah),
						'one' => q(malgacadda shaah),
						'other' => q({0} malgacadda shaaha),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabeyt),
						'one' => q({0} terabeyt),
						'other' => q({0} terabeyt),
					},
					'ton' => {
						'name' => q(tan),
						'one' => q({0}tan),
						'other' => q({0}tan),
					},
					'volt' => {
						'name' => q(foolt),
						'one' => q({0} foolt),
						'other' => q({0} foolt),
					},
					'watt' => {
						'name' => q(waat),
						'one' => q({0} waat),
						'other' => q({0} waat),
					},
					'week' => {
						'name' => q(Usbuuc/Sitimaan),
						'one' => q(Usbuuc/Sitimaan),
						'other' => q({0} Usbuucyo),
						'per' => q({0} Usbuuc kasta),
					},
					'yard' => {
						'name' => q(Yaardi),
						'one' => q({0} yaardi),
						'other' => q({0} yaardi),
					},
					'year' => {
						'name' => q(Sannado),
						'one' => q({0} Sannad),
						'other' => q({0}Sannado),
						'per' => q({0} Sannad Kasta),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(jiho),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0} B),
						'north' => q({0} W),
						'south' => q({0} K),
						'west' => q({0} G),
					},
					'day' => {
						'name' => q(maalmo),
						'one' => q({0}M),
						'other' => q({0}M/k),
						'per' => q({0}M/K),
					},
					'gram' => {
						'name' => q(garaam),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(saacado),
						'one' => q({0} h),
						'other' => q({0} S),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/s),
						'one' => q({0} km/s),
						'other' => q({0} km/s),
					},
					'liter' => {
						'name' => q(litar),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(daqiiqado),
						'one' => q({0} daqiiqo),
						'other' => q({0} daqiiqo),
					},
					'month' => {
						'name' => q(Bilooyin),
						'one' => q({0}Bil),
						'other' => q({0}Bil),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'second' => {
						'name' => q(il-biriqsi),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'week' => {
						'name' => q(Usbuucyo),
						'one' => q({0} Sit),
						'other' => q({0} U),
						'per' => q({0} U/K),
					},
					'year' => {
						'name' => q(SN),
						'one' => q(S),
						'other' => q({0}Sno),
					},
				},
				'short' => {
					'' => {
						'name' => q(jiho),
					},
					'acre' => {
						'name' => q(aakres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(akr ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(aarkminit),
						'one' => q({0} aarkminit),
						'other' => q({0} aarkminit),
					},
					'arc-second' => {
						'name' => q(aarksekond),
						'one' => q({0}aarksekond),
						'other' => q({0}aarksekond),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'atmosphere' => {
						'name' => q(jawiga),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(beyt),
						'one' => q({0} beyt),
						'other' => q({0} beyt),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(karaats),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(deg. C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'coordinate' => {
						'east' => q({0} B),
						'north' => q({0} W),
						'south' => q({0} K),
						'west' => q({0} G),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(fiit saddex jabbaaran),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(inji saddex jabbaaran),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yaardi saddex jabbaaran),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(kaab),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(maalmo),
						'one' => q({0} maalin),
						'other' => q({0} maalmooyin),
						'per' => q({0}M/K),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(darajo),
						'one' => q({0} darajo),
						'other' => q({0} darajo),
					},
					'fahrenheit' => {
						'name' => q(deg. F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(fuluud owns),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(cadaadis dib ku riixaya),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(US gal),
						'one' => q({0} gal US),
						'other' => q({0} gal US),
						'per' => q({0}/gal US),
					},
					'gallon-imperial' => {
						'name' => q(imb.gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GBeyt),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(garaam),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(saacado),
						'one' => q({0} s),
						'other' => q({0} h),
						'per' => q({0} s/k),
					},
					'inch' => {
						'name' => q(injjis),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(juuls),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karaat),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kBeyt),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kilokalooris),
						'one' => q({0} kilokalooris),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kiilojuul),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(kiilomitir saacaddiiba),
						'one' => q({0} kiilomitir saaciidaba),
						'other' => q({0} km/s),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(KW-saacad),
						'one' => q({0} KWs),
						'other' => q({0} KWs),
					},
					'knot' => {
						'name' => q(gn),
						'one' => q({0} gn),
						'other' => q({0} gn),
					},
					'light-year' => {
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(litar),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(litar/kiilomitir),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(laks),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MBeyt),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(mitir/ilbiriqsi),
						'one' => q({0} m/ilbiriqsi),
						'other' => q({0} m/ilbiriqsi),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µmitir),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(meyl),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(meyl/galoon),
						'one' => q({0} mpg US),
						'other' => q({0} mpg US),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(meyl/gal imb.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(meyl saacaddiiba),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(daqiiqado),
						'one' => q({0} daqiiqo),
						'other' => q({0} daqiiqo),
						'per' => q({0} d/k),
					},
					'month' => {
						'name' => q(Bilooyin),
						'one' => q({0}Bil),
						'other' => q({0}Bil),
						'per' => q({0}B/K),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(torooy os),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(baart/milyan),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(boqolkiiba),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(baarmiil),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(bBeyt),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(bm),
						'one' => q({0} bm),
						'other' => q({0} bm),
					},
					'pint' => {
						'name' => q(bints),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(dhibicyo),
						'one' => q({0} dhibic),
						'other' => q({0} dhibic),
					},
					'pound' => {
						'name' => q(bownd),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(shucaac),
						'one' => q({0} shucaac),
						'other' => q({0} shucaac),
					},
					'revolution' => {
						'name' => q(Wareeg),
						'one' => q({0} wareeg),
						'other' => q({0} wareeg),
					},
					'second' => {
						'name' => q(il-biriqsi),
						'one' => q({0} il -biriqsi),
						'other' => q({0} il-biriqsi),
						'per' => q({0} Il-biriqsi/Kasta),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(fiit jabbaaran),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(Injis labo jabbaaran),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(mitir jabbaaran),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(meyl jabbaaran),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yaardi labo jabbaaran),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(malgacad),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TBeyt),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tan),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(foolt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(waat),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(Usbuucyo),
						'one' => q({0} Sit),
						'other' => q({0} Usbuucyo),
						'per' => q({0} U/K),
					},
					'yard' => {
						'name' => q(yaardi),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(SN),
						'one' => q(S),
						'other' => q({0}Sno),
						'per' => q({0}S/K),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:haa|h|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:maya|m|no|n)$' }
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
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
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
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
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
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(Dirhamka Isutaga Imaaraatka Carabta),
				'one' => q(Dirham Isutaga Imaaraatka Carabta),
				'other' => q(Dirhamka Isutaga Imaaraatka Carabta),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afgan Afgan),
				'one' => q(Afgan Afgan),
				'other' => q(Afgan Afgan),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek Albaniya),
				'one' => q(Lek Abaniya),
				'other' => q(ALL),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Daraamka Armeniya),
				'one' => q(Daraam Armeniya),
				'other' => q(Daraamka Armeniya),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Galdar Nadarland Antilean),
				'one' => q(Galdar Nadarland Antilaan),
				'other' => q(Galdar Nadarland Antilean),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kawansada Angola),
				'one' => q(Kawansa Angola),
				'other' => q(Kawansada Angola),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Beeso Arjentina),
				'one' => q(Beeso Arjentiina),
				'other' => q(Beeso Arjentina),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Doolarka Awstaraaliya),
				'one' => q(Doolarka Awstaraaliya),
				'other' => q(Doolarada Awstaraaliya),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Foloorin Aruban),
				'one' => q(Foloorin Aruban),
				'other' => q(Foloorin Aruban),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manaatada Asarbeyjan),
				'one' => q(Manaata Asarbeyjan),
				'other' => q(Manaatada Asarbeyjan),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Konfatibal Maak Bosnia-Hersogofina),
				'one' => q(Konfatibal Maak Bosni-Harsegofina),
				'other' => q(Konfatibal Maak Bosnia-Hersogofina),
			},
		},
		'BBD' => {
			symbol => 'DBB',
			display_name => {
				'currency' => q(Doolarka Barbaadiyaanka),
				'one' => q(Doolarka Barbaadiyaanka),
				'other' => q(Doolarada Barbaadiyaanka),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka Bangledesh),
				'one' => q(Taka Bangledesh),
				'other' => q(Taka Bangledesh),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lef Bulgariya),
				'one' => q(Lef Bulgariya),
				'other' => q(BGN),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinaarka Baxreyn),
				'one' => q(Dinaar Baxreyn),
				'other' => q(Dinaarka Baxreyn),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Farank Burundi),
				'one' => q(Farank Burundi),
				'other' => q(Farank Burundi),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Doolarka Barmuuda),
				'one' => q(Doolaraka Barmuuda),
				'other' => q(Doolarada Barmuuda),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Doollarka Burunel),
				'one' => q(Doollar Burunel),
				'other' => q(Doollarka Burunel),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Bolifiano Bolifiya),
				'one' => q(Bolifaano Bolifiya),
				'other' => q(BOB),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Real Barasil),
				'one' => q(Real Barasil),
				'other' => q(Real Barasil),
			},
		},
		'BSD' => {
			symbol => 'DBS',
			display_name => {
				'currency' => q(Doolarka Bahamaas),
				'one' => q(Doolarka Bahamaas),
				'other' => q(Doolarada Bahamaas),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultaram Butan),
				'one' => q(Ngultaram Butan),
				'other' => q(Ngultaram Butan),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Buulada Botswana),
				'one' => q(Buulo Botswana),
				'other' => q(Buulada Botswana),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Rubalka Belarus),
				'one' => q(Rubal Belarus),
				'other' => q(Rubalka Belarus),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Doolarka Beelisa),
				'one' => q(Doolarka Beelisa),
				'other' => q(Doolarada Beelisa),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Doolarka Kanada),
				'one' => q(Doolarka Kanada),
				'other' => q(Doolarada Kanada),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Farank Kongo),
				'one' => q(Farank Kongo),
				'other' => q(Farank Kongo),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Farank Iswis),
				'one' => q(Farank Iswis),
				'other' => q(Farank Iswis),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Beeso Jili),
				'one' => q(Beeso Jili),
				'other' => q(Beeso Jili),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Yuanta Shiinaha \(Offshore\)),
				'one' => q(Yuan Shiinaha \(offshore\)),
				'other' => q(Yuanta Shiinaha \(Offshore\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuanta Shiinaha),
				'one' => q(Yuanta Shiinaha),
				'other' => q(CNY),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Beeso Kolombiya),
				'one' => q(Beeso Kolombiya),
				'other' => q(COP),
			},
		},
		'CRC' => {
			symbol => 'KKR',
			display_name => {
				'currency' => q(Kolon Kosta Rika),
				'one' => q(Kolon Kosta Rika),
				'other' => q(Kolon Kosta Rika),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Beeso Kuuba Konfatibal),
				'one' => q(Beeso Kuuba Konfatibal),
				'other' => q(Beeso Kuuba Konfatibal),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Beeso Kuuba),
				'one' => q(Beeso Kuuba),
				'other' => q(Beeso Kuuba),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Eskudo Keyb Farde),
				'one' => q(Eskudo Keyb Farde),
				'other' => q(Eskudo Keyb Farde),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Korunada Jeek),
				'one' => q(Koruna Jeek),
				'other' => q(Korunada Jeek),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Faran Jabbuuti),
				'one' => q(Farank Jabuuti),
				'other' => q(Farank Jabuuti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Koranka Danishka),
				'one' => q(Koran Danish),
				'other' => q(Koranka Danishka),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Beeso Dominika),
				'one' => q(Beeso Dominika),
				'other' => q(Beeso Dominika),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinaarka Aljeriya),
				'one' => q(Dinaar Aljeriya),
				'other' => q(Dinaarka Aljeriya),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Bowndka Masar),
				'one' => q(Bownd Masar),
				'other' => q(Bowndka Masar),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nafkada Eritriya),
				'one' => q(Nakfa Eritriya),
				'other' => q(Nafkada Eritriya),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birta Itoobbiya),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Yuuroo),
				'one' => q(Yuuroo),
				'other' => q(Yuuroo),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Doolarka Fiji),
				'one' => q(Doolarka Fiji),
				'other' => q(Doolarada Fiji),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Bowndka Faalkland Island),
				'one' => q(Bowndka Faalkland Island),
				'other' => q(Bowndka Faalkland Island),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Bowndka Biritishka),
				'one' => q(Bownd Biritish),
				'other' => q(Bowndka Biritishka),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Laariga Joorjiya),
				'one' => q(Laari Joorjiya),
				'other' => q(Laariga Joorjiya),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Sedi Gana),
				'one' => q(Sedi Gana),
				'other' => q(Sedi Gana),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Bowndka Gibraltar),
				'one' => q(Bownd Gibraltar),
				'other' => q(Bowndka Gibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi Gambiya),
				'one' => q(Dalasi Gambiya),
				'other' => q(Dalasi Gambiya),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Faranka Gini),
				'one' => q(Farank Gini),
				'other' => q(GNF),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetsal Guatemala),
				'one' => q(Quetsal Guatemala),
				'other' => q(Quetsal Guatemala),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Doolarka Guyanes),
				'one' => q(Doolarka Guyanes),
				'other' => q(GYD),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Doollarka Hong Kong),
				'one' => q(Doollar Hong Kong),
				'other' => q(Doollarka Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'LHN',
			display_name => {
				'currency' => q(Lembira Hondura),
				'one' => q(Lembira Hondura),
				'other' => q(Lembira Hondura),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna Korooshiya),
				'one' => q(Kuna Korooshiya),
				'other' => q(HRK),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Goorde Haiti),
				'one' => q(Goorde Haiti),
				'other' => q(Goorde Haiti),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Forintiska Hangari),
				'one' => q(Forintis Hangari),
				'other' => q(Forintiska Hangari),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Rubiah Indonesiya),
				'one' => q(Rubiah Indonesiya),
				'other' => q(Rubiah Indonesiya),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Niyuu Shekelka Israaiil),
				'one' => q(Niyuu Shekel Israaiil),
				'other' => q(Niyuu Shekelka Israaiil),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rubiga Hindiya),
				'one' => q(Rubi Hindiya),
				'other' => q(INR),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinaarka Ciraaq),
				'one' => q(Dinaar Ciraaq),
				'other' => q(Dinaarka Ciraaq),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Riyaalka Iran),
				'one' => q(Riyaal Iran),
				'other' => q(Riyaalka Iran),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Korona Eysland),
				'one' => q(Korona Eysland),
				'other' => q(Koronada Eysland),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Doolarka Jamaaika),
				'one' => q(Doolarka Jamaaika),
				'other' => q(Doolarada Jamaaika),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinaarka Joordan),
				'one' => q(Dinaar Joordan),
				'other' => q(Dinaarka Joordan),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yenta Jaban),
				'one' => q(Yen Jaban),
				'other' => q(Yenta Jaban),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Shilingka Kenya),
				'one' => q(Shiling Kenya),
				'other' => q(Shilingka Kenya),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Soom Kiyrgiystan),
				'one' => q(Soom Kiyriygstan),
				'other' => q(KGS),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riyf Cambodiya),
				'one' => q(Riyf Combodiya),
				'other' => q(Riyf Cambodiya),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Farank Komora),
				'one' => q(Farank Komora),
				'other' => q(Farank Komora),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Wonka Waqooyi Kuuriya),
				'one' => q(Won Waqooyi Kuuriya),
				'other' => q(Wonka Waqooyi Kuuriya),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Wonka Koonfur Kuuriya),
				'one' => q(Won Koonfur Kuuriya),
				'other' => q(Wonka Koonfur Kuuriya),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinaarka Kuweyt),
				'one' => q(Dinaar Kuweyt),
				'other' => q(Dinaarka Kuweyt),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Doolarka jasiiradaha Kayman),
				'one' => q(Doolarka jasiiradaha Kayman),
				'other' => q(Doolarka Jasiiradaha Kayman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge Kasakhstan),
				'one' => q(Tenge Kasakhstan),
				'other' => q(Tenge Kasakhstan),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kib Laoti),
				'one' => q(Kib Laoti),
				'other' => q(LAK),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Bowndka Lebanon),
				'one' => q(Bownd Lebanon),
				'other' => q(Bowndka Lebanon),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rubiga Siri lanka),
				'one' => q(Rubiga Siri Lanka),
				'other' => q(Rubiga Siri lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Doollarka Liberiya),
				'one' => q(Doollar Liberiya),
				'other' => q(Doollarka Liberiya),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinaarka Libya),
				'one' => q(Dinaar Libya),
				'other' => q(Dinaarka Libya),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Dirhamka Moroko),
				'one' => q(Dirham Moroko),
				'other' => q(Dirhamka Moroko),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leeyuu Moldofa),
				'one' => q(Leeyuu Moldofa),
				'other' => q(Leeyuu Moldofa),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariari Malagasy),
				'one' => q(Ariari Malagasi),
				'other' => q(Ariari Malagasy),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denaarka Masedoniya),
				'one' => q(Denaar Masedoniya),
				'other' => q(MKD),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kayat Mayanmaar),
				'one' => q(Kayat Mayanmaar),
				'other' => q(Kayat Mayanmaar),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik Mongoliya),
				'one' => q(Tugrik Mongoliya),
				'other' => q(Tugrik Mongoliya),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Bataka Makana),
				'one' => q(Bataka Makana),
				'other' => q(Bataka Makana),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Oogiya Mawritaniya \(1973–2017\)),
				'one' => q(Oogiya Mawritaniya \(1973–2017\)),
				'other' => q(Oogiya Mawritaniya \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(MRU),
				'one' => q(Oogiya Mawritaniya),
				'other' => q(Oogiya Mawritaniya),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rubiga Mowrishiya),
				'one' => q(Rubi Mowrishiya),
				'other' => q(Rubiga Mowrishiya),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rufiya Maldifiya),
				'one' => q(Rufiya Maldifiya),
				'other' => q(Rufiya Maldifiya),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kawajada Malawi),
				'one' => q(Kawaja Malawi),
				'other' => q(Kawajada Malawi),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Beeso Meksikaan),
				'one' => q(Beeso Meksikaan),
				'other' => q(BMX),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Ringit Malayshiya),
				'one' => q(Ringit Malayshiya),
				'other' => q(Ringit Malayshiya),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metikalka Mosambik),
				'one' => q(Metikal Mosambik),
				'other' => q(Metikalka Mosambik),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Doollarka Namibiya),
				'one' => q(Doollar Namibiya),
				'other' => q(Doollarka Namibiya),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nairada Neyjeeriya),
				'one' => q(Naira Neyjeeriya),
				'other' => q(Nairada Neyjeeriya),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nikaragua Kordoba),
				'one' => q(Nakaragua Kordoba),
				'other' => q(NIkaragua Kordoba),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Koronka Norway),
				'one' => q(Koronka Norway),
				'other' => q(Koronka Norway),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rubiga Nebal),
				'one' => q(Rubiga Nebal),
				'other' => q(Rubiga Nebal),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Doolarka Niyuu Siyalaan),
				'one' => q(Doolarka Niyuu siyalaan),
				'other' => q(Doolarada Niyuu Siya laan),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Riyaalka Comaan),
				'one' => q(Riyaal Comaan),
				'other' => q(Riyaalka Comaan),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa Panama),
				'one' => q(Balbao Banaama),
				'other' => q(Balboa Panama),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sol Beeru),
				'one' => q(Sol Beero),
				'other' => q(PEN),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kinada Babua Niyuu Gini),
				'one' => q(Kina Babua Niyuu Gini),
				'other' => q(Kinada Babua Niyuu Gini),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Biso Filibin),
				'one' => q(Biso Filibin),
				'other' => q(Biso Filibin),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rubiga Bakistan),
				'one' => q(Rubi Bakistan),
				'other' => q(Rubiga Bakistan),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Solotida Boland),
				'one' => q(Sooti Boland),
				'other' => q(Solotida Boland),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guarani Baraguay),
				'one' => q(Guarani Baraguay),
				'other' => q(Guarani Baraguay),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Riyaalka Qatar),
				'one' => q(Riyaal Qatar),
				'other' => q(Riyaalka Qatar),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Liyuu ROmaniya),
				'one' => q(Liyuu Romaniya),
				'other' => q(Liyuu ROmaniya),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinaarka Serbiya),
				'one' => q(Dinaar Serbiya),
				'other' => q(RSD),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rubalka Ruush),
				'one' => q(Rubal Ruush),
				'other' => q(Rubalka Ruush),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Farank Ruwanda),
				'one' => q(Farank Ruwanda),
				'other' => q(Farank Ruwanda),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riyaalka Sacuudiga),
				'one' => q(Riyaal Sacuudi),
				'other' => q(Riyaalka Sacuudiga),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Doolarka Jasiiradaha Solomon),
				'one' => q(Doolarka Jasiiradaha Solomon),
				'other' => q(Doolarada Jasiiradaha Solomon),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rubiga Siisalis),
				'one' => q(Rubi Siisalis),
				'other' => q(SCR),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Bowndka Suudaan),
				'one' => q(SDG),
				'other' => q(SDG),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Koronka Isweden),
				'one' => q(Koronka Isweden),
				'other' => q(Koronka Isweden),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Doollarka Singabuur),
				'one' => q(Doollar Singabuur),
				'other' => q(Doollarka Singabuur),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Bowndka St Helen),
				'one' => q(Bownd St Helen),
				'other' => q(SHP),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leonka Sira Leon),
				'one' => q(Leon Sira Leo),
				'other' => q(Leonka Sira Leon),
			},
		},
		'SOS' => {
			symbol => 'S',
			display_name => {
				'currency' => q(Shilingka Soomaaliya),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Doolarka Surinamees),
				'one' => q(Doolarka Surinamees),
				'other' => q(Doolarada Surinamees),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Boownka Koonfurta Suudaan),
				'one' => q(Boownka Koonfurta Suudaan),
				'other' => q(Boownanka Koonfurta Suudaan),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Dobra Sao Tome & Birinsibal),
				'one' => q(Dobra Sao Tome Birinsibal),
				'other' => q(STN),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Bowndka Suuriya),
				'one' => q(Bownd Suuriya),
				'other' => q(Bowndka Suuriya),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeenida iswasi),
				'one' => q(Lilengeeni Iswasi),
				'other' => q(Lilangeenida iswasi),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Baatka Tayland),
				'one' => q(Baat Tayland),
				'other' => q(Baatka Tayland),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoon Tajikistan),
				'one' => q(Soomon Tajikistan),
				'other' => q(Somoon Tajikistan),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manaat Turkmenistan),
				'one' => q(Manat Turkmenistan),
				'other' => q(Manaat Turkmenistan),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinaarka Tunisiya),
				'one' => q(Dinaarka Tunisiya),
				'other' => q(Dinaarka Tunisiya),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Ba’anga Tonga),
				'one' => q(Ba’anga Tonga),
				'other' => q(Ba’anga Tonga),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Liirada Turkiga),
				'one' => q(Liira Turki),
				'other' => q(Liirada Turkiga),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Doolarka Tirinad iyo Tobago),
				'one' => q(Doolarka Tirinad iyo Tobago),
				'other' => q(Doolarada Tirinad iyo Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Doollarka Taywaanta Cusubta),
				'one' => q(Doollar Taywaanta Cusub),
				'other' => q(Doollarka Taywaanta Cusubta),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Shilingka Tansaaniya),
				'one' => q(Shilin Tansaaniya),
				'other' => q(Shilingka Tansaaniya),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Hirfiniyada Yukreeyn),
				'one' => q(Hirfiniya Yukreeyn),
				'other' => q(Hirfiniyada Yukreeyn),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Shilingka Uganda),
				'one' => q(Shiling Uganda),
				'other' => q(Shilingka Uganda),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(USD),
				'one' => q(Doolarka Mareeykanka),
				'other' => q(Doolarada Mareeykanka),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Beeso Uruguay),
				'one' => q(Beeso Uruguay),
				'other' => q(Beeso Uruguay),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Soom Usbekistan),
				'one' => q(Soom Usbekistan),
				'other' => q(Soom Usbekistan),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Bolifar Fenesuala \(2008–2018\)),
				'one' => q(Bolifar Fenesuala \(2008–2018\)),
				'other' => q(Bolifar Fenesuala \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Bolifar Fenezuela),
				'one' => q(Bolifar Fenesuala),
				'other' => q(Bolifar Fenezuela),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Dong Fitnaam),
				'one' => q(Dong Fitnaam),
				'other' => q(Dong Fitnaam),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Fatu Fanuatu),
				'one' => q(Fatu Fanuatu),
				'other' => q(Fatu Fanuatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala Samao),
				'one' => q(Tala Samao),
				'other' => q(Tala Samao),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Farank CFA ee Bartamaha Afrika),
				'one' => q(Faranka CFA ee Bartamaha Afrika),
				'other' => q(Farank CFA ee Bartamaha Afrika),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Doolaraka Bariga Kaaribyan),
				'one' => q(Doolarka Bariga Kaaribyan),
				'other' => q(Doolarada Bariga Kaaribyan),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Faranka CFA Galbeedka Afrika),
				'one' => q(Farank CFA Galbeedka Afrika),
				'other' => q(XOF),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Farank CFP),
				'one' => q(Farank CFP),
				'other' => q(Farank CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Lacag aan la qoon ama aan saxnayn),
				'one' => q(Lacag aan la aqoon),
				'other' => q(Lacag aan la aqoon),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Riyaalka Yemen),
				'one' => q(Riyaal Yemen),
				'other' => q(Riyaalka Yemen),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Randka Koonfur Afrika),
				'one' => q(Rand Koonfur Afrika),
				'other' => q(Randka Koonfur Afrika),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kawajada Sambiya),
				'one' => q(Kawaja Sambiya),
				'other' => q(Kawajada Sambiya),
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
							'Kob',
							'Lab',
							'Sad',
							'Afr',
							'May',
							'Juun',
							'Luuliyo',
							'Og',
							'Sebtembar',
							'Oktoobar',
							'Nofembar',
							'Dec'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'K',
							'L',
							'S',
							'A',
							'S',
							'L',
							'T',
							'S',
							'S',
							'T',
							'K',
							'L'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Bisha Koobaad',
							'Bisha Labaad',
							'Bisha Saddexaad',
							'Bisha Afraad',
							'Bisha Shanaad',
							'Bisha Lixaad',
							'Bisha Todobaad',
							'Bisha Sideedaad',
							'Bisha Sagaalaad',
							'Bisha Tobnaad',
							'Bisha Kow iyo Tobnaad',
							'Bisha Laba iyo Tobnaad'
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
							'May',
							'Juun',
							'Luuliyo',
							'Og',
							'Seb',
							'Okt',
							'Nof',
							'Des'
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
							'L',
							'O',
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
							'Jannaayo',
							'Febraayo',
							'Maarso',
							'Abriil',
							'May',
							'Juun',
							'Luuliyo',
							'Ogost',
							'Sebtembar',
							'Oktoobar',
							'Nofembar',
							'Desembar'
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
						mon => 'Isn',
						tue => 'Tal',
						wed => 'Arb',
						thu => 'Kha',
						fri => 'Jim',
						sat => 'Sab',
						sun => 'Axd'
					},
					narrow => {
						mon => 'I',
						tue => 'T',
						wed => 'A',
						thu => 'Kh',
						fri => 'J',
						sat => 'S',
						sun => 'A'
					},
					short => {
						mon => 'Isn',
						tue => 'Tal',
						wed => 'Arb',
						thu => 'Kha',
						fri => 'Jim',
						sat => 'Sab',
						sun => 'Axd'
					},
					wide => {
						mon => 'Isniin',
						tue => 'Talaado',
						wed => 'Arbaco',
						thu => 'Khamiis',
						fri => 'Jimco',
						sat => 'Sabti',
						sun => 'Axad'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Isn',
						tue => 'Tal',
						wed => 'Arb',
						thu => 'Kha',
						fri => 'Jim',
						sat => 'Sab',
						sun => 'Axd'
					},
					narrow => {
						mon => 'I',
						tue => 'T',
						wed => 'A',
						thu => 'Kh',
						fri => 'J',
						sat => 'S',
						sun => 'A'
					},
					short => {
						mon => 'Isn',
						tue => 'Tal',
						wed => 'Arb',
						thu => 'Kha',
						fri => 'Jim',
						sat => 'Sab',
						sun => 'Axd'
					},
					wide => {
						mon => 'Isniin',
						tue => 'Talaado',
						wed => 'Arbaco',
						thu => 'Khamiis',
						fri => 'Jimco',
						sat => 'Sabti',
						sun => 'Axad'
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
					abbreviated => {0 => 'R1',
						1 => 'R2',
						2 => 'R3',
						3 => 'R4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Rubaca 1aad',
						1 => 'Rubaca 2aad',
						2 => 'Rubaca 3aad',
						3 => 'Rubaca 4aad'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'R1',
						1 => 'R2',
						2 => 'R3',
						3 => 'R4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Rubaca 1aad',
						1 => 'Rubaca 2aad',
						2 => 'Rubaca 3aad',
						3 => 'Rubaca 4aad'
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
					'am' => q{sn.},
					'pm' => q{gn.},
				},
				'narrow' => {
					'am' => q{sn.},
					'pm' => q{gn.},
				},
				'wide' => {
					'am' => q{sn.},
					'pm' => q{gn.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{sn.},
					'pm' => q{gn.},
				},
				'narrow' => {
					'am' => q{sn.},
					'pm' => q{gn.},
				},
				'wide' => {
					'am' => q{sn.},
					'pm' => q{gn.},
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
				'0' => 'CK',
				'1' => 'CD'
			},
			wide => {
				'0' => 'CK',
				'1' => 'CD'
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
			'full' => q{G y MMMM d, EEEE},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM dd, y},
			'long' => q{dd MMMM y},
			'medium' => q{dd-MMM-y},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{G y},
			yyyyM => q{GGGGG y-MM},
			yyyyMEd => q{GGGGG y-MM-dd, E},
			yyyyMMM => q{G y MMM},
			yyyyMMMEd => q{G y MMM d, E},
			yyyyMMMM => q{G y MMMM},
			yyyyMMMd => q{G y MMM d},
			yyyyMd => q{GGGGG y-MM-dd},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
		},
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
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMW => q{'usbuuc' W 'ee' MMMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'Usbuuca' w 'ee' Y},
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
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, dd – E, dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
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
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM dd – E, MMM dd, y},
				d => q{E, MMM dd – E, MMM dd, y},
				y => q{E, MMM dd, y – E, MMM dd, y},
			},
			yMMMM => {
				M => q{G y MMMM–MMMM},
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd–dd MMM y},
				y => q{dd MMM y – dd MMM y},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
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
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, dd – E, dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM dd – E, MMM dd, y},
				d => q{E, MMM dd – E, MMM dd, y},
				y => q{E, MMM dd, y – E, MMM dd, y},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd–dd MMM y},
				y => q{dd MMM y – dd MMM y},
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
		regionFormat => q({0} Waqtiga),
		regionFormat => q({0} Waqtiga Dharaarta),
		regionFormat => q({0} Waqtiga Caadiga ah),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Waqtiga Afqanistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjaan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljeeris#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Caasmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamaako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjui#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Balantire#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Barasafil#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Qaahira#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasabalaanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daresalaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douaala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Ceyuun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Firiitawn#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gabroon#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Haraare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johansbaag#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kambaala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartuum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librefil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Loom#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseero#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Muqdisho#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrofiya#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nookjot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Boorto-Noofo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhook#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Waqtiga Bartamaha Afrika#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Waqtiga Bariga Afrika#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Waqtiyada Caadiga ah ee Koonfur Afrika#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Galbeedka Afrika#,
				'generic' => q#Waqtiga Galbeedka Afrika#,
				'standard' => q#Waqtiyada Caadiga ah ee Galbeedka Afrika#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Alaska#,
				'generic' => q#Waqtiga Alaska#,
				'standard' => q#Waqtiga Caadiga ah ee Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Amason#,
				'generic' => q#Waqtiga Amason#,
				'standard' => q#Waqtiga Istandarka ee Amason#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anjorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuumaan#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaay#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunkion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baahiya#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahiya Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Beliise#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Balank-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Bow Fista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Boys#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Boonas Ayris#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kambriij Baay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kaambo Carande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kaankuun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakaas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamaarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayeen#,
		},
		'America/Cayman' => {
			exemplarCity => q#Keymaan#,
		},
		'America/Chicago' => {
			exemplarCity => q#Jikaago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Jiwaahuu#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokaan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordooba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Riika#,
		},
		'America/Creston' => {
			exemplarCity => q#Karestoon#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuiaaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurakao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Daanmaakshaan#,
		},
		'America/Dawson' => {
			exemplarCity => q#Doosan#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Doosan Kireek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denfar#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroyt#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Iiruneeb#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salfadoor#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Foot Nelsoon#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Footalesa#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Galeys Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Guus Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Garaand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Garenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeluub#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemaala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyaana#,
		},
		'America/Halifax' => {
			exemplarCity => q#HaliFakis#,
		},
		'America/Havana' => {
			exemplarCity => q#Hafaana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Harmosilo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Nokis, Indiaana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Mareengo, Indiaana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Betesbaag, Indiaana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Teel Siti Indiaana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Feefaay\, Indiaana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Finseenes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winaamak, Indiaana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indaanboolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuufik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaaluut#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaaika#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juniyuu#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montiseelo, Kentaki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kiraalendik#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Laa Baas#,
		},
		'America/Lima' => {
			exemplarCity => q#Liima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luuisfil#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Loowa Birinses Kuwaata#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maasiiyo#,
		},
		'America/Managua' => {
			exemplarCity => q#Manaaguwa#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaauus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Maarigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Maartiniik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Mataamooris#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazaatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Meendoosa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menoominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Meriida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlaakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksiko Sity#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miiquulon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moonktoon#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Moonteerey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Moontafiidiyo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Moontseraat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasaaw#,
		},
		'America/New_York' => {
			exemplarCity => q#Niyuu Yook#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nibiigoon#,
		},
		'America/Nome' => {
			exemplarCity => q#Noom#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noroonha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Biyuulah, Waqooyiga DaKoota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Bartamaha, Waqooyiga Dakoota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Niyuu Saalem, Waqooyiga Dakoota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Baanama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Paangnirtuung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Baramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Fooniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Dekadda Wiilka Boqorka#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Dekadda Isbeyn#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Pooro Felho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Boorta Riiko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arinaas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Reyni River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Raankin Inleet#,
		},
		'America/Recife' => {
			exemplarCity => q#Receyf#,
		},
		'America/Regina' => {
			exemplarCity => q#Rejiina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resoluut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Riyo Baraanko#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santareem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiyaago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Saanto Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Saaw Boolo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itoqortoomiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Siitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Baartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. Joon#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lusia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Toomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Finsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Iswift Karent#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalba#,
		},
		'America/Thule' => {
			exemplarCity => q#Tuul#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tanda Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuaana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Fankuufar#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Farascad#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winibeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutaat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yelowneyf#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Bartamaha#,
				'generic' => q#Waqtiga Bartamaha#,
				'standard' => q#Waqtiga Caadiga ah ee Bartamaha#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Bariga#,
				'generic' => q#Waqtiga Bariga#,
				'standard' => q#Waqtiga Caadiga ah ee Bariga#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Buurleyda#,
				'generic' => q#Waqtiga Buuraleyda#,
				'standard' => q#Waqtiga Caadiga ah ee Buuraleyda#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Basifika#,
				'generic' => q#Waqtiga Basifika#,
				'standard' => q#Waqtiga Caadiga ah ee Basifika#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Keysee#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Dafis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’urfile#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makquariy#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#MakMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Baamar#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Siyowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Torool#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Fostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Waqtiayda Dharaarta ee Abiya#,
				'generic' => q#Waqtiga Abiya#,
				'standard' => q#Waqtiyada Caadiga ah ee Abiya#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Carabta#,
				'generic' => q#Waqtiga Carabta#,
				'standard' => q#Waqtiyada Caadiga ah ee Carabta#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Arjentiina#,
				'generic' => q#Waqtia Arjentiina#,
				'standard' => q#Waqtiga istaandarka ee Arjentiina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Galbeedka Arjentiina#,
				'generic' => q#Waqtiga Galbeedka Arjentiina#,
				'standard' => q#Waqtiyada Caadiga ah ee Arjentiina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Armeniya#,
				'generic' => q#Waqtiga Armeniya#,
				'standard' => q#Waqtiyada Caadiga ah ee Armeniya#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Cadan#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadiyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktaw#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atiyraw#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baqdaad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Baxreyn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaauul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beyrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Buruney#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Kiita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Joybalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Dimishiq#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubay#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gasa#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hofud#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayabura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamkatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaaji#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandiyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Karasnoyarska#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lambuur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kujing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuweyt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makaw#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiya#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nofokusnetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nofosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Foonom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Botiyaanak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Boyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qiyslorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Caasimada Hoo Ji Mih#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Sool#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghaay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singabuur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Sarednokoleymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Teybey#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timfu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Viyaantiyaan#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Faladifostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinbaag#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerefan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Atlantik#,
				'generic' => q#Waqtiga Atlantik#,
				'standard' => q#Waqtiga Istaandarka ee Atlantik#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Barmuuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Keyb Faarde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjafik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Koonfurta Joorgiya#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Istaanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Birisban#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Boroken Hil#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kuriy#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Yukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melboon#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Bert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Bartamaha Astaraaliya#,
				'generic' => q#Waqtiga Bartamaha Astaraaliya#,
				'standard' => q#Waqtiyada Caadiga ah ee Bartamaha Astaraaliya#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta Bartamaha Galbeedka Australiya#,
				'generic' => q#Waqtiga Bartamaha Galbeedka Astaraaliya#,
				'standard' => q#Waqtiyada Caadiga ah ee Bartamaha Galbeedka Astaraaliya#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Bariga Australiya#,
				'generic' => q#Waqtiga Bariga Australiya#,
				'standard' => q#Waqtiyada Caadiga ah ee Bariga Australiya#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Galbeedka Australiya#,
				'generic' => q#Waqtiga Galbeedka Australiya#,
				'standard' => q#Waqtiyada Caadiga ah ee Galbeedka Australiya#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Asarbeyjan#,
				'generic' => q#Waqtiga Asarbeyjan#,
				'standard' => q#Waqtiyada Caadiga ah ee Asarbeyjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Asores#,
				'generic' => q#Waqtiga Asores#,
				'standard' => q#Waqtiyada Caadiga ah ee Asores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Bangledeesh#,
				'generic' => q#Waqtiga Bangledeesh#,
				'standard' => q#Waqtiyada Caadiga ah ee Bangledeesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Waqtiga Futan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Waqtiga Boliifiya#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Baraasiliya#,
				'generic' => q#Waqtiga Baraasiliya#,
				'standard' => q#Waqtiga Caadiga ah ee Baraasiliya#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Waqtiga Buruney Daarusalaam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Keyb Faarde#,
				'generic' => q#Waqtiga Keyb Faarde#,
				'standard' => q#Waqtiyada Caadiga ah ee Keyb Faarde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Waqtiyada Caadiga ah ee Jamoro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Jaatam#,
				'generic' => q#Waqtiga Jaatam#,
				'standard' => q#Waqtiyada Caadiga ah ee Jaatam#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Jili#,
				'generic' => q#Waqtiga Jili#,
				'standard' => q#Waqtiyada Caadiga ah ee Jili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Shiinaha#,
				'generic' => q#Waqtiga Shiinaha#,
				'standard' => q#Waqtiyada Caadiga ah ee Shiinaha#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga Joybalsan#,
				'generic' => q#Waqtiga Joybalsan#,
				'standard' => q#Waqtiyada Caadiga ah ee Joybalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Waqtiga Kirismas Island#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Waqtiga Kokos Island#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga Kolambiya#,
				'generic' => q#Waqtiga Kolambiya#,
				'standard' => q#Waqtiyada Caadiga ah ee kolambiya#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#waqtiga nus xagaaga ah ee jasiiradha cook#,
				'generic' => q#waqtiga jasiiradaha cook#,
				'standard' => q#waqtiga caadiga ah jasiiradaha cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Kuuba#,
				'generic' => q#Waqtiga Kuuba#,
				'standard' => q#Waqtiga Istaandarka ee Kuuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Waqtiga Dafis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Waqtiga Dumont - d’urfille#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Waqtiga East Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Bariga Island#,
				'generic' => q#Waqtiga Bariga Island#,
				'standard' => q#Waqtiyada Caadiga ah ee Bariga Island#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Waqtiga Ekuwador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Waqtiga iskuxiran ee caalamka#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Magaalo aan la garanayn#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astarakhaan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Barliin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Baratislafa#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Barasals#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bujarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budabest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Jisinaau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kobenhaagan#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Waqtiyada Caadiga ah ee Irishka#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isle of Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jaarsey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiyf#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kiroof#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#Landan#,
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Biritishka#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksembaaga#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskow#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Bariis#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Bodgorika#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Paraag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riija#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rooma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayeefo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratoof#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferobol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Iskoobje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofiya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Istokhoom#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanofsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Usgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Faduus#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Fatikaan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Fiyaana#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Filnuus#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Folgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsaw#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Sagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saborosey#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Surij#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Bartamaha Yurub#,
				'generic' => q#Waqtiga Bartamaha Yurub#,
				'standard' => q#Waqtiyada Caadiga ah ee Bartamaha Yurub#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Bariga Yurub#,
				'generic' => q#Waqtiga Bariga Yurub#,
				'standard' => q#Waqtiyada Caadiga ah ee Bariga Yurub#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Waqtiga Bariga fog ee Yurub#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Galbeedka Yurub#,
				'generic' => q#Waqtiga Galbeedka Yurub#,
				'standard' => q#Waqtiyada Caadiga ah ee Galbeedka Yurub#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Faalkland Island#,
				'generic' => q#Waqtiga Faalkland Islands#,
				'standard' => q#Waqtiyada Caadiga ah ee Faalkland Islands#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Fiji#,
				'generic' => q#Waqtiga Fiji#,
				'standard' => q#Waqtiyada Caadiga ah ee Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Waqtiga French Guiana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Waqtiga Koonfurta Faransiiska & Antaarktik#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Waqtiga Celceliska Giriinwij#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Waqtiga Galabagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Waqtiga Gambiyar#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Joorjiya#,
				'generic' => q#Waqtiga Joorjiya#,
				'standard' => q#Waqtiyada Caadiga ah ee Joorjiya#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Waqtiga Gilbart Island#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Waqtiga Istaandarda ee Dhulka cagaaran#,
				'generic' => q#Waqtiga Bariga Dhulka Cagaaran#,
				'standard' => q#Waqtiga Istaandarka ee Bariga Dhulka cagaaran#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Dhulka cagaaran#,
				'generic' => q#Waqtiga Galbeedka Dhulka cagaaran#,
				'standard' => q#Waqtiga Istaandarka ee Galbeedka Dhulka cagaaran#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Waqtiyada Caadiga ah ee Gacanka#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Waqtiga Guyaana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Hawaii=Alutin#,
				'generic' => q#Waqtiga Hawaii-Alutin#,
				'standard' => q#Waqtiga Istaandarka Hawaii-Alutin#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Hong Kong#,
				'generic' => q#Waqtiga Hong Kong#,
				'standard' => q#Waqtiyada Caadiga ah ee Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Hofud#,
				'generic' => q#Waqtiga Hofd#,
				'standard' => q#Waqtiyada Caadiga ah ee Hofud#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Waqtiyada Caadiga ah ee Hindiya#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarifo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Jagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Kiristmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldifis#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Morishiyaas#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayote#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Waqtiga badweynta Hindiya#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Waqtiga Indoshiina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Waqtiga Bartamaha Indoneysiya#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Waqtiga Indoneysiya#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Waqtiga Galbeedka Indoneysiya#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Iran#,
				'generic' => q#Waqtiga Iran#,
				'standard' => q#Waqtiyada Caadiga ah ee Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Irkutsk#,
				'generic' => q#Waqtiga Irkutsk#,
				'standard' => q#Waqtiyada Caadiga ah ee Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Israaiil#,
				'generic' => q#Waqtiga Israaiil#,
				'standard' => q#Waqtiyada Caadiga ah ee Israaiil#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Jabaan#,
				'generic' => q#Waqtiga Jabaan#,
				'standard' => q#Waqtiyada Caadiga ah ee Jabaan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Waqtiga Bariga Kasakhistaan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Waqtiga Koonfurta Kasakhistan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Kuuriya#,
				'generic' => q#Waqtiga Kuuriya#,
				'standard' => q#Waqtiyada Caadiga ah ee Kuuriya#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Waqtiga Kosriy#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Karasnoyarsk#,
				'generic' => q#Waqtiga Karasnoyarsk#,
				'standard' => q#Waqtiyada Caadiga ah ee Karasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Waqtiga Kiyrgistaan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Waqtiga Leyn Island#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Lord Howe#,
				'generic' => q#Waqtiga LOrd Howe#,
				'standard' => q#Waqtiyada Caadiga ah ee Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#waqtiga jaziirada makquariye#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Magadan#,
				'generic' => q#Watiga Magadan#,
				'standard' => q#Waqtiyada Caadiga ah ee Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Waqtiga Maleyshiya#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Waqtiga Maldifis#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Waqtiga Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#waqtiga jasiiradaha marshal#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Morishiyaas#,
				'generic' => q#Waqtiga Morishiyaas#,
				'standard' => q#Waqtiyada Caadiga ah ee Morishiyaas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Waqtiga Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Waqooyigalbeed Meksiko#,
				'generic' => q#Waqtiga Waqooyi-Galbeed ee Meksiko#,
				'standard' => q#waqtiga Istandardka ee waqooyi galbeet meksiko#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Baasifikada Meksiko#,
				'generic' => q#Waqtiga Baasifikada Meksiko#,
				'standard' => q#waqtiga standardka Baasifikada Meksiko#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Ulaanbaataar#,
				'generic' => q#Waqtiga Ulaanbaataar#,
				'standard' => q#Waqtiyada Caadiga ah ee Ulaanbaataar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Moskow#,
				'generic' => q#Waqtiga Moskow#,
				'standard' => q#Waqtiyada Caadiga ah ee Moskow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Waqtiga Mayanmaar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Waqtiga Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Waqtiga Nebal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Niyuu Kaledoniya#,
				'generic' => q#Waqtiga Niyuu Kaledonya#,
				'standard' => q#Waqtiyada Caadiga ah ee Niyuu Kaledoniya#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Niyuu Si’aland#,
				'generic' => q#Waqtiga Niyuu Si’land#,
				'standard' => q#Waqtiyada Caadiga ah ee Niyuu si’lan#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Newfoundland#,
				'generic' => q#Waqtiga Newfoundland#,
				'standard' => q#Waqtiga Istaandarka ee Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Waqtiga Niyuu#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Waqtiga Norfoolk Island#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Farnaando de Noronho#,
				'generic' => q#Waqtiga Farnaando de Noronho#,
				'standard' => q#Waqtiyada Caadiga ah ee Farnaando de Noronho#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Nofosibirsk#,
				'generic' => q#Waqtiga Nofosibirsk#,
				'standard' => q#Waqtiyada Caadiga ah ee Nofosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Omsk#,
				'generic' => q#Waqtiga Omsk#,
				'standard' => q#Waqtiyada Caadiga ah ee Omsk#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Abiya#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Okland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Boogaynfil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Jatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Bariga#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galabagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambiyr#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Cuadalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Joonston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimaati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrii#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kuwajaleyn#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niyuu#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Noorfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noomiya#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Bago Bago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Balaw#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Bitkayrn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Bonbey#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Boort Moresbi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Seyban#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatabu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Juuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Walis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Bakistan#,
				'generic' => q#Waqtiga Bakistan#,
				'standard' => q#Waqtiyada Caadiga ah ee Bakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Waqtiga Balaw#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Waqtiga Babua Niyuu Giniya#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Baragway#,
				'generic' => q#Waqtiga Baragway#,
				'standard' => q#Waqtiyada Caadiga ah ee Baragway#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Beeru#,
				'generic' => q#Waqtiga Beeru#,
				'standard' => q#Waqtiyada Caadiga ah ee Beeru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Filibin#,
				'generic' => q#Waqtiga Filibin#,
				'standard' => q#Waqtiyada Caadiga ah ee Filibin#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#waqtiga jasiirada fonikis#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee St. Pierre & Miquelon#,
				'generic' => q#Waqtiga St. Pierre & Miquelon#,
				'standard' => q#Waqtiga Istaandarka ee St. Pierre & Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Waqtiga Bitkairin#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Waqtiga Bonabe#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Waqtiga Boyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Waqtiga Riyunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Waqtiga Rotera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Sakhalin#,
				'generic' => q#Waqtiga Sakhalin#,
				'standard' => q#Waqtiyada Caadiga ah ee Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Samoa#,
				'generic' => q#Waqtiga Samoa#,
				'standard' => q#Waqtiyada Caadiga ah ee Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Waqtiga Siisalis#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Waqtiyada Caadiga ah ee Singabuur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#waqtiga jasiirada solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Waqtiga Koonfurta Jorjiya#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Waqtiga Surineym#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Waqtiga Siyowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Waqtiga Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Waqtiyada Dharaarta ee Teybey#,
				'generic' => q#Waqtiga Teybey#,
				'standard' => q#Waqtiyada Caadiga ah ee Teybey#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Waqtiga Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Waqtiga Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Tonga#,
				'generic' => q#Waqtiga Tonga#,
				'standard' => q#Waqtiyada Caadiga ah ee Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Waqtiga Juuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Waqtiayda Xagaaga ee Turkmenistan#,
				'generic' => q#Waqtiga Turkenistaan#,
				'standard' => q#Waqtiyada Caadiga ah ee Turkeminstan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Waqtiga Tufalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Urugway#,
				'generic' => q#Waqtiga Urugway#,
				'standard' => q#Waqtiyada Caadiga ah ee Urugway#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Usbekistan#,
				'generic' => q#Waqtiga Usbekistan#,
				'standard' => q#Waqtiyada Caadiga ah ee Usbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Fanautu#,
				'generic' => q#Waqtiga Fanuatu#,
				'standard' => q#Waqtiyada Caadiga ah ee Fanautu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Waqtiga Fenezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Faladifostok#,
				'generic' => q#Waqtiga Faladifostok#,
				'standard' => q#Waqtiyada Caadiga ah ee Faladifostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Folgograd#,
				'generic' => q#Waqtiga Folgograd#,
				'standard' => q#Waqtiyada Caadiga ah ee Folgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Waqtiga Fostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Waqtiga jasiirada wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Waqtiga Walis & Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Yakutsk#,
				'generic' => q#Waqtiyada Yakutsk#,
				'standard' => q#Waqtiyada Caadiga ah ee Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga ee Yekaterinbaag#,
				'generic' => q#Waqtiga Yekaterinbaag#,
				'standard' => q#Waqtiyada Caadiga ah ee Yekaterinbaag#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
