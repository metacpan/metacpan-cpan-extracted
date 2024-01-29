=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kl - Package for language Kalaallisut

=cut

package Locale::CLDR::Locales::Kl;
# This file auto generated from Data\common\main\kl.xml
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
		'numbertimes' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ataaseq),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(marlunnik),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(pingasunik),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(sisamanik),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(tallimanik),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(arfinilinnik),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(arfineq-marlunnik),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(arfineq-pingasunik),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(arfineq-sisamanik),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(qulinik),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(aqqanilinik),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(aqqaneq-marlunnik),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(aqqaneq-pingasunik),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(aqqaneq-sisamanik),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(aqqaneq-tallimanik),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(arfersanilinnik),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(arfersaneq-marlunnik),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(arfersaneq-pingasunik),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(arfersaneq-sisamanik),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%numbertimes← qulillit[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(uutritit[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%numbertimes← uutritillit[ →→]),
				},
				'max' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%numbertimes← uutritillit[ →→]),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nuulu),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ataaseq),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(marluk),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(pingasut),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(sisamat),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(tallimat),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(arfinillit),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(arfineq-marluk),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(arfineq-pingasut),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(arfineq-sisamat),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(qulit),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(aqqanilit),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(aqqaneq-marluk),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(aqqaneq-pingasut),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(aqqaneq-sisamat),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(aqqaneq-tallimat),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(arfersanillit),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(arfersaneq-marluk),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(arfersaneq-pingasut),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(arfersaneq-sisamat),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%numbertimes← qulillit[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(uutritit[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%numbertimes← uutritillit[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuusintit[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%numbertimes← tuusintillit[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(millionit[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%numbertimes← millionillit[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(milliardit[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%numbertimes← milliardillit[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(billionit[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%numbertimes← billioniillit[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(billiardit[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%numbertimes← billiardillit[ →→]),
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
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
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
				'ar' => 'arabiamiusut',
 				'az' => 'aserbajdsjaniskisut',
 				'bn' => 'bengalimiutut',
 				'cs' => 'tjekkiamut',
 				'da' => 'qallunaatut',
 				'de' => 'tyskisut',
 				'en' => 'tuluttut',
 				'eo' => 'esperanto',
 				'es' => 'spanskisut',
 				'et' => 'estlandimiutut',
 				'fa' => 'persiskisut',
 				'fi' => 'finlandimiutut',
 				'fo' => 'savalimmiutut',
 				'fr' => 'franskisut',
 				'ga' => 'irlandimiutut',
 				'he' => 'hebraimiutut',
 				'hi' => 'hindimiutut',
 				'id' => 'indonesiamiutut',
 				'is' => 'islandimiusut',
 				'it' => 'italiamiutut',
 				'ja' => 'japanimiusut',
 				'kl' => 'kalaallisut',
 				'ko' => 'koreamiusut',
 				'ku' => 'kurdiskisut',
 				'la' => 'latiinerisut',
 				'lt' => 'litauenimiutut',
 				'lv' => 'letlandimiutut',
 				'mg' => 'malagassiskisut',
 				'mi' => 'maorimiutut',
 				'nl' => 'hollandimiutut',
 				'pl' => 'polenimiutut',
 				'ps' => 'pashtomiutut',
 				'pt' => 'portugalimiutut',
 				'ro' => 'rumænimiutut',
 				'ru' => 'russisut',
 				'sk' => 'slovakimiusut',
 				'sv' => 'svenskisut',
 				'sw' => 'swahilimiutut',
 				'th' => 'thailandimiutut',
 				'tr' => 'tyrkiskisut',
 				'uk' => 'ukrainimiusut',
 				'und' => '(atorsinnaanngitsoq oqaatsit)',
 				'ur' => 'urdumiutut',
 				'vi' => 'vietnamimiusut',
 				'zh' => 'kineserisut',

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
			'Latn' => 'latin allakkat',
 			'Zsym' => 'assersuut',
 			'Zyyy' => 'peqatigiipput',
 			'Zzzz' => 'atorsinnaanngitsoq allakkat',

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
			'001' => 'silarsuaq',
 			'002' => 'Afrika',
 			'003' => 'Amerika Avannarleq',
 			'005' => 'Amerika Kujalleq',
 			'009' => 'Oceania',
 			'011' => 'Afrika Killiit',
 			'013' => 'America Qitiusumik',
 			'014' => 'Afrika Kangilliit',
 			'015' => 'Afrika Avannarleq',
 			'017' => 'Afrika Qitiusumik',
 			'018' => 'Afrika Kujalleq',
 			'019' => 'Amerika',
 			'030' => 'Asia Kangilliit',
 			'034' => 'Asia Kujalleq',
 			'039' => 'Europa Kujalleq',
 			'053' => 'Australia aamma Nutaaq Zeelandi',
 			'054' => 'Melanesia',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Asia Qitiusumik',
 			'145' => 'Asia Killiit',
 			'150' => 'Europa',
 			'151' => 'Europa Kangilliit',
 			'154' => 'Europa Avannarleq',
 			'155' => 'Europa Killiit',
 			'419' => 'America Latin aamma Karibia',
 			'AC' => 'Ascension qeqertaq',
 			'AD' => 'Andorra',
 			'AF' => 'Afghanistani',
 			'AG' => 'Antigua aamma Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Qalasersuaq Kujalleq',
 			'AR' => 'Argentina',
 			'AT' => 'Østrigi',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandi',
 			'BA' => 'Bosnia aamma Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet qeqertaq',
 			'BW' => 'Botswana',
 			'BY' => 'Hvideruslandi',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Cocos qeqertaq',
 			'CD' => 'Kongo-Kinshasa',
 			'CG' => 'Kongo-Brazzaville',
 			'CH' => 'Schweizi',
 			'CK' => 'Cook qeqertaq',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Colombia',
 			'CP' => 'Clipperton qeqertaq',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Cap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Jul-qeqertaq',
 			'CY' => 'Cypern',
 			'CZ' => 'Tjekkia',
 			'DE' => 'Tysklandi',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danmarki',
 			'DM' => 'Dominica',
 			'DZ' => 'Algeriet',
 			'EA' => 'Ceuta aamma Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estlandi',
 			'EG' => 'Egypten',
 			'EH' => 'Sahara Killiit',
 			'ER' => 'Eritrea',
 			'ES' => 'Spania',
 			'ET' => 'Ethiopia',
 			'EU' => 'Europami nunat kattusimaffiat',
 			'FI' => 'Finlandi',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandi qeqertaq',
 			'FM' => 'Micronesia',
 			'FO' => 'Savalimmiut',
 			'FR' => 'Frankrigi',
 			'GA' => 'Gabon',
 			'GB' => 'Tuluit Nunaat',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Kalaallit Nunaat',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GR' => 'Grækenlandi',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarni',
 			'IC' => 'Kanaria qeqertaq',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlandi',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandi',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordani',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KH' => 'Kambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'Saint Kitts aamma Nevis',
 			'KP' => 'Korea Avannarleq',
 			'KR' => 'Korea Kujalleq',
 			'KW' => 'Kuwait',
 			'KY' => 'Cayman qeqertaq',
 			'KZ' => 'Kasakhstani',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtensteini',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litaueni',
 			'LU' => 'Luxembourg',
 			'LV' => 'Letlandi',
 			'LY' => 'Libya',
 			'MA' => 'Marocko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Frankrigi Saint Martin',
 			'MG' => 'Madagaskar',
 			'ML' => 'Mali',
 			'MM' => 'Burma',
 			'MO' => 'Macao',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Moçambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nutaaq Caledonia',
 			'NE' => 'Niger',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Hollandi',
 			'NO' => 'Norge',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nutaaq Zeelandi',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PG' => 'Papua Nutaaq Guinea',
 			'PK' => 'Pakistani',
 			'PL' => 'Poleni',
 			'PM' => 'Saint Pierre aamma Miquelon',
 			'PR' => 'Puerto Rico',
 			'PT' => 'Portugali',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Quatar',
 			'RE' => 'Réunion',
 			'RO' => 'Rumænia',
 			'RS' => 'Serbia',
 			'RU' => 'Ruslandi',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Arabia',
 			'SD' => 'Avannarleqsudan',
 			'SE' => 'Sverige',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard aamma Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Kujalleqsudan',
 			'ST' => 'São Tomé aamma Príncipe',
 			'SV' => 'El Salvador',
 			'SY' => 'Syria',
 			'SZ' => 'Swazilandi',
 			'TA' => 'Tristan da Cunha',
 			'TD' => 'Chad',
 			'TG' => 'Togo',
 			'TH' => 'Thailandi',
 			'TJ' => 'Tajikistani',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Kangilliit',
 			'TM' => 'Turkmenistani',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Tyrkia',
 			'TT' => 'Trinidad aamma Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'US' => 'Naalagaaffeqatigiit',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistani',
 			'VA' => 'Vatikani',
 			'VE' => 'Venezuela',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis aamma Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Kujalleqafrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => '(atorsinnaanngitsoq nunap imartaa nunataalu)',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'ullorsiut',
 			'currency' => 'akissaat',
 			'numbers' => 'normu',

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
 				'gregorian' => q{gregorianskit ullorsiutaat},
 			},
 			'numbers' => {
 				'fullwide' => q{atitooq atugartuut normu},
 				'latn' => q{atugartuut normu},
 				'roman' => q{ruumamiut-kisitsisaat},
 				'romanlow' => q{naqippoq ruumamiut-kisitsisaat},
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
			'metric' => q{SI},
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
			'language' => 'oqaatsit: {0}',
 			'script' => 'allaqqitaq: {0}',
 			'region' => 'nunap imartaa nunataalu: {0}',

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
			auxiliary => qr{[á â ã é ê ẽ í î ĩ ô õ ĸ ú û ũ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z æ ø å]},
			numbers => qr{[, . % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'], };
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
	default		=> qq{»},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{›},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‹},
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
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(Jordgravitationer),
						'one' => q({0} nutsuinera nunarsuaq),
						'other' => q({0} nutsuinera nunarsuaq),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(Jordgravitationer),
						'one' => q({0} nutsuinera nunarsuaq),
						'other' => q({0} nutsuinera nunarsuaq),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meteri per kvadratsekundi),
						'one' => q({0} meteri per kvadratsekundi),
						'other' => q({0} meteri per kvadratsekundi),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meteri per kvadratsekundi),
						'one' => q({0} meteri per kvadratsekundi),
						'other' => q({0} meteri per kvadratsekundi),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(bueminutsi),
						'one' => q({0} bueminutsi),
						'other' => q({0} bueminutsi),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bueminutsi),
						'one' => q({0} bueminutsi),
						'other' => q({0} bueminutsi),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(buesekundi),
						'one' => q({0} buesekundi),
						'other' => q({0} buesekundi),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(buesekundi),
						'one' => q({0} buesekundi),
						'other' => q({0} buesekundi),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gradi),
						'one' => q({0} gradi),
						'other' => q({0} gradi),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gradi),
						'one' => q({0} gradi),
						'other' => q({0} gradi),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiani),
						'one' => q({0} radiani),
						'other' => q({0} radiani),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiani),
						'one' => q({0} radiani),
						'other' => q({0} radiani),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(kaajaluitsoq),
						'one' => q({0} kaajaluitsoq),
						'other' => q({0} kaajaluitsoq),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(kaajaluitsoq),
						'one' => q({0} kaajaluitsoq),
						'other' => q({0} kaajaluitsoq),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(amerikanske tønde land),
						'one' => q({0} amerikanskt tønde land),
						'other' => q({0} amerikanske tønde land),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(amerikanske tønde land),
						'one' => q({0} amerikanskt tønde land),
						'other' => q({0} amerikanske tønde land),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektari),
						'one' => q({0} hektari),
						'other' => q({0} hektari),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektari),
						'one' => q({0} hektari),
						'other' => q({0} hektari),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(kvadratsentimeteri),
						'one' => q({0} kvadratsentimeteri),
						'other' => q({0} kvadratsentimeteri),
						'per' => q({0} per kvadratsentimeteri),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(kvadratsentimeteri),
						'one' => q({0} kvadratsentimeteri),
						'other' => q({0} kvadratsentimeteri),
						'per' => q({0} per kvadratsentimeteri),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kvadratfod),
						'one' => q({0} kvadratfod),
						'other' => q({0} kvadratfod),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadratfod),
						'one' => q({0} kvadratfod),
						'other' => q({0} kvadratfod),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kvadratkilometeri),
						'one' => q({0} kvadratkilometeri),
						'other' => q({0} kvadratkilometeri),
						'per' => q({0} per kvadratkilometeri),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kvadratkilometeri),
						'one' => q({0} kvadratkilometeri),
						'other' => q({0} kvadratkilometeri),
						'per' => q({0} per kvadratkilometeri),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(kvadratmeteri),
						'one' => q({0} kvadratmeteri),
						'other' => q({0} kvadratmeteri),
						'per' => q({0} per kvadratmeteri),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(kvadratmeteri),
						'one' => q({0} kvadratmeteri),
						'other' => q({0} kvadratmeteri),
						'per' => q({0} per kvadratmeteri),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(engelske kvadratmil),
						'one' => q({0} engelsk kvadratmil),
						'other' => q({0} engelske kvadratmil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(engelske kvadratmil),
						'one' => q({0} engelsk kvadratmil),
						'other' => q({0} engelske kvadratmil),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammi per desiliteri),
						'one' => q({0} milligrammi per desiliteri),
						'other' => q({0} milligrammi per desiliteri),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammi per desiliteri),
						'one' => q({0} milligrammi per desiliteri),
						'other' => q({0} milligrammi per desiliteri),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimoli per literi),
						'one' => q({0} millimoli per literi),
						'other' => q({0} millimoli per literi),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimoli per literi),
						'one' => q({0} millimoli per literi),
						'other' => q({0} millimoli per literi),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(millioni ilaa),
						'one' => q({0} millioni ilaa),
						'other' => q({0} millioni ilaa),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(millioni ilaa),
						'one' => q({0} millioni ilaa),
						'other' => q({0} millioni ilaa),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(literi per kilometeri),
						'one' => q({0} literi per kilometeri),
						'other' => q({0} literi per kilometeri),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(literi per kilometeri),
						'one' => q({0} literi per kilometeri),
						'other' => q({0} literi per kilometeri),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} kangiani),
						'north' => q({0} avannaani),
						'south' => q({0} kujataani),
						'west' => q({0} kitaani),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} kangiani),
						'north' => q({0} avannaani),
						'south' => q({0} kujataani),
						'west' => q({0} kitaani),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ulloq unnuarlu),
						'one' => q({0} ulloq unnuarlu),
						'other' => q({0} ulloq unnuarlu),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ulloq unnuarlu),
						'one' => q({0} ulloq unnuarlu),
						'other' => q({0} ulloq unnuarlu),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(nalunaaquttap-akunnera),
						'one' => q({0} nalunaaquttap-akunnera),
						'other' => q({0} nalunaaquttap-akunnera),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(nalunaaquttap-akunnera),
						'one' => q({0} nalunaaquttap-akunnera),
						'other' => q({0} nalunaaquttap-akunnera),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekundi),
						'one' => q({0} mikrosekundi),
						'other' => q({0} mikrosekundi),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekundi),
						'one' => q({0} mikrosekundi),
						'other' => q({0} mikrosekundi),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekundi),
						'one' => q({0} millisekundi),
						'other' => q({0} millisekundi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekundi),
						'one' => q({0} millisekundi),
						'other' => q({0} millisekundi),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutsi),
						'one' => q({0} minutsi),
						'other' => q({0} minutsi),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutsi),
						'one' => q({0} minutsi),
						'other' => q({0} minutsi),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(qaammat),
						'one' => q({0} qaammat),
						'other' => q({0} qaammat),
						'per' => q({0} per qaammat),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(qaammat),
						'one' => q({0} qaammat),
						'other' => q({0} qaammat),
						'per' => q({0} per qaammat),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekundi),
						'one' => q({0} nanosekundi),
						'other' => q({0} nanosekundi),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekundi),
						'one' => q({0} nanosekundi),
						'other' => q({0} nanosekundi),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekundi),
						'one' => q({0} sekundi),
						'other' => q({0} sekundi),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekundi),
						'one' => q({0} sekundi),
						'other' => q({0} sekundi),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sapaatip-akunnera),
						'one' => q({0} sapaatip-akunnera),
						'other' => q({0} sapaatip-akunnera),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sapaatip-akunnera),
						'one' => q({0} sapaatip-akunnera),
						'other' => q({0} sapaatip-akunnera),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ukioq),
						'one' => q({0} ukioq),
						'other' => q({0} ukioq),
						'per' => q({0} per ukioq),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ukioq),
						'one' => q({0} ukioq),
						'other' => q({0} ukioq),
						'per' => q({0} per ukioq),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centimeteri),
						'one' => q({0} centimeteri),
						'other' => q({0} centimeteri),
						'per' => q({0} per centimeteri),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimeteri),
						'one' => q({0} centimeteri),
						'other' => q({0} centimeteri),
						'per' => q({0} per centimeteri),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decimeteri),
						'one' => q({0} decimeteri),
						'other' => q({0} decimeteri),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decimeteri),
						'one' => q({0} decimeteri),
						'other' => q({0} decimeteri),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fod),
						'one' => q({0} fod),
						'other' => q({0} fod),
						'per' => q({0} per fod),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fod),
						'one' => q({0} fod),
						'other' => q({0} fod),
						'per' => q({0} per fod),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0} per tomme),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0} per tomme),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometeri),
						'one' => q({0} kilometeri),
						'other' => q({0} kilometeri),
						'per' => q({0} per kilometeri),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometeri),
						'one' => q({0} kilometeri),
						'other' => q({0} kilometeri),
						'per' => q({0} per kilometeri),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lysukioq),
						'one' => q({0} lysåri),
						'other' => q({0} lysåri),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lysukioq),
						'one' => q({0} lysåri),
						'other' => q({0} lysåri),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meteri),
						'one' => q({0} meteri),
						'other' => q({0} meteri),
						'per' => q({0} per meteri),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meteri),
						'one' => q({0} meteri),
						'other' => q({0} meteri),
						'per' => q({0} per meteri),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometeri),
						'one' => q({0} mikrometeri),
						'other' => q({0} mikrometeri),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometeri),
						'one' => q({0} mikrometeri),
						'other' => q({0} mikrometeri),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(engelske mil),
						'one' => q({0} engelsk mil),
						'other' => q({0} engelske mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(engelske mil),
						'one' => q({0} engelsk mil),
						'other' => q({0} engelske mil),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(svenskeq mili),
						'one' => q({0} svenskeq mili),
						'other' => q({0} svenskeq mili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(svenskeq mili),
						'one' => q({0} svenskeq mili),
						'other' => q({0} svenskeq mili),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimeteri),
						'one' => q({0} millimeteri),
						'other' => q({0} millimeteri),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimeteri),
						'one' => q({0} millimeteri),
						'other' => q({0} millimeteri),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometeri),
						'one' => q({0} nanometeri),
						'other' => q({0} nanometeri),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometeri),
						'one' => q({0} nanometeri),
						'other' => q({0} nanometeri),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sømili),
						'one' => q({0} sømili),
						'other' => q({0} sømili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sømili),
						'one' => q({0} sømili),
						'other' => q({0} sømili),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometeri),
						'one' => q({0} pikometeri),
						'other' => q({0} pikometeri),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometeri),
						'one' => q({0} pikometeri),
						'other' => q({0} pikometeri),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(engelske yard),
						'one' => q({0} engelsk yard),
						'other' => q({0} engelske yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(engelske yard),
						'one' => q({0} engelsk yard),
						'other' => q({0} engelske yard),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luksi),
						'one' => q({0} luksi),
						'other' => q({0} luksi),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luksi),
						'one' => q({0} luksi),
						'other' => q({0} luksi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grammi),
						'one' => q({0} grammi),
						'other' => q({0} grammi),
						'per' => q({0} per grammi),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grammi),
						'one' => q({0} grammi),
						'other' => q({0} grammi),
						'per' => q({0} per grammi),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogrammi),
						'one' => q({0} kilogrammi),
						'other' => q({0} kilogrammi),
						'per' => q({0} per kilogrammi),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogrammi),
						'one' => q({0} kilogrammi),
						'other' => q({0} kilogrammi),
						'per' => q({0} per kilogrammi),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(tonni),
						'one' => q({0} tonni),
						'other' => q({0} tonni),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(tonni),
						'one' => q({0} tonni),
						'other' => q({0} tonni),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(skålpund),
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(skålpund),
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hestekrafter),
						'one' => q({0} hestekraft),
						'other' => q({0} hestekrafter),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hestekrafter),
						'one' => q({0} hestekraft),
						'other' => q({0} hestekrafter),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatti),
						'one' => q({0} kilowatti),
						'other' => q({0} kilowatti),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatti),
						'one' => q({0} kilowatti),
						'other' => q({0} kilowatti),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watti),
						'one' => q({0} watti),
						'other' => q({0} watti),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watti),
						'one' => q({0} watti),
						'other' => q({0} watti),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopascali),
						'one' => q({0} hektopascali),
						'other' => q({0} hektopascali),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopascali),
						'one' => q({0} hektopascali),
						'other' => q({0} hektopascali),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(tommer kviksølv),
						'one' => q({0} tomme kviksølv),
						'other' => q({0} tommer kviksølv),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tommer kviksølv),
						'one' => q({0} tomme kviksølv),
						'other' => q({0} tommer kviksølv),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibari),
						'one' => q({0} millibari),
						'other' => q({0} millibari),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibari),
						'one' => q({0} millibari),
						'other' => q({0} millibari),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometeri per nalunaaquttap-akunnera),
						'one' => q({0} kilometeri per nalunaaquttap-akunnera),
						'other' => q({0} kilometeri per nalunaaquttap-akunnera),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometeri per nalunaaquttap-akunnera),
						'one' => q({0} kilometeri per nalunaaquttap-akunnera),
						'other' => q({0} kilometeri per nalunaaquttap-akunnera),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meteri per sekundi),
						'one' => q({0} meteri per sekundi),
						'other' => q({0} meteri per sekundi),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meteri per sekundi),
						'one' => q({0} meteri per sekundi),
						'other' => q({0} meteri per sekundi),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(engelske mil per nalunaaquttap-akunnera),
						'one' => q({0} engelsk mil per nalunaaquttap-akunnera),
						'other' => q({0} engelske mil per nalunaaquttap-akunnera),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(engelske mil per nalunaaquttap-akunnera),
						'one' => q({0} engelsk mil per nalunaaquttap-akunnera),
						'other' => q({0} engelske mil per nalunaaquttap-akunnera),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gradi Celsius),
						'one' => q({0} gradi Celsius),
						'other' => q({0} gradi Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gradi Celsius),
						'one' => q({0} gradi Celsius),
						'other' => q({0} gradi Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(gradi Fahrenheit),
						'one' => q({0} gradi Fahrenheit),
						'other' => q({0} gradi Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(gradi Fahrenheit),
						'one' => q({0} gradi Fahrenheit),
						'other' => q({0} gradi Fahrenheit),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentiliteri),
						'one' => q({0} sentiliteri),
						'other' => q({0} sentiliteri),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentiliteri),
						'one' => q({0} sentiliteri),
						'other' => q({0} sentiliteri),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kubikkilometeri),
						'one' => q({0} kubikkilometeri),
						'other' => q({0} kubikkilometeri),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kubikkilometeri),
						'one' => q({0} kubikkilometeri),
						'other' => q({0} kubikkilometeri),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(engelske kubikmil),
						'one' => q({0} engelsk kubikmil),
						'other' => q({0} engelske kubikmil),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(engelske kubikmil),
						'one' => q({0} engelsk kubikmil),
						'other' => q({0} engelske kubikmil),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desiliteri),
						'one' => q({0} desiliteri),
						'other' => q({0} desiliteri),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desiliteri),
						'one' => q({0} desiliteri),
						'other' => q({0} desiliteri),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hectoliteri),
						'one' => q({0} hectoliteri),
						'other' => q({0} hectoliteri),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hectoliteri),
						'one' => q({0} hectoliteri),
						'other' => q({0} hectoliteri),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(literi),
						'one' => q({0} literi),
						'other' => q({0} literi),
						'per' => q({0} per literi),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(literi),
						'one' => q({0} literi),
						'other' => q({0} literi),
						'per' => q({0} per literi),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliteri),
						'one' => q({0} megaliteri),
						'other' => q({0} megaliteri),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliteri),
						'one' => q({0} megaliteri),
						'other' => q({0} megaliteri),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(milliliteri),
						'one' => q({0} milliliteri),
						'other' => q({0} milliliteri),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(milliliteri),
						'one' => q({0} milliliteri),
						'other' => q({0} milliliteri),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(alussaatip imai),
						'one' => q({0} alussaatip imai),
						'other' => q({0} alussaatip imai),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(alussaatip imai),
						'one' => q({0} alussaatip imai),
						'other' => q({0} alussaatip imai),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(alussaateeqqap imai),
						'one' => q({0} alussaateeqqap imai),
						'other' => q({0} alussaateeqqap imai),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(alussaateeqqap imai),
						'one' => q({0} alussaateeqqap imai),
						'other' => q({0} alussaateeqqap imai),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(kaaj),
						'one' => q({0}kaaj),
						'other' => q({0}kaaj),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(kaaj),
						'one' => q({0}kaaj),
						'other' => q({0}kaaj),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(millioni ilaa),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(millioni ilaa),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}Ø),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}Ø),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}mån),
						'other' => q({0}mån),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}mån),
						'other' => q({0}mån),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0}u),
						'other' => q({0}u),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0}u),
						'other' => q({0}u),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}uk),
						'other' => q({0}uk),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}uk),
						'other' => q({0}uk),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} fod),
						'other' => q({0} fod),
						'per' => q({0}/fod),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} fod),
						'other' => q({0} fod),
						'per' => q({0}/fod),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0}/tomme),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0}/tomme),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} lå),
						'other' => q({0} lå),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} lå),
						'other' => q({0} lå),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(sv. mili),
						'one' => q({0} sv.mili),
						'other' => q({0} sv.mili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(sv. mili),
						'one' => q({0} sv.mili),
						'other' => q({0} sv.mili),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sømili),
						'one' => q({0} sømili),
						'other' => q({0} sømili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sømili),
						'one' => q({0} sømili),
						'other' => q({0} sømili),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(tonni),
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(tonni),
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}hk),
						'other' => q({0}hk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}hk),
						'other' => q({0}hk),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliteri),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliteri),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ssk),
						'one' => q({0} ssk),
						'other' => q({0} ssk),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ssk),
						'one' => q({0} ssk),
						'other' => q({0} ssk),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(Jordgravitationer),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(Jordgravitationer),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(bueminutsi),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bueminutsi),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(buesekundi),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(buesekundi),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gradi),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gradi),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(kaaj),
						'one' => q({0} kaaj),
						'other' => q({0} kaaj),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(kaaj),
						'one' => q({0} kaaj),
						'other' => q({0} kaaj),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(amerikanske tønde land),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(amerikanske tønde land),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektari),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektari),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kvadratfod),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadratfod),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kvadratkilometeri),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kvadratkilometeri),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(kvadratmeteri),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(kvadratmeteri),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(engelske kvadratmil),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(engelske kvadratmil),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(millioni ilaa),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(millioni ilaa),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ø),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ø),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ulloq unnuarlu),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ulloq unnuarlu),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(nalunaaquttap-akunnera),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(nalunaaquttap-akunnera),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekundi),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekundi),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutsi),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutsi),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(qaammat),
						'one' => q({0} mån),
						'other' => q({0} mån),
						'per' => q({0}/mån),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(qaammat),
						'one' => q({0} mån),
						'other' => q({0} mån),
						'per' => q({0}/mån),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekundi),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekundi),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sapaatip-akunnera),
						'one' => q({0} u),
						'other' => q({0} u),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sapaatip-akunnera),
						'one' => q({0} u),
						'other' => q({0} u),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ukioq),
						'one' => q({0} ukioq),
						'other' => q({0} ukioq),
						'per' => q({0}/ukioq),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ukioq),
						'one' => q({0} ukioq),
						'other' => q({0} ukioq),
						'per' => q({0}/ukioq),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centimeteri),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centimeteri),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fod),
						'one' => q({0} fod),
						'other' => q({0} fod),
						'per' => q({0}/fod),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fod),
						'one' => q({0} fod),
						'other' => q({0} fod),
						'per' => q({0}/fod),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0}/tomme),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0}/tomme),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometeri),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometeri),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lysukioq),
						'one' => q({0} lysåri),
						'other' => q({0} lysåri),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lysukioq),
						'one' => q({0} lysåri),
						'other' => q({0} lysåri),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meteri),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meteri),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(engelske mil),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(engelske mil),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(svenskeq mili),
						'one' => q({0} svenskeq mili),
						'other' => q({0} svenskeq mili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(svenskeq mili),
						'one' => q({0} svenskeq mili),
						'other' => q({0} svenskeq mili),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimeteri),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimeteri),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sømili),
						'one' => q({0} sømili),
						'other' => q({0} sømili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sømili),
						'one' => q({0} sømili),
						'other' => q({0} sømili),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometeri),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometeri),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(engelske yard),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(engelske yard),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luksi),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luksi),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grammi),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grammi),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogrammi),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogrammi),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(tonni),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(tonni),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(skålpund),
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(skålpund),
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hestekrafter),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hestekrafter),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatti),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatti),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watti),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watti),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopascali),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopascali),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(tommer kviksølv),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tommer kviksølv),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibari),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibari),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometeri per nalunaaquttap-akunnera),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometeri per nalunaaquttap-akunnera),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meteri per sekundi),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meteri per sekundi),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(engelske mil per nalunaaquttap-akunnera),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(engelske mil per nalunaaquttap-akunnera),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gradi Celsius),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gradi Celsius),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(gradi Fahrenheit),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(gradi Fahrenheit),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kubikkilometeri),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kubikkilometeri),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(engelske kubikmil),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(engelske kubikmil),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(literi),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(literi),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliteri),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliteri),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ssk),
						'one' => q({0} ssk),
						'other' => q({0} ssk),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ssk),
						'one' => q({0} ssk),
						'other' => q({0} ssk),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:aap|a|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:naagga|n)$' }
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

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(×10^),
			'group' => q(.),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(−),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
			'default' => {
				'1000' => {
					'one' => '0 td',
					'other' => '0 td',
				},
				'10000' => {
					'one' => '00 td',
					'other' => '00 td',
				},
				'100000' => {
					'one' => '000 td',
					'other' => '000 td',
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 tusind',
					'other' => '0 tusind',
				},
				'10000' => {
					'one' => '00 tusind',
					'other' => '00 tusind',
				},
				'100000' => {
					'one' => '000 tusind',
					'other' => '000 tusind',
				},
				'1000000' => {
					'one' => '0 million',
					'other' => '0 millioner',
				},
				'10000000' => {
					'one' => '00 million',
					'other' => '00 millioner',
				},
				'100000000' => {
					'one' => '000 million',
					'other' => '000 millioner',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliarder',
				},
				'10000000000' => {
					'one' => '00 milliard',
					'other' => '00 milliarder',
				},
				'100000000000' => {
					'one' => '000 milliard',
					'other' => '000 milliarder',
				},
				'1000000000000' => {
					'one' => '0 billion',
					'other' => '0 billioner',
				},
				'10000000000000' => {
					'one' => '00 billion',
					'other' => '00 billioner',
				},
				'100000000000000' => {
					'one' => '000 billion',
					'other' => '000 billioner',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 td',
					'other' => '0 td',
				},
				'10000' => {
					'one' => '00 td',
					'other' => '00 td',
				},
				'100000' => {
					'one' => '000 td',
					'other' => '000 td',
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
						'negative' => '¤-#,##0.00',
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
		'DKK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(danmarkimut koruuni),
				'one' => q(danskinut koruuni),
				'other' => q(danmarkimut koruuni),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'NOK' => {
			symbol => 'Nkr',
			display_name => {
				'currency' => q(norskit koruuni),
				'one' => q(norskit koruuni),
				'other' => q(norskit koruuni),
			},
		},
		'SEK' => {
			symbol => 'Skr',
			display_name => {
				'currency' => q(svenskit koruuni),
				'one' => q(svenskit koruuni),
				'other' => q(svenskit koruuni),
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
							'jan',
							'febr',
							'mar',
							'apr',
							'maj',
							'jun',
							'jul',
							'aug',
							'sept',
							'okt',
							'nov',
							'dec'
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
							'januaarip',
							'februaarip',
							'marsip',
							'apriilip',
							'maajip',
							'juunip',
							'juulip',
							'aggustip',
							'septembarip',
							'oktobarip',
							'novembarip',
							'decembarip'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan',
							'febr',
							'mar',
							'apr',
							'maj',
							'jun',
							'jul',
							'aug',
							'sept',
							'okt',
							'nov',
							'dec'
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
							'januaari',
							'februaari',
							'marsi',
							'apriili',
							'maaji',
							'juuni',
							'juuli',
							'aggusti',
							'septembari',
							'oktobari',
							'novembari',
							'decembari'
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
						mon => 'ata',
						tue => 'mar',
						wed => 'pin',
						thu => 'sis',
						fri => 'tal',
						sat => 'arf',
						sun => 'sap'
					},
					short => {
						mon => 'ata',
						tue => 'mar',
						wed => 'pin',
						thu => 'sis',
						fri => 'tal',
						sat => 'arf',
						sun => 'sap'
					},
					wide => {
						mon => 'ataasinngorneq',
						tue => 'marlunngorneq',
						wed => 'pingasunngorneq',
						thu => 'sisamanngorneq',
						fri => 'tallimanngorneq',
						sat => 'arfininngorneq',
						sun => 'sapaat'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'A',
						tue => 'M',
						wed => 'P',
						thu => 'S',
						fri => 'T',
						sat => 'A',
						sun => 'S'
					},
					short => {
						mon => 'ata',
						tue => 'mar',
						wed => 'pin',
						thu => 'sis',
						fri => 'tal',
						sat => 'arf',
						sun => 'sap'
					},
					wide => {
						mon => 'ataasinngorneq',
						tue => 'marlunngorneq',
						wed => 'pingasunngorneq',
						thu => 'sisamanngorneq',
						fri => 'tallimanngorneq',
						sat => 'arfininngorneq',
						sun => 'sapaat'
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
					abbreviated => {0 => 'S1',
						1 => 'S2',
						2 => 'S3',
						3 => 'S4'
					},
					narrow => {0 => 'S1',
						1 => 'S2',
						2 => 'S3',
						3 => 'S4'
					},
					wide => {0 => 'ukiup sisamararterutaa 1',
						1 => 'ukiup sisamararterutaa 2',
						2 => 'ukiup sisamararterutaa 3',
						3 => 'ukiup sisamararterutaa 4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'S1',
						1 => 'S2',
						2 => 'S3',
						3 => 'S4'
					},
					narrow => {0 => 'S1',
						1 => 'S2',
						2 => 'S3',
						3 => 'S4'
					},
					wide => {0 => 'ukiup sisamararterutaa 1',
						1 => 'ukiup sisamararterutaa 2',
						2 => 'ukiup sisamararterutaa 3',
						3 => 'ukiup sisamararterutaa 4'
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
					'am' => q{u.t.},
					'pm' => q{u.k.},
				},
				'wide' => {
					'am' => q{ulloqeqqata-tungaa},
					'pm' => q{ulloqeqqata-kingorna},
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
				'0' => 'Kr.in.si.',
				'1' => 'Kr.in.king.'
			},
			narrow => {
				'0' => 'Kr.s.',
				'1' => 'Kr.k.'
			},
			wide => {
				'0' => 'Kristusip inunngornerata siornagut',
				'1' => 'Kristusip inunngornerata kingornagut'
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
			'full' => q{EEEE dd MMMM y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE dd MMMM y},
			'long' => q{dd MMMM y},
			'medium' => q{dd MMM y},
			'short' => q{y-MM-dd},
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
			'full' => q{HH.mm.ss zzzz},
			'long' => q{HH.mm.ss z},
			'medium' => q{HH.mm.ss},
			'short' => q{HH.mm},
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
			Ed => q{E, d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			yM => q{y-MM},
			yMEd => q{E, y-MM-dd},
			yMMM => q{LLL y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{dd MMM y},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQQ},
			yQQQQ => q{y QQQQ},
		},
		'gregorian' => {
			Ed => q{E, d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			yM => q{y-MM},
			yMEd => q{E, y-MM-dd},
			yMMM => q{LLL y},
			yMMMEd => q{E, dd MMM y},
			yMMMd => q{dd MMM y},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQQ},
			yQQQQ => q{y QQQQ},
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
				M => q{E, MM-dd – E, MM-dd},
				d => q{E, MM-dd – E, MM-dd},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, MM-d – E, MM-d},
				d => q{E, MM-d – E, MM-d},
			},
			MMMd => {
				M => q{MM-d – MM-d},
				d => q{MM-d – d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – dd},
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
				M => q{y-MM – MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMM => {
				M => q{y-MM – MM},
				y => q{y-MM – y-MM},
			},
			yMMMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMMM => {
				M => q{y-MM – MM},
				y => q{y-MM – y-MM},
			},
			yMMMd => {
				M => q{y-MM-dd – MM-d},
				d => q{y-MM-d – d},
				y => q{y-MM-dd – y-MM-dd},
			},
			yMd => {
				M => q{y-MM-dd – MM-dd},
				d => q{y-MM-dd – dd},
				y => q{y-MM-dd – y-MM-dd},
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
				M => q{E, MM-dd – E, MM-dd},
				d => q{E, MM-dd – E, MM-dd},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, MM-d – E, MM-d},
				d => q{E, MM-d – E, MM-d},
			},
			MMMd => {
				M => q{MM-d – MM-d},
				d => q{MM-d – d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – dd},
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
				M => q{y-MM – MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMM => {
				M => q{y-MM – MM},
				y => q{y-MM – y-MM},
			},
			yMMMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMMM => {
				M => q{y-MM – MM},
				y => q{y-MM – y-MM},
			},
			yMMMd => {
				M => q{y-MM-dd – MM-d},
				d => q{y-MM-d – d},
				y => q{y-MM-dd – y-MM-dd},
			},
			yMd => {
				M => q{y-MM-dd – MM-dd},
				d => q{y-MM-dd – dd},
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
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		fallbackFormat => q({0} ({1})),
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Thule' => {
			exemplarCity => q#Qaanaaq#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#atorsinnaanngitsoq nalunaaqutaqaqatigiissut#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
