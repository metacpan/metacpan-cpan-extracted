=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Jv - Package for language Javanese

=cut

package Locale::CLDR::Locales::Jv;
# This file auto generated from Data\common\main\jv.xml
#	on Fri 13 Oct  9:22:22 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
				'af' => 'af',
 				'ar' => 'Arab',
 				'ar_001' => 'Arab Standar Anyar',
 				'ban' => 'ban',
 				'be' => 'be',
 				'bn' => 'Bengali',
 				'bs' => 'bs',
 				'co' => 'Korsika',
 				'de' => 'Jérman',
 				'en' => 'Inggris',
 				'en_GB@alt=short' => 'Inggris (Britania)',
 				'en_US@alt=short' => 'Inggris (AS)',
 				'es' => 'Spanyol',
 				'es_419' => 'Spanyol (Amerika Latin)',
 				'es_ES' => 'Spanyol (Eropah)',
 				'es_MX' => 'Spanyol (Meksiko)',
 				'fr' => 'Prancis',
 				'hi' => 'India',
 				'id' => 'Indonesia',
 				'it' => 'Italia',
 				'ja' => 'Jepang',
 				'jv' => 'Jawa',
 				'ko' => 'Korea',
 				'nl' => 'Walanda',
 				'nl_BE' => 'Flemis',
 				'pl' => 'Polandia',
 				'pt' => 'Portugis',
 				'ru' => 'Rusia',
 				'th' => 'Thailand',
 				'tr' => 'Turki',
 				'und' => 'Basa Ora Dikenali',
 				'zh' => 'Tyonghwa',
 				'zh_Hans' => 'Tyonghwa (Gampang)',
 				'zh_Hant' => 'Tyonghwa (Tradisional)',

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
			'Arab' => 'Arab',
 			'Cyrl' => 'Sirilik',
 			'Hani' => 'Han',
 			'Hans' => 'Prasaja',
 			'Hans@alt=stand-alone' => 'Han Prasaja',
 			'Hant' => 'Tradhisional',
 			'Hant@alt=stand-alone' => 'Han Tradhisional',
 			'Jpan' => 'Jepang',
 			'Kore' => 'Korea',
 			'Latn' => 'Latin',
 			'Zxxx' => 'Ora Ketulis',
 			'Zzzz' => 'Skrip Ora Dikenali',

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
			'001' => 'Donya',
 			'002' => 'Afrika',
 			'003' => 'Amérika Lèr',
 			'005' => 'Amérika Kidul',
 			'009' => 'Oséania',
 			'011' => 'Afrika Kulon',
 			'013' => 'Amérika Tengah',
 			'014' => 'Afrika Wétan',
 			'015' => 'Afrika Lèr',
 			'017' => 'Afrika Sisih Tengah',
 			'018' => 'Afrika Sisih Kidul',
 			'019' => 'Amérika',
 			'021' => 'Amérika Sisih Lor',
 			'029' => 'Karibia',
 			'030' => 'Asia Wétan',
 			'034' => 'Asia Kidul',
 			'035' => 'Asia Kidul-wétan',
 			'039' => 'Éropah Kidul',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Daerah Mikronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Tengah',
 			'145' => 'Asia Kulon',
 			'150' => 'Éropah',
 			'151' => 'Éropah Wétan',
 			'154' => 'Éropah Lèr',
 			'155' => 'Éropah Kulon',
 			'202' => 'Afrika Kidule Sahara',
 			'419' => 'Amérika Latin',
 			'AC' => 'Pulo Ascension',
 			'AD' => 'Andora',
 			'AE' => 'Uni Émirat Arab',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua lan Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albani',
 			'AM' => 'Arménia',
 			'AO' => 'Angola',
 			'AQ' => 'Antartika',
 			'AR' => 'Argèntina',
 			'AS' => 'Samoa Amerika',
 			'AT' => 'Ostenrik',
 			'AU' => 'Ostrali',
 			'AW' => 'Aruba',
 			'AX' => 'Kapuloan Alan',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia lan Hèrségovina',
 			'BB' => 'Barbadhos',
 			'BD' => 'Banggaladésa',
 			'BE' => 'Bèlgi',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgari',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Bénin',
 			'BL' => 'Saint Barthélémi',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunéi',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karibia Walanda',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Pulo Bovèt',
 			'BW' => 'Botswana',
 			'BY' => 'Bélarus',
 			'BZ' => 'Bélisé',
 			'CA' => 'Kanada',
 			'CC' => 'Kapuloan Cocos (Keeling)',
 			'CD' => 'Kongo - Kinshasa',
 			'CD@alt=variant' => 'Républik Dhémokratik Kongo',
 			'CF' => 'Républik Afrika Tengah',
 			'CG' => 'Kongo - Brassaville',
 			'CG@alt=variant' => 'Républik Kongo',
 			'CH' => 'Switserlan',
 			'CI' => 'Pasisir Gadhing',
 			'CK' => 'Kapuloan Cook',
 			'CL' => 'Cilé',
 			'CM' => 'Kamerun',
 			'CN' => 'Tyongkok',
 			'CO' => 'Kolombia',
 			'CP' => 'Pulo Clipperton',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Pongol Verdé',
 			'CW' => 'Kurasao',
 			'CX' => 'Pulo Natal',
 			'CY' => 'Siprus',
 			'CZ' => 'Céko',
 			'CZ@alt=variant' => 'Républik Céko',
 			'DE' => 'Jérman',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Dhènemarken',
 			'DM' => 'Dominika',
 			'DO' => 'Républik Dominika',
 			'DZ' => 'Aljasair',
 			'EA' => 'Séuta lan Melila',
 			'EC' => 'Ékuadhor',
 			'EE' => 'Éstonia',
 			'EG' => 'Mesir',
 			'EH' => 'Sahara Kulon',
 			'ER' => 'Éritréa',
 			'ES' => 'Sepanyol',
 			'ET' => 'Étiopia',
 			'EU' => 'Uni Éropah',
 			'EZ' => 'Zona Éuro',
 			'FI' => 'Finlan',
 			'FJ' => 'Fiji',
 			'FK' => 'Kapuloan Falkland',
 			'FK@alt=variant' => 'Kapuloan Falkland (Islas Malvinas)',
 			'FM' => 'Féderasi Mikronésia',
 			'FO' => 'Kapuloan Faro',
 			'FR' => 'Prancis',
 			'GA' => 'Gabon',
 			'GB' => 'Karajan Manunggal',
 			'GB@alt=short' => 'KM',
 			'GD' => 'Grénada',
 			'GE' => 'Géorgia',
 			'GF' => 'Guyana Prancis',
 			'GG' => 'Guernsei',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grinland',
 			'GM' => 'Gambia',
 			'GN' => 'Gini',
 			'GP' => 'Guadélup',
 			'GQ' => 'Guinéa Katulistiwa',
 			'GR' => 'Grikenlan',
 			'GS' => 'Georgia Kidul lan Kapuloan Sandwich Kidul',
 			'GT' => 'Guatémala',
 			'GU' => 'Guam',
 			'GW' => 'Gini-Bisau',
 			'GY' => 'Guyana',
 			'HK' => 'Laladan Administratif Astamiwa Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Kapuloan Heard lan McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Kroasia',
 			'HT' => 'Haiti',
 			'HU' => 'Honggari',
 			'IC' => 'Kapuloan Kanari',
 			'ID' => 'Indonésia',
 			'IE' => 'Républik Irlan',
 			'IL' => 'Israèl',
 			'IM' => 'Pulo Man',
 			'IN' => 'Indhi',
 			'IO' => 'Wilayah Inggris nang Segoro Hindia',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Èslan',
 			'IT' => 'Itali',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Yordania',
 			'JP' => 'Jepang',
 			'KE' => 'Kénya',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kamboja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Saint Kits lan Nèvis',
 			'KP' => 'Koréa Lèr',
 			'KR' => 'Koréa Kidul',
 			'KW' => 'Kuwait',
 			'KY' => 'Kapuloan Kéman',
 			'KZ' => 'Kasakstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Santa Lusia',
 			'LI' => 'Liktenstén',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libèria',
 			'LS' => 'Lésotho',
 			'LT' => 'Litowen',
 			'LU' => 'Luksemburg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Montenégro',
 			'MF' => 'Santa Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Kapuloan Marshall',
 			'MK' => 'Makédonia',
 			'MK@alt=variant' => 'Républik Makédonia Lor',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Laladan Administratif Astamiwa Makau',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Kapuloan Mariana Lor',
 			'MQ' => 'Martinik',
 			'MR' => 'Mauritania',
 			'MS' => 'Monsérat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maladéwa',
 			'MW' => 'Malawi',
 			'MX' => 'Mèksiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Kalédonia Anyar',
 			'NE' => 'Nigér',
 			'NF' => 'Pulo Norfolk',
 			'NG' => 'Nigéria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Walanda',
 			'NO' => 'Nurwègen',
 			'NP' => 'Népal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Niu Sélan',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia Prancis',
 			'PG' => 'Papua Nugini',
 			'PH' => 'Pilipina',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Saint Pièr lan Mikuélon',
 			'PN' => 'Kapuloan Pitcairn',
 			'PR' => 'Puèrto Riko',
 			'PS' => 'Tlatah Palèstina',
 			'PS@alt=short' => 'Palèstina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Oseania Paling Njaba',
 			'RE' => 'Réunion',
 			'RO' => 'Ruméni',
 			'RS' => 'Sèrbi',
 			'RU' => 'Rusia',
 			'RW' => 'Rwanda',
 			'SA' => 'Arab Saudi',
 			'SB' => 'Kapuloan Suleman',
 			'SC' => 'Sésèl',
 			'SD' => 'Sudan',
 			'SE' => 'Swèdhen',
 			'SG' => 'Singapura',
 			'SH' => 'Saint Héléna',
 			'SI' => 'Slovénia',
 			'SJ' => 'Svalbard lan Jan Mayen',
 			'SK' => 'Slowak',
 			'SL' => 'Siéra Léoné',
 			'SM' => 'San Marino',
 			'SN' => 'Sénégal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan Kidul',
 			'ST' => 'Sao Tomé lan Principé',
 			'SV' => 'Èl Salvador',
 			'SX' => 'Sint Martén',
 			'SY' => 'Suriah',
 			'SZ' => 'Swasiland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks lan Kapuloan Kaikos',
 			'TD' => 'Chad',
 			'TF' => 'Wilayah Prancis nang Kutub Kidul',
 			'TG' => 'Togo',
 			'TH' => 'Tanah Thai',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Leste',
 			'TL@alt=variant' => 'Timor Wétan',
 			'TM' => 'Turkménistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TT' => 'Trinidad lan Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukrania',
 			'UG' => 'Uganda',
 			'UM' => 'Kapuloan A.S. Paling Njobo',
 			'UN' => 'Pasarékatan Bangsa-Bangsa',
 			'US' => 'Amérika Sarékat',
 			'US@alt=short' => 'AS',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbèkistan',
 			'VA' => 'Kutho Vatikan',
 			'VC' => 'Saint Vinsen lan Grénadin',
 			'VE' => 'Vénésuéla',
 			'VG' => 'Kapuloan Virgin Britania',
 			'VI' => 'Kapuloan Virgin Amérika',
 			'VN' => 'Viètnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis lan Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika Kidul',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Daerah Ora Dikenali',

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
 				'gregorian' => q{Tanggalan Gregorian},
 				'iso8601' => q{Tanggalan ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{Standar Ngurutke Urutan},
 			},
 			'numbers' => {
 				'latn' => q{Digit Latin},
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
 			'UK' => q{BR},
 			'US' => q{AS},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Basa: {0}',
 			'script' => 'Skrip: {0}',
 			'region' => 'Daerah: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'top-to-bottom',
			characters => 'left-to-right',
		}}
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
			auxiliary => qr{[f q v x z]},
			index => ['A', 'Â', 'Å', 'B', 'C', 'D', 'E', 'É', 'È', 'Ê', 'G', 'H', 'I', 'Ì', 'J', 'K', 'L', 'M', 'N', 'O', 'Ò', 'P', 'R', 'S', 'T', 'U', 'Ù', 'W', 'Y'],
			main => qr{[a â å b c d e é è ê g h i ì j k l m n o ò p r s t u ù w y]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- , ; \: ! ? . ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Â', 'Å', 'B', 'C', 'D', 'E', 'É', 'È', 'Ê', 'G', 'H', 'I', 'Ì', 'J', 'K', 'L', 'M', 'N', 'O', 'Ò', 'P', 'R', 'S', 'T', 'U', 'Ù', 'W', 'Y'], };
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
						'name' => q(arah kardinal),
					},
					'acre' => {
						'name' => q(are),
						'other' => q({0} are),
					},
					'acre-foot' => {
						'name' => q(are-kaki),
						'other' => q({0} are-kaki),
					},
					'ampere' => {
						'name' => q(amper),
						'other' => q({0} amper),
					},
					'arc-minute' => {
						'name' => q(menit saka busur),
						'other' => q({0} menit saka busur),
					},
					'arc-second' => {
						'name' => q(detik saka busur),
						'other' => q({0} detik saka busur),
					},
					'astronomical-unit' => {
						'name' => q(unit astronomi),
						'other' => q({0} unit astronomi),
					},
					'atmosphere' => {
						'name' => q(atmosfer),
						'other' => q({0} atmosfer),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bite),
						'other' => q({0} bite),
					},
					'calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					'carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(derajat celsius),
						'other' => q({0} derajat celsius),
					},
					'centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} saben sentimeter),
					},
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					'cubic-centimeter' => {
						'name' => q(sentimeter kubik),
						'other' => q({0} sentimeter kubik),
						'per' => q({0} saben sentimeter kubik),
					},
					'cubic-foot' => {
						'name' => q(kaki kubik),
						'other' => q({0} kaki kubik),
					},
					'cubic-inch' => {
						'name' => q(inci kubik),
						'other' => q({0} inci kubik),
					},
					'cubic-kilometer' => {
						'name' => q(kilometer kubik),
						'other' => q({0} kilometer kubik),
					},
					'cubic-meter' => {
						'name' => q(meter kubik),
						'other' => q({0} meter kubik),
						'per' => q({0} saben meter kubik),
					},
					'cubic-mile' => {
						'name' => q(mil kubik),
						'other' => q({0} mil kubik),
					},
					'cubic-yard' => {
						'name' => q(yard kubik),
						'other' => q({0} yard kubik),
					},
					'cup' => {
						'name' => q(kup),
						'other' => q({0} kup),
					},
					'cup-metric' => {
						'name' => q(metrik kup),
						'other' => q({0} metrik kup),
					},
					'day' => {
						'name' => q(dino),
						'other' => q({0} dino),
						'per' => q({0} saben dino),
					},
					'deciliter' => {
						'name' => q(desiliter),
						'other' => q({0} desiliter),
					},
					'decimeter' => {
						'name' => q(desimeter),
						'other' => q({0} desimeter),
					},
					'degree' => {
						'name' => q(derajat),
						'other' => q({0} derajat),
					},
					'fahrenheit' => {
						'name' => q(derajat Fahrenhet),
						'other' => q({0} derajat Fahrenhet),
					},
					'fluid-ounce' => {
						'name' => q(ons banyu),
						'other' => q({0} ons banyu),
					},
					'foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0} saben kaki),
					},
					'g-force' => {
						'name' => q(tenaga-g),
						'other' => q({0} tenaga-g),
					},
					'gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0} saben galon),
					},
					'gallon-imperial' => {
						'name' => q(galon inggris),
						'other' => q({0} galon inggris),
						'per' => q({0} saben galon inggris),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					'gigabyte' => {
						'name' => q(gigabite),
						'other' => q({0} gigabite),
					},
					'gigahertz' => {
						'name' => q(gigahet),
						'other' => q({0} gigahet),
					},
					'gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					'gram' => {
						'name' => q(gram),
						'other' => q({0} gram),
						'per' => q({0} saben gram),
					},
					'hectare' => {
						'name' => q(hektar),
						'other' => q({0} hektar),
					},
					'hectoliter' => {
						'name' => q(hektoliter),
						'other' => q({0} hektoliter),
					},
					'hectopascal' => {
						'name' => q(hektopaskal),
						'other' => q({0} hektopaskal),
					},
					'hertz' => {
						'name' => q(het),
						'other' => q({0} het),
					},
					'horsepower' => {
						'name' => q(tenogo jaran),
						'other' => q({0} tenogo jaran),
					},
					'hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0} saben jam),
					},
					'inch' => {
						'name' => q(inci),
						'other' => q({0} inci),
						'per' => q({0} saben inci),
					},
					'inch-hg' => {
						'name' => q(inci saka raksa),
						'other' => q({0} inci saka raksa),
					},
					'joule' => {
						'name' => q(jol),
						'other' => q({0} jol),
					},
					'karat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobite),
						'other' => q({0} kilobite),
					},
					'kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} saben kilogram),
					},
					'kilohertz' => {
						'name' => q(kilohet),
						'other' => q({0} kilohet),
					},
					'kilojoule' => {
						'name' => q(kilojol),
						'other' => q({0} kilojol),
					},
					'kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} saben kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer saben jam),
						'other' => q({0} kilometer saben jam),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatt-jam),
						'other' => q({0} kilowatt-jam),
					},
					'knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					'light-year' => {
						'name' => q(taun cahya),
						'other' => q({0} taun cahya),
					},
					'liter' => {
						'name' => q(liter),
						'other' => q({0} liter),
						'per' => q({0} saben liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liter saben 100 kilometer),
						'other' => q({0} liter saben 100 kilometer),
					},
					'liter-per-kilometer' => {
						'name' => q(liter saben kilometer),
						'other' => q({0} liter saben kilometer),
					},
					'lux' => {
						'name' => q(luk),
						'other' => q({0} luk),
					},
					'megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabite),
						'other' => q({0} megabite),
					},
					'megahertz' => {
						'name' => q(megahet),
						'other' => q({0} megahet),
					},
					'megaliter' => {
						'name' => q(megaliter),
						'other' => q({0} megaliter),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(meter),
						'other' => q({0} meter),
						'per' => q({0} saben meter),
					},
					'meter-per-second' => {
						'name' => q(meter saben detik),
						'other' => q({0} meter saben detik),
					},
					'meter-per-second-squared' => {
						'name' => q(meter saben detik kuadrat),
						'other' => q({0} meter saben detik kuadrat),
					},
					'metric-ton' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					'microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					'micrometer' => {
						'name' => q(mikrometer),
						'other' => q({0} mikrometer),
					},
					'microsecond' => {
						'name' => q(mikrodetik),
						'other' => q({0} mikrodetik),
					},
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'name' => q(mil saben galon),
						'other' => q({0} mil saben galon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mil saben galon inggris),
						'other' => q({0} mil saben galon inggris),
					},
					'mile-per-hour' => {
						'name' => q(mil saben jam),
						'other' => q({0} mil saben jam),
					},
					'mile-scandinavian' => {
						'name' => q(mil-skandinavia),
						'other' => q({0} mil-skandinavia),
					},
					'milliampere' => {
						'name' => q(miliamper),
						'other' => q({0} miliamper),
					},
					'millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					'milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					'milligram-per-deciliter' => {
						'name' => q(miligram saben desiliter),
						'other' => q({0} miligram saben desiliter),
					},
					'milliliter' => {
						'name' => q(mililiter),
						'other' => q({0} mililiter),
					},
					'millimeter' => {
						'name' => q(milimeter),
						'other' => q({0} milimeter),
					},
					'millimeter-of-mercury' => {
						'name' => q(milimeter saka raksa),
						'other' => q({0} milimeter saka raksa),
					},
					'millimole-per-liter' => {
						'name' => q(milimol saben liter),
						'other' => q({0} milimol saben liter),
					},
					'millisecond' => {
						'name' => q(milidetik),
						'other' => q({0} milidetik),
					},
					'milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					'minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} saben menit),
					},
					'month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
						'per' => q({0} saben sasi),
					},
					'nanometer' => {
						'name' => q(nanometer),
						'other' => q({0} nanometer),
					},
					'nanosecond' => {
						'name' => q(nanodetik),
						'other' => q({0} nanodetik),
					},
					'nautical-mile' => {
						'name' => q(mil segoro),
						'other' => q({0} mil segoro),
					},
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0} saben ons),
					},
					'ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					'part-per-million' => {
						'name' => q(bagean saben yuta),
						'other' => q({0} bagean saben yuta),
					},
					'per' => {
						'1' => q({0} saben {1}),
					},
					'percent' => {
						'name' => q(persen),
						'other' => q({0} persen),
					},
					'permille' => {
						'name' => q(permil),
						'other' => q({0} permil),
					},
					'petabyte' => {
						'name' => q(petabite),
						'other' => q({0} petabite),
					},
					'picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					'pint' => {
						'name' => q(pin),
						'other' => q({0} pin),
					},
					'pint-metric' => {
						'name' => q(metrik pin),
						'other' => q({0} metrik pin),
					},
					'point' => {
						'name' => q(poin),
						'other' => q({0} poin),
					},
					'pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0} saben pon),
					},
					'pound-per-square-inch' => {
						'name' => q(pon saben inci kuadrat),
						'other' => q({0} pon saben inci kuadrat),
					},
					'quart' => {
						'name' => q(seprapat galon),
						'other' => q({0} seprapat galon),
					},
					'radian' => {
						'name' => q(radian),
						'other' => q({0} radian),
					},
					'revolution' => {
						'name' => q(revolusi),
						'other' => q({0} revolusi),
					},
					'second' => {
						'name' => q(detik),
						'other' => q({0} detik),
						'per' => q({0} saben detik),
					},
					'square-centimeter' => {
						'name' => q(sentimeter persegi),
						'other' => q({0} sentimeter persegi),
						'per' => q({0} saben sentimeter persegi),
					},
					'square-foot' => {
						'name' => q(kaki persegi),
						'other' => q({0} kaki persegi),
					},
					'square-inch' => {
						'name' => q(inci persegi),
						'other' => q({0} inci persegi),
						'per' => q({0} saben inci persegi),
					},
					'square-kilometer' => {
						'name' => q(kilometer persegi),
						'other' => q({0} kilometer persegi),
						'per' => q({0} saben kilometer persegi),
					},
					'square-meter' => {
						'name' => q(meter persegi),
						'other' => q({0} meter persegi),
						'per' => q({0} saben meter persegi),
					},
					'square-mile' => {
						'name' => q(mil persegi),
						'other' => q({0} mil persegi),
						'per' => q({0} saben mil persegi),
					},
					'square-yard' => {
						'name' => q(yard persegi),
						'other' => q({0} yard persegi),
					},
					'tablespoon' => {
						'name' => q(sendok mangan),
						'other' => q({0} sendok mangan),
					},
					'teaspoon' => {
						'name' => q(sendok teh),
						'other' => q({0} sendok teh),
					},
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabite),
						'other' => q({0} terabite),
					},
					'ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
					},
					'volt' => {
						'name' => q(volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(watt),
						'other' => q({0} watt),
					},
					'week' => {
						'name' => q(pekan),
						'other' => q({0} pekan),
						'per' => q({0} saben pekan),
					},
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					'year' => {
						'name' => q(taun),
						'other' => q({0} taun),
						'per' => q({0} saben taun),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(arah),
					},
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					'day' => {
						'name' => q(dino),
						'other' => q({0} dino),
					},
					'gram' => {
						'name' => q(gram),
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(jam),
						'other' => q({0}j),
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
						'name' => q(km/jam),
						'other' => q({0} km/jam),
					},
					'liter' => {
						'name' => q(liter),
						'other' => q({0} L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
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
						'name' => q(md),
						'other' => q({0} md),
					},
					'minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
					},
					'month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					'second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
					},
					'week' => {
						'name' => q(pekan),
						'other' => q({0} pekan),
					},
					'year' => {
						'name' => q(taun),
						'other' => q({0} taun),
					},
				},
				'short' => {
					'' => {
						'name' => q(arah),
					},
					'acre' => {
						'name' => q(are),
						'other' => q({0} are),
					},
					'acre-foot' => {
						'name' => q(are-kaki),
						'other' => q({0} are-kaki),
					},
					'ampere' => {
						'name' => q(amper),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(menit saka busur),
						'other' => q({0} menit saka busur),
					},
					'arc-second' => {
						'name' => q(detik saka busur),
						'other' => q({0} detik saka busur),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					'atmosphere' => {
						'name' => q(atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bite),
						'other' => q({0} bite),
					},
					'calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					'carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(kaki³),
						'other' => q({0} kaki³),
					},
					'cubic-inch' => {
						'name' => q(inci³),
						'other' => q({0} inci³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mil³),
						'other' => q({0} mil³),
					},
					'cubic-yard' => {
						'name' => q(yard³),
						'other' => q({0} yard³),
					},
					'cup' => {
						'name' => q(kup),
						'other' => q({0} kup),
					},
					'cup-metric' => {
						'name' => q(metrik kup),
						'other' => q({0} metrik kup),
					},
					'day' => {
						'name' => q(dino),
						'other' => q({0} dino),
						'per' => q({0}/dino),
					},
					'deciliter' => {
						'name' => q(dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(derajat),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(ons banyu),
						'other' => q({0} ons banyu),
					},
					'foodcalorie' => {
						'name' => q(Kal),
						'other' => q({0} Kal),
					},
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0}/kaki),
					},
					'g-force' => {
						'name' => q(tenaga-g),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0}/galon),
					},
					'gallon-imperial' => {
						'name' => q(galon inggris),
						'other' => q({0} galon inggris),
						'per' => q({0}/galon inggris),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GBite),
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
						'name' => q(gram),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hektar),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(tenogo jaran),
						'other' => q({0} tenogo jaran),
					},
					'hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0}/jam),
					},
					'inch' => {
						'name' => q(inci),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(jol),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karat),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kBite),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kilojol),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/jam),
					},
					'kilowatt' => {
						'name' => q(kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kW-jam),
						'other' => q({0} kW-jam),
					},
					'knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					'light-year' => {
						'name' => q(taun cahya),
						'other' => q({0} tc),
					},
					'liter' => {
						'name' => q(liter),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(liter/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(luk),
						'other' => q({0} luk),
					},
					'megabit' => {
						'name' => q(Mbit),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MBite),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'other' => q({0} ML),
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
						'name' => q(meter/dtk),
						'other' => q({0} m/dtk),
					},
					'meter-per-second-squared' => {
						'name' => q(meter/detik²),
						'other' => q({0} meter/detik²),
					},
					'metric-ton' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					'microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					'micrometer' => {
						'name' => q(µmeter),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'name' => q(mil/galon),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mil/galon inggris),
						'other' => q({0} mpg inggris),
					},
					'mile-per-hour' => {
						'name' => q(mil/jam),
						'other' => q({0} mil/jam),
					},
					'mile-scandinavian' => {
						'name' => q(mil-skandinavia),
						'other' => q({0} mil-skandinavia),
					},
					'milliampere' => {
						'name' => q(miliamper),
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
						'name' => q(mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'other' => q({0} mL),
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
						'name' => q(mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(milidtk),
						'other' => q({0} md),
					},
					'milliwatt' => {
						'name' => q(mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
					},
					'month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
						'per' => q({0}/sasi),
					},
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanodtk),
						'other' => q({0} nd),
					},
					'nautical-mile' => {
						'name' => q(mil segoro),
						'other' => q({0} mil segoro),
					},
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0}/ons),
					},
					'ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} ps),
					},
					'part-per-million' => {
						'name' => q(bagean/yuta),
						'other' => q({0} bagean saben yuta),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(persen),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(permil),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(PBite),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pin),
						'other' => q({0} pin),
					},
					'pint-metric' => {
						'name' => q(metrik pin),
						'other' => q({0} metrik pin),
					},
					'point' => {
						'name' => q(poin),
						'other' => q({0} p),
					},
					'pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0}/pon),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(seprapat galon),
						'other' => q({0} seprapat galon),
					},
					'radian' => {
						'name' => q(rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
						'per' => q({0}/dtk),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(kaki persegi),
						'other' => q({0} kaki persegi),
					},
					'square-inch' => {
						'name' => q(inci²),
						'other' => q({0} inci²),
						'per' => q({0}/inci²),
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
						'name' => q(mil²),
						'other' => q({0} mil²),
						'per' => q({0}/mil²),
					},
					'square-yard' => {
						'name' => q(yard²),
						'other' => q({0} yard²),
					},
					'tablespoon' => {
						'name' => q(sdk mgn),
						'other' => q({0} sdk mgn),
					},
					'teaspoon' => {
						'name' => q(sdk teh),
						'other' => q({0} sdk teh),
					},
					'terabit' => {
						'name' => q(Tbit),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TBite),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
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
						'name' => q(pekan),
						'other' => q({0} pekan),
						'per' => q({0}/pekan),
					},
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					'year' => {
						'name' => q(taun),
						'other' => q({0} taun),
						'per' => q({0}/taun),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yoh)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ora|no|n)$' }
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
	default		=> 'java',
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
			'group' => q(.),
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
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
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
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirham Uni Emirat Arab),
				'other' => q(Dirham Uni Emirat Arab),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afghani Afganistan),
				'other' => q(Afghani Afganistan),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek Albania),
				'other' => q(Lek Albania),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dram Armenia),
				'other' => q(Dram Armenia),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Guilder Antilla Walanda),
				'other' => q(Guilder Antilla Walanda),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kwanza Angola),
				'other' => q(Kwanza Angola),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Peso Argentina),
				'other' => q(Peso Argentina),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Dolar Australia),
				'other' => q(Dolar Australia),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florin Aruban),
				'other' => q(Florin Aruban),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manat Azerbaijan),
				'other' => q(Manat Azerbaijan),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Mark Konvertibel Bosnia-Herzegovina),
				'other' => q(Mark Konvertibel Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Dolar Barbadian),
				'other' => q(Dolar Barbadian),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka Bangladesh),
				'other' => q(Taka Bangladesh),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lev Bulgaria),
				'other' => q(Lev Bulgaria),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bahrain Dinar),
				'other' => q(Bahrain Dinar),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Franc Burundi),
				'other' => q(Franc Burundi),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Dolar Bermuda),
				'other' => q(Dolar Bermuda),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Dolar Brunai),
				'other' => q(Dolar Brunai),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviano Bolivia),
				'other' => q(Boliviano Bolivia),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Real Brasil),
				'other' => q(Real Brasil),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dolar Bahamian),
				'other' => q(Dolar Bahamian),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrum Bhutan),
				'other' => q(Ngultrum Bhutan),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula Botswana),
				'other' => q(Pula Botswana),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Ruble Belarusia),
				'other' => q(Ruble Belarusia),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dolar Belise),
				'other' => q(Dolar Belise),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dolar Kanada),
				'other' => q(Dolar Kanada),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Franc Kongo),
				'other' => q(Franc Kongo),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Franc Swiss),
				'other' => q(Franc Swiss),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Peso Chili),
				'other' => q(Peso Chili),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Yuan Cina \(Jaban Rangkah\)),
				'other' => q(Yuan Cina \(Jaban Rangkah\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuan Cina),
				'other' => q(Yuan Cina),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Peso Kolumbia),
				'other' => q(Peso Kolumbia),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Colon Kosta Rika),
				'other' => q(Colon Kosta Rika),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Peso Konvertibel Kuba),
				'other' => q(Peso Konvertibel Kuba),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Peso Kuba),
				'other' => q(Peso Kuba),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Escudo Tanjung Verde),
				'other' => q(Escudo Tanjung Verde),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Koruna Czech),
				'other' => q(Koruna Czech),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Franc Djibouti),
				'other' => q(Franc Djibouti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Krone Denmark),
				'other' => q(Krone Denmark),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Peso Dominika),
				'other' => q(Peso Dominika),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinar Algeria),
				'other' => q(Dinar Algeria),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Pound Mesir),
				'other' => q(Pound Mesir),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nakfa Eritrea),
				'other' => q(Nakfa Eritrea),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr Ethiopia),
				'other' => q(Birr Ethiopia),
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
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dolar Fiji),
				'other' => q(Dolar Fiji),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Pound Kepuloan Falkland),
				'other' => q(Pound Kepuloan Falkland),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Pound Inggris),
				'other' => q(Pound Inggris),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Lari Georgia),
				'other' => q(Lari Georgia),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Cedi Ghana),
				'other' => q(Cedi Ghana),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Pound Gibraltar),
				'other' => q(Pound Gibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi Gambia),
				'other' => q(Dalasi Gambia),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Franc Guinea),
				'other' => q(Franc Guinea),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetzal Guatemala),
				'other' => q(Quetzal Guatemala),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Dolar Guyana),
				'other' => q(Dolar Guyana),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dolar Hong Kong),
				'other' => q(Dolar Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Lempira Honduras),
				'other' => q(Lempira Honduras),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna Kroasia),
				'other' => q(Kuna Kroasia),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gourde Haiti),
				'other' => q(Gourde Haiti),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Forint Hungaria),
				'other' => q(Forint Hungaria),
			},
		},
		'IDR' => {
			symbol => 'Rp',
			display_name => {
				'currency' => q(Rupiah Indonesia),
				'other' => q(Rupiah Indonesia),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Shekel Anyar Israel),
				'other' => q(Shekel Anyar Israel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupee India),
				'other' => q(Rupee India),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar Irak),
				'other' => q(Dinar Irak),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Rial Iran),
				'other' => q(Rial Iran),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Krona Islandia),
				'other' => q(Krona Islandia),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dolar Jamaika),
				'other' => q(Dolar Jamaika),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar Yordania),
				'other' => q(Dinar Yordania),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yen Jepang),
				'other' => q(Yen Jepang),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Shilling Kenya),
				'other' => q(Shilling Kenya),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som Kirgistan),
				'other' => q(Som Kirgistan),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riel Kamboja),
				'other' => q(Riel Kamboja),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Franc Komoro),
				'other' => q(Franc Komoro),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Won Korea Lor),
				'other' => q(Won Korea Lor),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Won Korea Kidul),
				'other' => q(Won Korea Kidul),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinar Kuwait),
				'other' => q(Dinar Kuwait),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Dolar Kepuloan Caiman),
				'other' => q(Dolar Kepuloan Caiman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge Kasakhstan),
				'other' => q(Tenge Kasakhstan),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kip Laos),
				'other' => q(Kip Laos),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Pound Libanon),
				'other' => q(Pound Libanon),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupee Sri Lanka),
				'other' => q(Rupee Sri Lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Dolar Liberia),
				'other' => q(Dolar Liberia),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinar Libya),
				'other' => q(Dinar Libya),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Dirham Maroko),
				'other' => q(Dirham Moroko),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leu Moldova),
				'other' => q(Leu Moldova),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariary Malagasi),
				'other' => q(Ariary Malagasi),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denar Masedonia),
				'other' => q(Denar Masedonia),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kyat Myanmar),
				'other' => q(Kyat Myanmar),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik Mongol),
				'other' => q(Tugrik Mongol),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataca Macau),
				'other' => q(MOP),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Ouguiya Mauritania \(1973 - 2017\)),
				'other' => q(Ouguiya Mauritania \(1973 - 2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Ouguiya Mauritania),
				'other' => q(Ouguiya Mauritania),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupee Mauritius),
				'other' => q(Rupee Mauritius),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rufiyaa Maladewa),
				'other' => q(Rufiyaa Maladewa),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kwacha Malawi),
				'other' => q(Kwacha Malawi),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Peso Meksiko),
				'other' => q(Peso Meksiko),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Ringgit Malaysia),
				'other' => q(Ringgit Malaysia),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metical Mosambik),
				'other' => q(Metical Mosambik),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dolar Namibia),
				'other' => q(Dolar Namibia),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Naira Nigeria),
				'other' => q(Naira Nigeria),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Cordoba Nikaragua),
				'other' => q(Cordoba Nikaragua),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Krone Norwegia),
				'other' => q(Krone Norwegia),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupee Nepal),
				'other' => q(Rupee Nepal),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Dolar Selandia Anyar),
				'other' => q(Dolar Selandia Anyar),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial Oman),
				'other' => q(Rial Oman),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa Panama),
				'other' => q(Balboa Panama),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sol Peru),
				'other' => q(Sol Peru),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina Papua Nugini),
				'other' => q(Kina Papua Nugini),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Piso Filipina),
				'other' => q(Piso Filipina),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupee Pakistan),
				'other' => q(Rupee Pakistan),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloty Polandia),
				'other' => q(Zloty Polandia),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guarani Paraguay),
				'other' => q(Guarani Paraguay),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Rial Qatar),
				'other' => q(Rial Qatar),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu Rumania),
				'other' => q(Leu Rumania),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinar Serbia),
				'other' => q(Dinar Serbia),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rubel Rusia),
				'other' => q(Rubel Rusia),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Franc Rwanda),
				'other' => q(Franc Rwanda),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riyal Saudi),
				'other' => q(Riyal Saudi),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dolar Kepuloan Solomon),
				'other' => q(Dolar Kepuloan Solomon),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupee Seichelles),
				'other' => q(Rupee Seichelles),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Pound Sudan),
				'other' => q(Pound Sudan),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Krona Swedia),
				'other' => q(Krona Swedia),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Dolar Singapura),
				'other' => q(Dolar Singapura),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Pound Santa Helena),
				'other' => q(Pound Santa Helena),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leone Sierra Leone),
				'other' => q(Leone Sierra Leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Shilling Somalia),
				'other' => q(Shilling Somalia),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Dolar Suriname),
				'other' => q(Dolar Suriname),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Pound Sudan Kidul),
				'other' => q(Pound Sudan Kidul),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Dobra Sao Tome lan Principe),
				'other' => q(Dobra Sao Tome lan Principe),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Pound Siria),
				'other' => q(Pound Siria),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni Swasi),
				'other' => q(Lilangeni Swasi),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Baht Thai),
				'other' => q(Baht Thai),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoni Tajikistan),
				'other' => q(Somoni Tajikistan),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat Turmenistan),
				'other' => q(Manat Turmenistan),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinar Tunisia),
				'other' => q(Dinar Tunisia),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Paʻanga Tonga),
				'other' => q(Paʻanga Tonga),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Lira Turki),
				'other' => q(Lira Turki),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Dolar Trinidad lan Tobago),
				'other' => q(Dolar Trinidad lan Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dolar Anyar Taiwan),
				'other' => q(Dolar Anyar Taiwan),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Shilling Tansania),
				'other' => q(Shilling Tansania),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Hryvnia Ukrania),
				'other' => q(Hryvnia Ukrania),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Shilling Uganda),
				'other' => q(Shilling Uganda),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Dolar Amerika Serikat),
				'other' => q(Dolar Amerika Serikat),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Peso Uruguay),
				'other' => q(Peso Uruguay),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Som Usbekistan),
				'other' => q(Som Usbekistan),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Bolivar Venezuela \(2008 - 2018\)),
				'other' => q(Bolivar Venezuela \(2008 - 2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Bolivar Venezuela),
				'other' => q(Bolivar Venezuela),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Dong Vietnam),
				'other' => q(Dong Vietnam),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vatu Vanuatu),
				'other' => q(Vatu Vanuatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala Samoa),
				'other' => q(Tala Samoa),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA Franc Afrika Tengah),
				'other' => q(CFA Franc Afrika Tengah),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Dolar Karibia Wetan),
				'other' => q(Dolar Karibia Wetan),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA Franc Afrika Kulon),
				'other' => q(CFA Franc Afrika Kulon),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Franc CFP),
				'other' => q(Franc CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Dhuwit Ora Dikenali),
				'other' => q(Dhuwit Ora Dikenali),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial Yaman),
				'other' => q(Rial Yaman),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand Afrika Kidul),
				'other' => q(Rand Afrika Kidul),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha Sambia),
				'other' => q(Kwacha Sambia),
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
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Agt',
							'Sep',
							'Okt',
							'Nov',
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
							'Januari',
							'Februari',
							'Maret',
							'April',
							'Mei',
							'Juni',
							'Juli',
							'Agustus',
							'September',
							'Oktober',
							'November',
							'Desember'
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
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Agt',
							'Sep',
							'Okt',
							'Nov',
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
							'Januari',
							'Februari',
							'Maret',
							'April',
							'Mei',
							'Juni',
							'Juli',
							'Agustus',
							'September',
							'Oktober',
							'November',
							'Desember'
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
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Ahd'
					},
					narrow => {
						mon => 'S',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'A'
					},
					short => {
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Ahd'
					},
					wide => {
						mon => 'Senin',
						tue => 'Selasa',
						wed => 'Rabu',
						thu => 'Kamis',
						fri => 'Jumat',
						sat => 'Sabtu',
						sun => 'Ahad'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Ahd'
					},
					narrow => {
						mon => 'S',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'A'
					},
					short => {
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Ahd'
					},
					wide => {
						mon => 'Senin',
						tue => 'Selasa',
						wed => 'Rabu',
						thu => 'Kamis',
						fri => 'Jumat',
						sat => 'Sabtu',
						sun => 'Ahad'
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
					abbreviated => {0 => 'TW1',
						1 => 'TW2',
						2 => 'TW3',
						3 => 'TW4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'triwulan kaping pisan',
						1 => 'triwulan kaping loro',
						2 => 'triwulan kaping telu',
						3 => 'triwulan kaping papat'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'TW1',
						1 => 'TW2',
						2 => 'TW3',
						3 => 'TW4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'triwulan kaping pisan',
						1 => 'triwulan kaping loro',
						2 => 'triwulan kaping telu',
						3 => 'triwulan kaping papat'
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
					'am' => q{Isuk},
					'pm' => q{Wengi},
				},
				'narrow' => {
					'am' => q{Isuk},
					'pm' => q{Wengi},
				},
				'wide' => {
					'am' => q{Isuk},
					'pm' => q{Wengi},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{Isuk},
					'pm' => q{Wengi},
				},
				'narrow' => {
					'am' => q{Isuk},
					'pm' => q{Wengi},
				},
				'wide' => {
					'am' => q{Isuk},
					'pm' => q{Wengi},
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
				'0' => 'SM',
				'1' => 'M'
			},
			wide => {
				'0' => 'Sakdurunge Masehi',
				'1' => 'Masehi'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
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
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM - y GGGGG},
			yyyyMEd => q{E, dd - MM - y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd - MM - y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{'pekan' W 'saka' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'pekan' w 'saka' Y},
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
				M => q{MM – MM},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
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
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM-y – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
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
				M => q{MM – MM},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{MMM d–d},
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
				M => q{MM-y – MM-y},
				y => q{MM-y – MM-y},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y},
				d => q{E, dd-MM-y – E, dd-MM-y},
				y => q{E, dd-MM-y – E, dd-MM-y},
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
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
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
		regionFormat => q(Wektu {0}),
		regionFormat => q(Wektu Ketigo {0}),
		regionFormat => q(Wektu Standar {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Wektu Afghanistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algiers#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoum#,
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
			exemplarCity => q#Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadishu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
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
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
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
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Wektu Afrika Tengah#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Wektu Afrika Wetan#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Wektu Standar Afrika Kidul#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Afrika Kulon#,
				'generic' => q#Wektu Afrika Kulon#,
				'standard' => q#Wektu Standar Afrika Kulon#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Wektu Ketigo Alaska#,
				'generic' => q#Wektu Alaska#,
				'standard' => q#Wektu Standar Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Wektu Ketigo Amazon#,
				'generic' => q#Wektu Amazon#,
				'standard' => q#Wektu Standar Amazon#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
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
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Belise#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Teluk Cambridge#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caiman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curacao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Benteng Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Teluk Glace#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Teluk Goose#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifak#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox [Indiana]#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo [Indiana]#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg [Indiana]#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City [Indiana]#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay [Indiana]#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes [Indiana]#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac [Indiana]#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello [Kentucky]#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendosa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Kutho Meksiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah [Dakota Lor]#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Tengah [Dakota Lor]#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Salem Anyar [Dakota Lor]#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Palabuhan Spanyol#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Riko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Kali Rainy#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Santa Barthelemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Santa John#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Santa Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Santa Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Santa Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Arus Banter#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Teluk Gludhug#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Wektu Ketigo Tengah#,
				'generic' => q#Wektu Tengah#,
				'standard' => q#Wektu Standar Tengah#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Wektu Ketigo sisih Wetah#,
				'generic' => q#Wektu sisih Wetan#,
				'standard' => q#Wektu Standar sisih Wetan#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Wektu Ketigo Giri#,
				'generic' => q#Wektu Giri#,
				'standard' => q#Wektu Standar Giri#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Wektu Ketigo Pasifik#,
				'generic' => q#Wektu Pasifik#,
				'standard' => q#Wektu Standar Pasifik#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Wektu Ketigo Apia#,
				'generic' => q#Wektu Apia#,
				'standard' => q#Wektu Standar Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Wektu Ketigo Arab#,
				'generic' => q#Wektu Arab#,
				'standard' => q#Wektu Standar Arab#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Wektu Ketigo Argentina#,
				'generic' => q#Wektu Argentina#,
				'standard' => q#Wektu Standar Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Argentina sisih Kulon#,
				'generic' => q#Wektu Argentina sisih Kulon#,
				'standard' => q#Wektu Standar Argentina sisih Kulon#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Wektu Ketigo Armenia#,
				'generic' => q#Wektu Armenia#,
				'standard' => q#Wektu Standar Armenia#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baghdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
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
			exemplarCity => q#Muscat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapura#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
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
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Wektu Ketigo Atlantik#,
				'generic' => q#Wektu Atlantik#,
				'standard' => q#Wektu Standar Atlantik#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia Kidul#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Saint Helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
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
			exemplarCity => q#Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sydney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Wektu Ketigo Australia Tengah#,
				'generic' => q#Wektu Australia Tengah#,
				'standard' => q#Wektu Standar Australia Tengah#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Wektu Ketigo Australia Tengah sisih Kulon#,
				'generic' => q#Wektu Australia Tengah sisih Kulon#,
				'standard' => q#Wektu Standar Australia Tengah sisih Kulon#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Wektu Ketigo Australia sisih Wetan#,
				'generic' => q#Wektu Australia sisih Wetan#,
				'standard' => q#Wektu Standar Australia sisih Wetan#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Australia sisih Kulon#,
				'generic' => q#Wektu Australia sisih Kulon#,
				'standard' => q#Wektu Standar Australia sisih Kulon#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Wektu Ketigo Azerbaijan#,
				'generic' => q#Wektu Azerbaijan#,
				'standard' => q#Wektu Standar Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Wektu Ketigo Azores#,
				'generic' => q#Wektu Azores#,
				'standard' => q#Wektu Standar Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Wektu Ketigo Bangladesh#,
				'generic' => q#Wektu Bangladesh#,
				'standard' => q#Wektu Standar Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Wektu Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Wektu Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Wektu Ketigo Brasilia#,
				'generic' => q#Wektu Brasilia#,
				'standard' => q#Wektu Standar Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Wektu Brunai Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Wektu Ketigo Tanjung Verde#,
				'generic' => q#Wektu Tanjung Verde#,
				'standard' => q#Wektu Standar Tanjung Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Wektu Standar Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Wektu Ketigo Chatham#,
				'generic' => q#Wektu Chatham#,
				'standard' => q#Wektu Standar Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Wektu Ketigo Chili#,
				'generic' => q#Wektu Chili#,
				'standard' => q#Wektu Standar Chili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Wektu Ketigo Cina#,
				'generic' => q#Wektu Cina#,
				'standard' => q#Wektu Standar Cina#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#WEktu Ketigo Choibalsan#,
				'generic' => q#Wektu Choibalsan#,
				'standard' => q#Wektu Standar Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Wektu Pulo Natal#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Wektu Kepuloan Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Wektu Ketigo Kolombia#,
				'generic' => q#Wektu Kolombia#,
				'standard' => q#Wektu Standar Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Wektu Ketigo Kepuloan Cook#,
				'generic' => q#Wektu Kepuloan Cook#,
				'standard' => q#Wektu Standar Kepuloan Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Wektu Ketigo Kuba#,
				'generic' => q#Wektu Kuba#,
				'standard' => q#Wektu Standar Kuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Wektu Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Wektu Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Wektu Timor Leste#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Wektu Ketigo Pulo Paskah#,
				'generic' => q#Wektu Pulo Paskah#,
				'standard' => q#Wektu Standar Pulo Paskah#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Wektu Ekuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Wektu Kordinat Universal#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Kuto Ora Dikenali#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussels#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucharest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Wektu Standar Irlandia#,
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
			exemplarCity => q#Pulo Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Wektu Ketigo Inggris#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburk#,
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
			exemplarCity => q#Moscow#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prague#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsaw#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Wektu Ketigo Eropa Tengah#,
				'generic' => q#Wektu Eropa Tengah#,
				'standard' => q#Wektu Standar Eropa Tengah#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Wektu Ketigo Eropa sisih Wetan#,
				'generic' => q#Wektu Eropa sisih Wetan#,
				'standard' => q#Wektu Standar Eropa sisih Wetan#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Wektu Eropa sisih Wetan seng Luwih Adoh#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Eropa sisih Kulon#,
				'generic' => q#Wektu Eropa sisih Kulon#,
				'standard' => q#Wektu Standar Eropa sisih Kulon#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Wektu Ketigo Kepuloan Falkland#,
				'generic' => q#Wektu Kepuloan Falkland#,
				'standard' => q#Wektu Standar Kepuloan Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Wektu Ketigo Fiji#,
				'generic' => q#Wektu Fiji#,
				'standard' => q#Wektu Standar Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Wektu Guiana Prancis#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Wektu Antartika lan Prancis sisih Kidul#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Wektu Rerata Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Wektu Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Wektu Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Wektu Ketigo Georgia#,
				'generic' => q#Wektu Georgia#,
				'standard' => q#Wektu Standar Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Wektu Kepuloan Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Wektu Ketigo Grinland Wetan#,
				'generic' => q#Wektu Grinland Wetan#,
				'standard' => q#Wektu Standar Grinland Wetan#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Grinland Kulon#,
				'generic' => q#Wektu Grinland Kulon#,
				'standard' => q#Wektu Standar Grinland Kulon#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Wektu Standar Teluk#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Wektu Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Wektu Ketigo Hawaii-Aleutian#,
				'generic' => q#Wektu Hawaii-Aleutian#,
				'standard' => q#Wektu Standar Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Wektu Ketigo Hong Kong#,
				'generic' => q#Wektu Hong Kong#,
				'standard' => q#Wektu Standar Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Wektu Ketigo Hovd#,
				'generic' => q#Wektu Hovd#,
				'standard' => q#Wektu Standar Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Wektu Standar India#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Khagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Natal#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
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
			exemplarCity => q#Maladewa#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Wektu Segoro Hindia#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Wektu Indocina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Wektu Indonesia Tengah#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Wektu Indonesia sisih Wetan#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Wektu Indonesia sisih Kulon#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Wektu Ketigo Iran#,
				'generic' => q#Wektu Iran#,
				'standard' => q#Wektu Standar Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Irkutsk#,
				'generic' => q#Wektu Irkutsk#,
				'standard' => q#Wektu Standar Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Wektu Ketigo Israel#,
				'generic' => q#Wektu Israel#,
				'standard' => q#Wektu Standar Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Wektu Ketigo Jepang#,
				'generic' => q#Wektu Jepang#,
				'standard' => q#Wektu Standar Jepang#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Wektu Kazakhstan Wetan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Wektu Kazakhstan Kulon#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Wektu Ketigo Korea#,
				'generic' => q#Wektu Korea#,
				'standard' => q#Wektu Standar Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Wektu Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Krasnoyarsk#,
				'generic' => q#Wektu Krasnoyarsk#,
				'standard' => q#Wektu Standar Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Wektu Kirgizstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Wektu Kepuloan Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Wektu Ketigo Lord Howe#,
				'generic' => q#Wektu Lord Howe#,
				'standard' => q#Wektu Standar Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Wektu Pulo Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Wektu Ketigo Magadan#,
				'generic' => q#Wektu Magadan#,
				'standard' => q#Wektu Standar Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Wektu Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Wektu Maladewa#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Wektu Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Wektu Kepuloan Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Wektu Ketigo Mauritius#,
				'generic' => q#Wektu Mauritius#,
				'standard' => q#Wektu Standar Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Wektu Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Wektu Ketigo Meksiko Lor-Kulon#,
				'generic' => q#Wektu Meksiko Lor-Kulon#,
				'standard' => q#Wektu Standar Meksiko Lor-Kulon#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Wektu Ketigo Pasifik Meksiko#,
				'generic' => q#Wektu Pasifik Meksiko#,
				'standard' => q#Wektu Standar Pasifik Meksiko#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Wektu Ketigo Ulaanbaatar#,
				'generic' => q#Wektu Ulaanbaatar#,
				'standard' => q#Wektu Standar Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Wektu Ketigo Moscow#,
				'generic' => q#Wektu Moscow#,
				'standard' => q#Wektu Standar Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Wektu Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Wektu Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Wektu Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Wektu Ketigo Kaledonia Anyar#,
				'generic' => q#Wektu Kaledonia Anyar#,
				'standard' => q#Wektu Standar Kaledonia Anyar#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Wektu Ketigo Selandia Anyar#,
				'generic' => q#Wektu Selandia Anyar#,
				'standard' => q#Wektu Standar Selandia Anyar#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Wektu Ketigo Newfoundland#,
				'generic' => q#Wektu Newfoundland#,
				'standard' => q#Wektu Standar Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Wektu Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Wektu Pulo Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Wektu Ketigo Fernando de Noronha#,
				'generic' => q#Wektu Fernando de Noronha#,
				'standard' => q#Wektu Standar Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Novosibirsk#,
				'generic' => q#Wektu Novosibirsk#,
				'standard' => q#Wektu Standar Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Omsk#,
				'generic' => q#Wektu Omsk#,
				'standard' => q#Wektu Standar Omsk#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Paskah#,
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
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
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
			exemplarCity => q#Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pelabuhan Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Wektu Ketigo Pakistan#,
				'generic' => q#Wektu Pakistan#,
				'standard' => q#Wektu Standar Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Wektu Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Wektu Papua Nugini#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Wektu Ketigo Paraguay#,
				'generic' => q#Wektu Paraguay#,
				'standard' => q#Wektu Standar Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Wektu Ketigo Peru#,
				'generic' => q#Wektu Peru#,
				'standard' => q#Wektu Standar Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Wektu Ketigo Filipina#,
				'generic' => q#Wektu Filipina#,
				'standard' => q#Wektu Standar Filipina#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Wektu Kepuloan Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Wektu Ketigo Santa Pierre lan Miquelon#,
				'generic' => q#Wektu Santa Pierre lan Miquelon#,
				'standard' => q#Wektu Standar Santa Pierre lan Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Wektu Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Wektu Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Wektu Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Wektu Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Wektu Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Wektu Ketigo Sakhalin#,
				'generic' => q#Wektu Sakhalin#,
				'standard' => q#Wektu Standar Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Wektu Ketigo Samoa#,
				'generic' => q#Wektu Samoa#,
				'standard' => q#Wektu Standar Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Wektu Seichelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Wektu Standar Singapura#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Wektu Kepuloan Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Wektu Georgia Kidul#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Wektu Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Wektu Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Wektu Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Wektu Ketigo Taipei#,
				'generic' => q#Wektu Taipei#,
				'standard' => q#Wektu Standar Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Wektu Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Wektu Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Wektu Ketigo Tonga#,
				'generic' => q#Wektu Tonga#,
				'standard' => q#Wektu Standar Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Wektu Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Wektu Ketigo Turkmenistan#,
				'generic' => q#Wektu Turkmenistan#,
				'standard' => q#Wektu Standar Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Wektu Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Wektu Ketigo Uruguay#,
				'generic' => q#Wektu Uruguay#,
				'standard' => q#Wektu Standar Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Wektu Ketigo Usbekistan#,
				'generic' => q#Wektu Usbekistan#,
				'standard' => q#Wektu Standar Usbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Wektu Ketigo Vanuatu#,
				'generic' => q#Wektu Vanuatu#,
				'standard' => q#Wektu Standar Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Wektu Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wektu Ketigo Vladivostok#,
				'generic' => q#Wektu Vladivostok#,
				'standard' => q#Wektu Standar Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wektu Ketigo Volgograd#,
				'generic' => q#Wektu Volgograd#,
				'standard' => q#Wektu Standar Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wektu Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wektu Pulo Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wektu Wallis lan Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Yakutsk#,
				'generic' => q#Wektu Yakutsk#,
				'standard' => q#Wektu Standar Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Wektu Ketigo Yekaterinburg#,
				'generic' => q#Wektu Yekaterinburg#,
				'standard' => q#Wektu Standar Yekaterinburg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
