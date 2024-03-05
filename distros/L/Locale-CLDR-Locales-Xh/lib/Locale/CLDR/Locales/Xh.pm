=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Xh - Package for language Xhosa

=cut

package Locale::CLDR::Locales::Xh;
# This file auto generated from Data\common\main\xh.xml
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
				'af' => 'isiBhulu',
 				'am' => 'Isi-Amharic',
 				'ar' => 'Isi-Arabhu',
 				'ar_001' => 'Isi-Arabhu (Sale mihla)',
 				'as' => 'isiAssamese',
 				'az' => 'Isi-Azerbaijani',
 				'be' => 'Isi-Belarusian',
 				'bg' => 'Isi-Bulgaria',
 				'bn' => 'IsiBangla',
 				'br' => 'Breton',
 				'bs' => 'Isi-Bosnia',
 				'ca' => 'Isi-Calatan',
 				'cs' => 'Isi-Czech',
 				'cy' => 'Isi-Welsh',
 				'da' => 'Isi-Danish',
 				'de' => 'IsiJamani',
 				'de_AT' => 'IsiJamani Sase-Austria',
 				'de_CH' => 'IsiJamani Esiyi-High Swiss',
 				'el' => 'Isi-Greek',
 				'en' => 'IsiNgesi',
 				'en_AU' => 'IsiNgesi Sase-Australia',
 				'en_CA' => 'IsiNgesi SaseKhanada',
 				'en_GB' => 'IsiNgesi SaseBritane',
 				'en_GB@alt=short' => 'IsiNgesi sase-UK',
 				'en_US' => 'Isingesi SaseMelika',
 				'en_US@alt=short' => 'IsiNgesi Sase-US',
 				'eo' => 'Isi-Esperanto',
 				'es' => 'Isi-Spanish',
 				'es_419' => 'IsiSpanish SaseLatin America',
 				'es_ES' => 'IsiSpanish SaseYurophu',
 				'es_MX' => 'IsiSpanish SaseMexico',
 				'et' => 'Isi-Estonian',
 				'eu' => 'Isi-Basque',
 				'fa' => 'Isi-Persia',
 				'fi' => 'Isi-Finnish',
 				'fil' => 'Isi-Taglog',
 				'fo' => 'Isi-Faroese',
 				'fr' => 'IsiFrentshi',
 				'fr_CA' => 'IsiFrentshi SaseKhanada',
 				'fr_CH' => 'IsiFrentshi SaseSwitzerland',
 				'fy' => 'Isi-Frisian',
 				'ga' => 'Isi-Irish',
 				'gd' => 'Scots Gaelic',
 				'gl' => 'Isi-Galician',
 				'gn' => 'Guarani',
 				'gu' => 'Isi-Gujarati',
 				'he' => 'Isi-Hebrew',
 				'hi' => 'IsiHindi',
 				'hi_Latn' => 'IsiHindi (Latin)',
 				'hi_Latn@alt=variant' => 'IsiHinglish',
 				'hr' => 'Isi-Croatia',
 				'hu' => 'Isi-Hungarian',
 				'hy' => 'isiArmenian',
 				'ia' => 'Interlingua',
 				'id' => 'Isi-Indonesia',
 				'ie' => 'isiInterlingue',
 				'is' => 'Isi-Icelandic',
 				'it' => 'IsiTaliyane',
 				'ja' => 'IsiJapan',
 				'jv' => 'Isi-Javanese',
 				'ka' => 'Isi-Georgia',
 				'km' => 'isiCambodia',
 				'kn' => 'Isi-Kannada',
 				'ko' => 'Isi-Korean',
 				'ku' => 'Kurdish',
 				'ky' => 'Kyrgyz',
 				'la' => 'Isi-Latin',
 				'ln' => 'Iilwimi',
 				'lo' => 'IsiLoathian',
 				'lt' => 'Isi-Lithuanian',
 				'lv' => 'Isi-Latvian',
 				'mk' => 'Isi-Macedonian',
 				'ml' => 'Isi-Malayalam',
 				'mn' => 'IsiMongolian',
 				'mr' => 'Isi-Marathi',
 				'ms' => 'Isi-Malay',
 				'mt' => 'Isi-Maltese',
 				'ne' => 'Isi-Nepali',
 				'nl' => 'IsiDatshi',
 				'nl_BE' => 'IsiFlemish',
 				'nn' => 'Isi-Norwegia (Nynorsk)',
 				'no' => 'Isi-Norwegian',
 				'oc' => 'Iso-Occitan',
 				'or' => 'Oriya',
 				'pa' => 'Isi-Punjabi',
 				'pl' => 'Isi-Polish',
 				'ps' => 'Pashto',
 				'pt' => 'IsiPhuthukezi',
 				'pt_BR' => 'IsiPhuthukezi SaseBrazil',
 				'pt_PT' => 'IsiPhuthukezi SasePortugal',
 				'ro' => 'Isi-Romanian',
 				'ru' => 'Isi-Russian',
 				'sa' => 'iSanskrit',
 				'sd' => 'isiSindhi',
 				'sh' => 'Serbo-Croatian',
 				'si' => 'Isi-Sinhalese',
 				'sk' => 'Isi-Slovak',
 				'sl' => 'Isi-Slovenian',
 				'so' => 'IsiSomaliya',
 				'sq' => 'Isi-Albania',
 				'sr' => 'Isi-Serbia',
 				'st' => 'Sesotho',
 				'su' => 'Isi-Sudanese',
 				'sv' => 'Isi-Swedish',
 				'sw' => 'Isi-Swahili',
 				'ta' => 'Isi-Tamil',
 				'te' => 'Isi-Telegu',
 				'th' => 'Isi-Thai',
 				'ti' => 'Isi-Tigrinya',
 				'tk' => 'Turkmen',
 				'tlh' => 'Klingon',
 				'tr' => 'Isi-Turkish',
 				'tw' => 'Twi',
 				'ug' => 'Isi Uighur',
 				'uk' => 'Isi-Ukranian',
 				'und' => 'Unknown language',
 				'ur' => 'Urdu',
 				'uz' => 'Isi-Uzbek',
 				'vi' => 'Isi-Vietnamese',
 				'xh' => 'IsiXhosa',
 				'yi' => 'Yiddish',
 				'zh' => 'IsiMandarin',
 				'zh@alt=menu' => 'IsiTshayina, IsiMandarin',
 				'zh_Hans' => 'IsiTshayina Esenziwe Lula',
 				'zh_Hans@alt=long' => 'IsiMandarin Esenziwe Lula',
 				'zh_Hant' => 'IsiTshayina Esiqhelekileyo',
 				'zh_Hant@alt=long' => 'IsiMandarin Esiqhelekileyo',
 				'zu' => 'isiZulu',

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
			'Arab' => 'Isi-Arabhu',
 			'Cyrl' => 'IsiCyrillic',
 			'Hans' => 'IsiHans Esenziwe Lula',
 			'Hans@alt=stand-alone' => 'IsiHan Esenziwe Lula',
 			'Hant' => 'IsiHant Esiqhelekileyo',
 			'Hant@alt=stand-alone' => 'IsiHan Esiqhelekileyo',
 			'Jpan' => 'IsiJapanese',
 			'Kore' => 'IsiKorean',
 			'Latn' => 'IsiLatin',
 			'Zxxx' => 'Engabhalwanga',
 			'Zzzz' => 'Ulwimi Olungaziwayo',

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
			'001' => 'ihlabathi',
 			'002' => 'IAfrika',
 			'003' => 'UMntla Melika',
 			'005' => 'UMzantsi Melika',
 			'009' => 'E-Oceania',
 			'011' => 'INtshona Afrika',
 			'013' => 'UMbindi Melika',
 			'014' => 'IMpuma Afrika',
 			'015' => 'UMntla Afrika',
 			'017' => 'UMbindi Afrika',
 			'018' => 'EMazantsi e-Afrika',
 			'019' => 'EMzantsi Melika',
 			'021' => 'EMantla Melika',
 			'029' => 'ECaribbean',
 			'030' => 'IMpuma Asia',
 			'034' => 'UMzantsi Asia',
 			'035' => 'UMzantsi-mpuma Asia',
 			'039' => 'UMzantsi Yurophu',
 			'053' => 'I-Australasia',
 			'054' => 'IMelanasia',
 			'057' => 'UMmandla weMicronesia',
 			'061' => 'I-Polynesia',
 			'142' => 'E-Asia',
 			'143' => 'UMbindi Asia',
 			'145' => 'INtshona Asia',
 			'150' => 'EYurophu',
 			'151' => 'IMpuma Yurophu',
 			'154' => 'UMntla Yurophu',
 			'155' => 'INtshona Yurophu',
 			'202' => 'UMzantsi weSahara',
 			'419' => 'ILatin America',
 			'AC' => 'E-Ascension Island',
 			'AD' => 'E-Andorra',
 			'AE' => 'E-United Arab Emirates',
 			'AF' => 'E-Afghanistan',
 			'AG' => 'E-Antigua & Barbuda',
 			'AI' => 'E-Anguilla',
 			'AL' => 'E-Albania',
 			'AM' => 'E-Armenia',
 			'AO' => 'E-Angola',
 			'AQ' => 'E-Antarctica',
 			'AR' => 'E-Argentina',
 			'AS' => 'E-American Samoa',
 			'AT' => 'E-Austria',
 			'AU' => 'E-Australia',
 			'AW' => 'E-Aruba',
 			'AX' => 'E-Åland Islands',
 			'AZ' => 'E-Azerbaijan',
 			'BA' => 'EBosnia & Herzegovina',
 			'BB' => 'EBarbados',
 			'BD' => 'EBangladesh',
 			'BE' => 'EBelgium',
 			'BF' => 'EBurkina Faso',
 			'BG' => 'EBulgaria',
 			'BH' => 'EBahrain',
 			'BI' => 'EBurundi',
 			'BJ' => 'EBenin',
 			'BL' => 'ESt. Barthélemy',
 			'BM' => 'EBermuda',
 			'BN' => 'eBrunei',
 			'BO' => 'EBolivia',
 			'BQ' => 'ECaribbean Netherlands',
 			'BR' => 'EBrazil',
 			'BS' => 'EBahamas',
 			'BT' => 'EBhutan',
 			'BV' => 'EBouvet Island',
 			'BW' => 'EBotswana',
 			'BY' => 'EBelarus',
 			'BZ' => 'EBelize',
 			'CA' => 'EKhanada',
 			'CC' => 'ECocos (Keeling) Islands',
 			'CD' => 'ECongo -Kinshasa',
 			'CD@alt=variant' => 'ECongo (DRC)',
 			'CF' => 'ECentral African Republic',
 			'CG' => 'ECongo - Brazzaville',
 			'CG@alt=variant' => 'ECongo (Republic)',
 			'CH' => 'ESwitzerland',
 			'CI' => 'ECôte d’Ivoire',
 			'CI@alt=variant' => 'E-Ivory Coast',
 			'CK' => 'ECook Islands',
 			'CL' => 'EChile',
 			'CM' => 'ECameroon',
 			'CN' => 'ETshayina',
 			'CO' => 'EColombia',
 			'CP' => 'EClipperton Island',
 			'CR' => 'ECosta Rica',
 			'CU' => 'ECuba',
 			'CV' => 'ECape Verde',
 			'CW' => 'ECuraçao',
 			'CX' => 'EChristmas Island',
 			'CY' => 'ECyprus',
 			'CZ' => 'ECzechia',
 			'CZ@alt=variant' => 'ECzech Republic',
 			'DE' => 'EJamani',
 			'DG' => 'EDiego Garcia',
 			'DJ' => 'EDjibouti',
 			'DK' => 'EDenmark',
 			'DM' => 'EDominica',
 			'DO' => 'EDominican Republic',
 			'DZ' => 'E-Algeria',
 			'EA' => 'ECeuta & Melilla',
 			'EC' => 'EEcuador',
 			'EE' => 'E-Estonia',
 			'EG' => 'IYiputa',
 			'EH' => 'EWestern Sahara',
 			'ER' => 'E-Eritrea',
 			'ES' => 'ESpain',
 			'ET' => 'E-Ethiopia',
 			'EU' => 'I-European Union',
 			'EZ' => 'I-Eurozone',
 			'FI' => 'EFinland',
 			'FJ' => 'EFiji',
 			'FK' => 'EFalkland Islands',
 			'FK@alt=variant' => 'EFalkland Islands (Islas Malvinas)',
 			'FM' => 'EMicronesia',
 			'FO' => 'EFaroe Islands',
 			'FR' => 'EFrance',
 			'GA' => 'EGabon',
 			'GB' => 'E-United Kingdom',
 			'GB@alt=short' => 'E-UK',
 			'GD' => 'EGrenada',
 			'GE' => 'EGeorgia',
 			'GF' => 'EFrench Guiana',
 			'GG' => 'EGuernsey',
 			'GH' => 'EGhana',
 			'GI' => 'EGibraltar',
 			'GL' => 'EGreenland',
 			'GM' => 'EGambia',
 			'GN' => 'EGuinea',
 			'GP' => 'EGuadeloupe',
 			'GQ' => 'E-Equatorial Guinea',
 			'GR' => 'EGreece',
 			'GS' => 'ESouth Georgia & South Sandwich Islands',
 			'GT' => 'EGuatemala',
 			'GU' => 'EGuam',
 			'GW' => 'EGuinea-Bissau',
 			'GY' => 'EGuyana',
 			'HK' => 'EHong Kong SAR China',
 			'HK@alt=short' => 'EHong Kong',
 			'HM' => 'EHeard & McDonald Islands',
 			'HN' => 'EHonduras',
 			'HR' => 'ECroatia',
 			'HT' => 'EHaiti',
 			'HU' => 'EHungary',
 			'IC' => 'ECanary Islands',
 			'ID' => 'E-Indonesia',
 			'IE' => 'E-Ireland',
 			'IL' => 'E-Israel',
 			'IM' => 'E-Isle of Man',
 			'IN' => 'E-Indiya',
 			'IO' => 'EBritish Indian Ocean Territory',
 			'IO@alt=chagos' => 'EChagos Archipelago',
 			'IQ' => 'E-Iraq',
 			'IR' => 'E-Iran',
 			'IS' => 'E-Iceland',
 			'IT' => 'E-Italy',
 			'JE' => 'EJersey',
 			'JM' => 'EJamaica',
 			'JO' => 'EJordan',
 			'JP' => 'EJapan',
 			'KE' => 'EKenya',
 			'KG' => 'EKyrgyzstan',
 			'KH' => 'ECambodia',
 			'KI' => 'EKiribati',
 			'KM' => 'EComoros',
 			'KN' => 'ESt. Kitts & Nevis',
 			'KP' => 'EMntla Korea',
 			'KR' => 'EMzantsi Korea',
 			'KW' => 'EKuwait',
 			'KY' => 'ECayman Islands',
 			'KZ' => 'EKazakhstan',
 			'LA' => 'ELaos',
 			'LB' => 'ELebanon',
 			'LC' => 'ESt. Lucia',
 			'LI' => 'ELiechtenstein',
 			'LK' => 'ESri Lanka',
 			'LR' => 'ELiberia',
 			'LS' => 'ELesotho',
 			'LT' => 'ELithuania',
 			'LU' => 'ELuxembourg',
 			'LV' => 'ELatvia',
 			'LY' => 'ELibya',
 			'MA' => 'EMorocco',
 			'MC' => 'EMonaco',
 			'MD' => 'EMoldova',
 			'ME' => 'EMontenegro',
 			'MF' => 'ESt. Martin',
 			'MG' => 'EMadagascar',
 			'MH' => 'EMarshall Islands',
 			'MK' => 'EMntla Macedonia',
 			'ML' => 'EMali',
 			'MM' => 'EMyanmar (Burma)',
 			'MN' => 'EMongolia',
 			'MO' => 'EMacao SAR China',
 			'MO@alt=short' => 'EMacao',
 			'MP' => 'ENorthern Mariana Islands',
 			'MQ' => 'EMartinique',
 			'MR' => 'EMauritania',
 			'MS' => 'EMontserrat',
 			'MT' => 'EMalta',
 			'MU' => 'EMauritius',
 			'MV' => 'EMaldives',
 			'MW' => 'EMalawi',
 			'MX' => 'EMexico',
 			'MY' => 'EMalaysia',
 			'MZ' => 'EMozambique',
 			'NA' => 'ENamibia',
 			'NC' => 'ENew Caledonia',
 			'NE' => 'ENiger',
 			'NF' => 'ENorfolk Island',
 			'NG' => 'ENigeria',
 			'NI' => 'ENicaragua',
 			'NL' => 'ENetherlands',
 			'NO' => 'ENorway',
 			'NP' => 'ENepal',
 			'NR' => 'ENauru',
 			'NU' => 'ENiue',
 			'NZ' => 'ENew Zealand',
 			'NZ@alt=variant' => 'E-Aotearoa New Zealand',
 			'OM' => 'E-Oman',
 			'PA' => 'EPanama',
 			'PE' => 'EPeru',
 			'PF' => 'EFrench Polynesia',
 			'PG' => 'EPapua New Guinea',
 			'PH' => 'EPhilippines',
 			'PK' => 'EPakistan',
 			'PL' => 'EPoland',
 			'PM' => 'ESt. Pierre & Miquelon',
 			'PN' => 'EPitcairn Islands',
 			'PR' => 'EPuerto Rico',
 			'PS' => 'IPalestinian Territories',
 			'PS@alt=short' => 'EPalestina',
 			'PT' => 'EPortugal',
 			'PW' => 'EPalau',
 			'PY' => 'EParaguay',
 			'QA' => 'EQatar',
 			'QO' => 'I-Oceania Esemaphandleni',
 			'RE' => 'ERéunion',
 			'RO' => 'ERomania',
 			'RS' => 'ESerbia',
 			'RU' => 'ERashiya',
 			'RW' => 'ERwanda',
 			'SA' => 'ESaudi Arabia',
 			'SB' => 'ESolomon Islands',
 			'SC' => 'ESeychelles',
 			'SD' => 'ESudan',
 			'SE' => 'ESweden',
 			'SG' => 'ESingapore',
 			'SH' => 'ESt. Helena',
 			'SI' => 'ESlovenia',
 			'SJ' => 'ESvalbard & Jan Mayen',
 			'SK' => 'ESlovakia',
 			'SL' => 'ESierra Leone',
 			'SM' => 'ESan Marino',
 			'SN' => 'ESenegal',
 			'SO' => 'ESomalia',
 			'SR' => 'ESuriname',
 			'SS' => 'ESouth Sudan',
 			'ST' => 'ESão Tomé & Príncipe',
 			'SV' => 'E-El Salvador',
 			'SX' => 'ESint Maarten',
 			'SY' => 'ESiriya',
 			'SZ' => 'ESwatini',
 			'SZ@alt=variant' => 'ESwaziland',
 			'TA' => 'ETristan da Cunha',
 			'TC' => 'ETurks & Caicos Islands',
 			'TD' => 'EChad',
 			'TF' => 'EFrench Southern Territories',
 			'TG' => 'ETogo',
 			'TH' => 'EThailand',
 			'TJ' => 'ETajikistan',
 			'TK' => 'ETokelau',
 			'TL' => 'ETimor-Leste',
 			'TL@alt=variant' => 'E-East Timor',
 			'TM' => 'ETurkmenistan',
 			'TN' => 'ETunisia',
 			'TO' => 'ETonga',
 			'TR' => 'ETurkey',
 			'TR@alt=variant' => 'ETürkiye',
 			'TT' => 'ETrinidad & Tobago',
 			'TV' => 'ETuvalu',
 			'TW' => 'ETaiwan',
 			'TZ' => 'ETanzania',
 			'UA' => 'E-Ukraine',
 			'UG' => 'E-Uganda',
 			'UM' => 'I-U.S. Outlying Islands',
 			'UN' => 'Izizwe Ezimanyeneyo',
 			'US' => 'EMelika',
 			'US@alt=short' => 'I-US',
 			'UY' => 'E-Uruguay',
 			'UZ' => 'E-Uzbekistan',
 			'VA' => 'EVatican City',
 			'VC' => 'ESt. Vincent & Grenadines',
 			'VE' => 'EVenezuela',
 			'VG' => 'EBritish Virgin Islands',
 			'VI' => 'E-U.S. Virgin Islands',
 			'VN' => 'EVietnam',
 			'VU' => 'EVanuatu',
 			'WF' => 'EWallis & Futuna',
 			'WS' => 'ESamoa',
 			'XA' => 'I-Pseudo-Accents',
 			'XB' => 'I-Pseudo-Bidi',
 			'XK' => 'EKosovo',
 			'YE' => 'EYemen',
 			'YT' => 'EMayotte',
 			'ZA' => 'EMzantsi Afrika',
 			'ZM' => 'EZambia',
 			'ZW' => 'EZimbabwe',
 			'ZZ' => 'Ingingqi Engaziwayo',

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
 				'gregorian' => q{Ngokwekhalenda YeGregorian},
 				'iso8601' => q{Ikhalenda ye-ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{Standard Sort Order},
 			},
 			'numbers' => {
 				'latn' => q{Western Digits},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Language: {0}',
 			'script' => 'Script: {0}',
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
			auxiliary => qr{[áàăâåäãā æ ç éèĕêëē íìĭîïī ñ óòŏôöøō œ úùŭûüū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'name' => q(cardinal direction),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(cardinal direction),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} east),
						'north' => q({0} north),
						'south' => q({0} south),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} east),
						'north' => q({0} north),
						'south' => q({0} south),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'coordinate' => {
						'south' => q({0}S),
					},
					# Core Unit Identifier
					'coordinate' => {
						'south' => q({0}S),
					},
				},
				'short' => {
					# Long Unit Identifier
					'coordinate' => {
						'south' => q({0} S),
					},
					# Core Unit Identifier
					'coordinate' => {
						'south' => q({0} S),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ewe|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hayi|h|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'group' => q( ),
		},
	} }
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
			display_name => {
				'currency' => q(I-Dirham yase-UAE),
				'one' => q(I-dirham yase-UAE),
				'other' => q(Ii-dirham zase-UAE),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(I-Afghani yase-Afghanistan),
				'one' => q(I-Afghani yase-Afghanistan),
				'other' => q(Ii-Afghani zase-Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(I-Lek yase-Albania),
				'one' => q(I-lek yase-Albania),
				'other' => q(Ii-lekë zase-Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(I-Dram yase Armenia),
				'one' => q(I-dram yase-Armenia),
				'other' => q(Ii-dram zase-Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Netherlands Antillean Guilder),
				'one' => q(Netherlands Antillean guilder),
				'other' => q(Netherlands Antillean guilders),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(I-Kwanza yase-Angola),
				'one' => q(I-kwanza yase-Angola),
				'other' => q(Ii-kwanza zase-Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(IPeso yase-Argentina),
				'one' => q(Ipeso yase-Argentina),
				'other' => q(Iipeso zase-Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(IDola yase-Australia),
				'one' => q(Idola yase-Australia),
				'other' => q(Iidola zase-Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruban Florin),
				'one' => q(Aruban florin),
				'other' => q(Aruban florin),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(I-Manat yase-Azerbeijan),
				'one' => q(I-manat yase-Azerbaijan),
				'other' => q(Ii-manat zase-Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(I-Convertible Mark yaseBosnia-Herzegovina),
				'one' => q(I-convertible mark yaseBosnia-Herzegovina),
				'other' => q(Ii-convertible mark zaseBosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadian Dollar),
				'one' => q(Barbadian dollar),
				'other' => q(Barbadian dollars),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(I-Taka yaseBangladesh),
				'one' => q(I-taka yaseBangladesh),
				'other' => q(Ii-taka yaseBanglaesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(I-Lev yaseBulgaria),
				'one' => q(I-lev yaseBulgaria),
				'other' => q(Ii-leva zaseBulgaria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(I-Dinar yaseBahrain),
				'one' => q(I-dinar yaseBahrain),
				'other' => q(Ii-dinar zaseBahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(I-Franc yaseBurundi),
				'one' => q(I-franc yaseBurundi),
				'other' => q(Ii-franc zaseBurundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermudan Dollar),
				'one' => q(Bermudan dollar),
				'other' => q(Bermudan dollars),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(IDola yaseBrunei),
				'one' => q(Idola yaseBrunei),
				'other' => q(Iidola zaseBrunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(I-Boliviano yaseBolivia),
				'one' => q(I-boliviano yaseBolivia),
				'other' => q(I-bolivianos yaseBolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(I-Real yaseBrazil),
				'one' => q(I-real yaseBrazil),
				'other' => q(Ii-reals zaseBrazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamian Dollar),
				'one' => q(Bahamian dollar),
				'other' => q(Bahamian dollars),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(I-Ngultrum yaseBhutan),
				'one' => q(I-ngultrum yaseBhutan),
				'other' => q(Ii-ngultrum zaseBhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(I-Pula yaseBotswana),
				'one' => q(I-pula yaseBotswana),
				'other' => q(I-Pula yaseBotswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(I-Ruble yaseBelarus),
				'one' => q(I-ruble yaseBelarus),
				'other' => q(Ii-ruble zaseBelarus),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize Dollar),
				'one' => q(Belize dollar),
				'other' => q(Belize dollars),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Canadian Dollar),
				'one' => q(Canadian dollar),
				'other' => q(Canadian dollars),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(I-Franc yaseCongo),
				'one' => q(I-franc yaseCongo),
				'other' => q(Ii-franc zaseCongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(I-Franc yaseSwitzerland),
				'one' => q(I-franc yaseSwitzerland),
				'other' => q(Ii-francs zaseSitzerland),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(I-Peso yaseChile),
				'one' => q(I-peso yaseChile),
				'other' => q(Ii-pesos zaseChile),
			},
		},
		'CNH' => {
			symbol => 'I-CNH',
			display_name => {
				'currency' => q(I-Chinese Yuan \(offshore\)),
				'one' => q(I-Chinese yuan \(offshore\)),
				'other' => q(I-Chinese yuan \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(I-Yuan yaseTshayina),
				'one' => q(I-yuan yaseTshayina),
				'other' => q(I-yuan yaseTshayina),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(I-Peso yaseColombia),
				'one' => q(I-peso yaseColombia),
				'other' => q(Ii-peso zaseColombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rican Colón),
				'one' => q(Costa Rican colón),
				'other' => q(Costa Rican colóns),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Cuban Convertible Peso),
				'one' => q(Cuban convertible peso),
				'other' => q(Cuban convertible pesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Cuban Peso),
				'one' => q(Cuban peso),
				'other' => q(Cuban pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Cape Verdean Escudo),
				'one' => q(I-escudo yaseCape Verde),
				'other' => q(Ii-escudo zaseCape Verde),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(I-Koruna yaseCzech),
				'one' => q(I-koruna yaseCzech),
				'other' => q(Ii-koruna zaseCzech),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(I-Franc yaseDjibouti),
				'one' => q(I-franc yaseDjibouti),
				'other' => q(Ii-franc zaseDjibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(I-Krone yaseDenmark),
				'one' => q(I-krone yaseDenmark),
				'other' => q(I-kroner yaseDenmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominican Peso),
				'one' => q(Dominican peso),
				'other' => q(Dominican pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(I-Dinar yase-Algeria),
				'one' => q(I-dinar yase-Algeria),
				'other' => q(Ii-dinar zase-Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(IPonti yase-Egypt),
				'one' => q(Iponti yase-Egypt),
				'other' => q(Iiponti zaseYiputa),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(I-Nakfa yase-Eritria),
				'one' => q(I-nakfa yase-Eritria),
				'other' => q(Ii-nakfa zase-Eritria),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(I-Birr yase-Ethopia),
				'one' => q(I-birr yase-Ethopia),
				'other' => q(Ii-birr zase-Ethopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(I-Euro),
				'one' => q(i-euro),
				'other' => q(ii-euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(IDola yaseFiji),
				'one' => q(Idola yaseFiji),
				'other' => q(Iidola zaseFiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Iponti yaseFalkland Islands),
				'one' => q(IPonti yaseFalkland Islands),
				'other' => q(Iiponti zaseFalkland Islands),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(IPonti yaseBritane),
				'one' => q(Iponti yaseBritane),
				'other' => q(Iiponti zaseBritane),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(I-Lari yaseGeorgia),
				'one' => q(I-lari yaseGeorgia),
				'other' => q(Ii-lari zaseGeorgia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(I-Cedi yaseGhana),
				'one' => q(I-cedi yaseGhana),
				'other' => q(Ii-cedi zaseGhana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(IPonti yaseGilbraltar),
				'one' => q(Iponti yaseGibraltar),
				'other' => q(Iiponti zaseGibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(I-Dalasi yaseGambia),
				'one' => q(I-dalasi yaseGambia),
				'other' => q(Ii-dalasi zaseGambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(I-Franc yaseGuinea),
				'one' => q(I-franc yaseGuinea),
				'other' => q(Ii-franc zaseGuinea),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemalan Quetzal),
				'one' => q(Guatemalan quetzal),
				'other' => q(Guatemalan quetzals),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(IDola yaseGuyana),
				'one' => q(Idola yaseGuyana),
				'other' => q(Iidola zaseGuyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(IDola yaseHong Kong),
				'one' => q(Idola yaseHong Kong),
				'other' => q(Iidola zaseHong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduran Lempira),
				'one' => q(Honduran lempira),
				'other' => q(Honduran lempiras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(I-Kuna yaseCrotia),
				'one' => q(I-kuna yaseCroatia),
				'other' => q(Ii-kuna zaseCroatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haitian Gourde),
				'one' => q(Haitian gourde),
				'other' => q(Haitian gourdes),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(I-Forint yaseHungay),
				'one' => q(I-forint yaseHungary),
				'other' => q(Ii-forint zaseHungary),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(I-Rupiah yase-Indonesia),
				'one' => q(I-rupiah yase-Indonesia),
				'other' => q(Ii-rupiah zase-Indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(I-New Shekel yase-Israel),
				'one' => q(I-new shekel yase-Israel),
				'other' => q(Ii-new shekel zase-Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(I-Rupee yase-Indiya),
				'one' => q(I-rupee yase-Indiya),
				'other' => q(Ii-rupee zase-Indiya),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(I-Dinar yase-Iraq),
				'one' => q(I-dinar yase-Iraq),
				'other' => q(Ii-dinar zase-Iraq),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(I-Rial yase-Iran),
				'one' => q(I-rial yase-Iran),
				'other' => q(Ii-rial zase-Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(I-Króna yase-Iceland),
				'one' => q(I-króna yase-Iceland),
				'other' => q(Ii-krónur zase-Iceland),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaican Dollar),
				'one' => q(Jamaican dollar),
				'other' => q(Jamaican dollars),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(I-Dinar yaseJordan),
				'one' => q(I-dinar yaseJordan),
				'other' => q(Ii-dinar zaseJordan),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(I-Yen yaseJapan),
				'one' => q(I-yen yaseJapan),
				'other' => q(I-yen yaseJapan),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(I-Shilling yaseKenya),
				'one' => q(I-shilling yaseKenya),
				'other' => q(Iis-shilling zaseKenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(I-Som yaseKyrgystan),
				'one' => q(I-som yaseKyrgystan),
				'other' => q(Ii-som zaseKyrgystan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(I-Riel yaseCambodia),
				'one' => q(I-riel yaseCambodia),
				'other' => q(Ii-riel zaseCambodia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(I-Franc yaseComoros),
				'one' => q(I-franc yaseComoros),
				'other' => q(Ii-franc zaseComoros),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(I-Won yaseNorth Korea),
				'one' => q(I-won yaseNorth Korea),
				'other' => q(I-won yaseNorth Korea),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(I-Won yaseSouth Korea),
				'one' => q(I-won yaseSouth Korea),
				'other' => q(I-won yaseSouth Korean),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(I-Dinar yaseKuwait),
				'one' => q(I-dinar yaseKuwait),
				'other' => q(Ii-dinar zaseKuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Cayman Islands Dollar),
				'one' => q(Cayman Islands dollar),
				'other' => q(Cayman Islands dollars),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(I-Tenge yaseKhazakhstan),
				'one' => q(I-tenge yaseKhazakhstan),
				'other' => q(Ii-tenge zaseKhazakhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(I-Kip yaseLaos),
				'one' => q(I-kip yaseLaos),
				'other' => q(Ii-kip zaseLaos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(IPonti yaseLebanon),
				'one' => q(Iponti yaseLebanon),
				'other' => q(Iiponti zaseLebanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(I-Rupee yaseSri Lanka),
				'one' => q(I-rupee yaseSri Lanka),
				'other' => q(Ii-rupee zaseSri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(IDola yaseLiberia),
				'one' => q(Idola yaseLiberia),
				'other' => q(Iidola zaseLiberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(I-Loti yaseLesotho),
				'one' => q(I-loti yaseLesotho),
				'other' => q(Ii-loti zaseLesotho),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyan Dinar),
				'one' => q(I-dinar yaseLibya),
				'other' => q(Ii-dinar zaseLibya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroccan Dirham),
				'one' => q(I-dirham yaseMorocco),
				'other' => q(Ii-dirham zaseMorocco),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldovan Leu),
				'one' => q(I-leu yaseMoldova),
				'other' => q(I-lei yaseMoldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(I-Ariary yaseMadagascar),
				'one' => q(I-ariary yaseMadagascar),
				'other' => q(Ii-ariary zaseMadagascar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Macedonian Denar),
				'one' => q(I-denar yaseMacedonia),
				'other' => q(Ii-denar zaseMacedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(I-Kyat yaseMyanmar),
				'one' => q(I-kyat yaseMyanmar),
				'other' => q(Ii-kyat zaseMyanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(I-Tugrik yaseMongolia),
				'one' => q(I-tugrik yaseMongolia),
				'other' => q(Ii-tugrik zaseMongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(I-Pataca yaseMacao),
				'one' => q(I-pataca yaseMacao),
				'other' => q(Ii-pataca zaseMacao),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(I-Ouguiya yaseMauritania),
				'one' => q(I-ouguiya yaseMauritania),
				'other' => q(Ii-ouguiya zaseMauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(I-Rupee yaseMauritius),
				'one' => q(I-rupee yaseMauritius),
				'other' => q(Ii-rupee zaseMaritius),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(I-Rufiyaa yaseMaldives),
				'one' => q(I-rufiyaa yaseMaldives),
				'other' => q(Ii-rufiyaa zaseMaldives),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(I-Kwacha yaseMalawi),
				'one' => q(I-kwacha yaseMalawi),
				'other' => q(Ii-kwacha zaseMalawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexican Peso),
				'one' => q(Mexican peso),
				'other' => q(Mexican pesos),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(I-Ringgit yaseMalysia),
				'one' => q(I-ringgit yaseMalaysia),
				'other' => q(Ii-ringgit zaseMalaysia),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(I-Metical yaseMozambique),
				'one' => q(I-metical yaseMozambique),
				'other' => q(Ii-metical zaseMozambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(IDola yaseNamibia),
				'one' => q(Idola yaseNamibia),
				'other' => q(Iidola zaseNamibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(I-Naira yaseNigeria),
				'one' => q(I-naira yaseNigeria),
				'other' => q(Ii-naira zaseNigeria),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguan Córdoba),
				'one' => q(Nicaraguan córdoba),
				'other' => q(Nicaraguan córdobas),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(I-Krone yaseNorway),
				'one' => q(I-krone yaseNorway),
				'other' => q(Ii-kroner zaseNorway),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(I-Rupee yaseNepal),
				'one' => q(I-rupee yaseNepal),
				'other' => q(Ii-rupee zaseNepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(IDola yaseNew Zealand),
				'one' => q(Idola yaseNew Zealand),
				'other' => q(Iidola zaseNew Zealand),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(I-Rial yase-Oman),
				'one' => q(I-rial yase-Oman),
				'other' => q(Ii-rial zase-Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamanian Balboa),
				'one' => q(Panamanian balboa),
				'other' => q(Panamanian balboas),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(I-Sol yasePeruvia),
				'one' => q(I-sol yasePeruvia),
				'other' => q(Ii-sol zasePeruvia),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(I-Kina yasePapua New Guinea),
				'one' => q(I-kina yasePapua New Guinea),
				'other' => q(I-kina yasePapua New Guinea),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(I-Peso yasePhilippines),
				'one' => q(I-peso yasePhilippiines),
				'other' => q(Ii-peso zasePhilippines),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(I-Rupee yasePakistan),
				'one' => q(I-rupee yasePakistan),
				'other' => q(Ii-rupee zasePakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polish Zloty),
				'one' => q(I-zloty yasePoland),
				'other' => q(Ii-zloty zasePoland),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(I-Guarani yaseParaguay),
				'one' => q(I-guarani yaseParaguay),
				'other' => q(Ii-guarani zaseParaguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(I-Riyal yaseQatar),
				'one' => q(I-riyal yaseQatar),
				'other' => q(Ii-riyal zaseQatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(I-Leu yaseRomania),
				'one' => q(I-leu yaseRomania),
				'other' => q(Ii-lei zaseRomania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(I-Dinar yaseSerbia),
				'one' => q(I-dinar yaseSerbia),
				'other' => q(Ii-dinars zaseSerbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(I-Ruble yaseRashiya),
				'one' => q(I-ruble yaseRashiya),
				'other' => q(Ii-ruble zaseRashiya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(I-Franc yaseRwanda),
				'one' => q(I-franc yaseRwanda),
				'other' => q(Ii-franc zaseRwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(I-Riyal yaseSaudi),
				'one' => q(I-riyal yaseSaudi),
				'other' => q(Ii-riyal zaseSaudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(IDola yaseSolomon Islands),
				'one' => q(Idola yaseSolomon Islands),
				'other' => q(Iidola zaseSolomon Islands),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(I-Rupee yaseSeychelles),
				'one' => q(I-rupee yaseSeychelles),
				'other' => q(Ii-rupee zaseSeychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudanese Pound),
				'one' => q(Iponti yaseSudan),
				'other' => q(Iiponti zaseSudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(I-Krona yaseSweden),
				'one' => q(I-krona yaseSweden),
				'other' => q(Ii-kronor zaseSweden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(IDola yaseSingapore),
				'one' => q(Idola yaseSingapore),
				'other' => q(Iidola zaseSingapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(IPonti yaseSt. Helena),
				'one' => q(Iponti yaseSt. Helena),
				'other' => q(Iiponti zaseSt. Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(I-Loeone yaseSierra Leone),
				'one' => q(I-leone yaseSierra Leone),
				'other' => q(Ii-leones zaseSierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(I-Loeone yaseSierra Leone \(1964—2022\)),
				'one' => q(I-leone yaseSierra Leone \(1964—2022\)),
				'other' => q(Ii-leones zaseSierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(I-Shilling yaseSomalia),
				'one' => q(I-shilling yaseSomalia),
				'other' => q(Ii-shilling zaseSomalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(IDola yaseSuriname),
				'one' => q(Idola yaseSuriname),
				'other' => q(Iidola zaseSuriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(IPonti yaseSouth Sudan),
				'one' => q(Iponti yaseSouth Sudan),
				'other' => q(Iiponti zaseSouth Sudan),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(I-Dobra yaseSão Tomé & Príncipe),
				'one' => q(I-dobra yaseSão Tomé & Príncipe),
				'other' => q(Ii-dobra zaseSão Tomé & Príncipe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(IPonti yaseSiriya),
				'one' => q(Iponti yaseSiriya),
				'other' => q(Iiponti zaseSiriya),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(I-Lilangeni yase-Eswatini),
				'one' => q(I-lilangeni yase-Eswatini),
				'other' => q(I-emalangeni yase-Eswatini),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(I-Baht yaseThailand),
				'one' => q(I-baht yaseThailand),
				'other' => q(I-baht yaseThailand),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(I-Somoni yaseTajikistan),
				'one' => q(I-somoni yaseTajikistan),
				'other' => q(Ii-somonis zaseTajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(I-Manat yaseTurkmenistan),
				'one' => q(I-manat yaseTurkmenistan),
				'other' => q(I-manat yaseTurkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisian Dinar),
				'one' => q(I-dinar yaseTunisia),
				'other' => q(Ii-dinar zaseTunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(I-Paʻanga yaseTonga),
				'one' => q(I-paʻanga yaseTonga),
				'other' => q(I-paʻanga yaseTonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(I-Lira yaseTurkey),
				'one' => q(I-lira yaseTurkey),
				'other' => q(I-Lira yaseTurkey),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad & Tobago Dollar),
				'one' => q(Trinidad & Tobago dollar),
				'other' => q(Trinidad & Tobago dollars),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(IDola yaseNew Taiwan),
				'one' => q(Idola yaseNew Taiwan),
				'other' => q(Iidola zaseNew Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(I-Shilling yaseTanzania),
				'one' => q(I-shilling yaseTanzania),
				'other' => q(Ii-shilling zaseTanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(I-Hryvnia yase-Ukraine),
				'one' => q(I-hryvnia yase-Ukraine),
				'other' => q(Ii-hryvnias zase-Ukraine),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(I-Shilling yase-Uganda),
				'one' => q(I-shilling yase-Uganda),
				'other' => q(Ii-shilling zase-Uganda),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US Dollar),
				'one' => q(US dollar),
				'other' => q(US dollars),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(I-Peso yase-Uruguay),
				'one' => q(I-peso yase-Uruguay),
				'other' => q(Ii-peso zase-Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(I-Som yase-Uzbekistan),
				'one' => q(I-som yase-Uzbekistan),
				'other' => q(I-som yase-Uzbekistan),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(I-Bolívar yaseVenezuela),
				'one' => q(I-bolivar yaseVenezuela),
				'other' => q(Ii-bolivar zaseVenezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(I-Dong yaseVietnam),
				'one' => q(I-dong yaseVietnam),
				'other' => q(I-dong yaseVietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(I-Vatu yaseVanuatu),
				'one' => q(I-vatu yaseVanuatu),
				'other' => q(Ii-vatu zaseVanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(I-Tala yaseSamoa),
				'one' => q(I-tala yaseSamoa),
				'other' => q(I-tala yaseSamoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Central African CFA Franc),
				'one' => q(I-CFA franc yaseCentral Africa),
				'other' => q(Ii-CFA francs zaseCentral Africa),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(East Caribbean Dollar),
				'one' => q(East Caribbean dollar),
				'other' => q(East Caribbean dollars),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(West African CFA Franc),
				'one' => q(I-CFA franc yaseWest Africa),
				'other' => q(Ii-CFA franc zaseWest Africa),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(I-Franc yaseCFP),
				'one' => q(I-franc yaseCFP),
				'other' => q(Ii-franc zaseCFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Ikharensi Engaziwayo),
				'one' => q(\(ikharensi exabiso lingaziwayo\)),
				'other' => q(\(ikharensi engaziwayo\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(I-Rial yaseYemen),
				'one' => q(I-rial yaseYemen),
				'other' => q(Ii-rial zaseYemen),
			},
		},
		'ZAR' => {
			symbol => 'R',
			display_name => {
				'currency' => q(IRandi yaseMzantsi Afrika),
				'one' => q(Irandi yaseMzantsi Afrika),
				'other' => q(Irandi yaseMzantsi Afrika),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(I-Kwacha yaseZambi),
				'one' => q(I-kwacha yaseZambia),
				'other' => q(I-kwacha yaseZambia),
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
							'Mat',
							'Epr',
							'Mey',
							'Jun',
							'Jul',
							'Aga',
							'Sept',
							'Okt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janyuwari',
							'Februwari',
							'Matshi',
							'Epreli',
							'Meyi',
							'Juni',
							'Julayi',
							'Agasti',
							'Septemba',
							'Okthobha',
							'Novemba',
							'Disemba'
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
							'Mat',
							'Epr',
							'Mey',
							'Jun',
							'Jul',
							'Aga',
							'Sep',
							'Okt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janyuwari',
							'Februwari',
							'Matshi',
							'Epreli',
							'Meyi',
							'Juni',
							'Julayi',
							'Agasti',
							'Septemba',
							'Okthoba',
							'Novemba',
							'Disemba'
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
						mon => 'Mvu',
						tue => 'Lwesb',
						wed => 'Tha',
						thu => 'Sin',
						fri => 'Hla',
						sat => 'Mgq',
						sun => 'Caw'
					},
					narrow => {
						mon => 'M',
						tue => 'Sb',
						wed => 'Tht',
						thu => 'Sin',
						fri => 'Hl',
						sat => 'Mgq',
						sun => 'C'
					},
					wide => {
						mon => 'Mvulo',
						tue => 'Lwesibini',
						wed => 'Lwesithathu',
						thu => 'Lwesine',
						fri => 'Lwesihlanu',
						sat => 'Mgqibelo',
						sun => 'Cawe'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mvu',
						tue => 'Bin',
						wed => 'Tha',
						thu => 'Sin',
						fri => 'Hla',
						sat => 'Mgq',
						sun => 'Caw'
					},
					narrow => {
						mon => 'M',
						tue => 'Sb',
						wed => 'St',
						thu => 'Sin',
						fri => 'Hl',
						sat => 'Mgq',
						sun => 'C'
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
					abbreviated => {0 => 'Kota 1',
						1 => 'Kota 2',
						2 => 'Kota 3',
						3 => 'Kota 4'
					},
					wide => {0 => 'ikota yoku-1',
						1 => 'ikota yesi-2',
						2 => 'ikota yesi-3',
						3 => 'ikota yesi-4'
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
				'0' => 'BC',
				'1' => 'AD'
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
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
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
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			Md => q{M/d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			Md => q{M/d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E, M/d/y G – E, M/d/y G},
				M => q{E, M/d/y – E, M/d/y G},
				d => q{E, M/d/y – E, M/d/y G},
				y => q{E, M/d/y – E, M/d/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y G – M/d/y G},
				M => q{M/d/y – M/d/y G},
				d => q{M/d/y – M/d/y G},
				y => q{M/d/y – M/d/y G},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
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
			},
			hv => {
				h => q{h–h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Time),
		regionFormat => q({0} Daylight Time),
		regionFormat => q({0} Standard Time),
		'Afghanistan' => {
			long => {
				'standard' => q#Afghanistan Time#,
			},
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Central Africa Time#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#East Africa Time#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#South Africa Standard Time#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#West Africa Summer Time#,
				'generic' => q#West Africa Time#,
				'standard' => q#West Africa Standard Time#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska Daylight Time#,
				'generic' => q#Alaska Time#,
				'standard' => q#Alaska Standard Time#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon Summer Time#,
				'generic' => q#Amazon Time#,
				'standard' => q#Amazon Standard Time#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Central Daylight Time#,
				'generic' => q#Central Time#,
				'standard' => q#Central Standard Time#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern Daylight Time#,
				'generic' => q#Eastern Time#,
				'standard' => q#Eastern Standard Time#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain Daylight Time#,
				'generic' => q#Mountain Time#,
				'standard' => q#Mountain Standard Time#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific Daylight Time#,
				'generic' => q#Pacific Time#,
				'standard' => q#Pacific Standard Time#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia Daylight Time#,
				'generic' => q#Apia Time#,
				'standard' => q#Apia Standard Time#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabian Daylight Time#,
				'generic' => q#Arabian Time#,
				'standard' => q#Arabian Standard Time#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina Summer Time#,
				'generic' => q#Argentina Time#,
				'standard' => q#Argentina Standard Time#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Western Argentina Summer Time#,
				'generic' => q#Western Argentina Time#,
				'standard' => q#Western Argentina Standard Time#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenia Summer Time#,
				'generic' => q#Armenia Time#,
				'standard' => q#Armenia Standard Time#,
			},
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh City#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantic Daylight Time#,
				'generic' => q#Atlantic Time#,
				'standard' => q#Atlantic Standard Time#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Australian Central Daylight Time#,
				'generic' => q#Central Australia Time#,
				'standard' => q#Australian Central Standard Time#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australian Central Western Daylight Time#,
				'generic' => q#Australian Central Western Time#,
				'standard' => q#Australian Central Western Standard Time#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australian Eastern Daylight Time#,
				'generic' => q#Eastern Australia Time#,
				'standard' => q#Australian Eastern Standard Time#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Australian Western Daylight Time#,
				'generic' => q#Western Australia Time#,
				'standard' => q#Australian Western Standard Time#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaijan Summer Time#,
				'generic' => q#Azerbaijan Time#,
				'standard' => q#Azerbaijan Standard Time#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azores Summer Time#,
				'generic' => q#Azores Time#,
				'standard' => q#Azores Standard Time#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesh Summer Time#,
				'generic' => q#Bangladesh Time#,
				'standard' => q#Bangladesh Standard Time#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutan Time#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia Time#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia Summer Time#,
				'generic' => q#Brasilia Time#,
				'standard' => q#Brasilia Standard Time#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam Time#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Cape Verde Summer Time#,
				'generic' => q#Cape Verde Time#,
				'standard' => q#Cape Verde Standard Time#,
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
				'generic' => q#Chatham Time#,
				'standard' => q#Chatham Standard Time#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chile Summer Time#,
				'generic' => q#Chile Time#,
				'standard' => q#Chile Standard Time#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#China Daylight Time#,
				'generic' => q#China Time#,
				'standard' => q#China Standard Time#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibalsan Summer Time#,
				'generic' => q#Choibalsan Time#,
				'standard' => q#Choibalsan Standard Time#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Christmas Island Time#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocos Islands Time#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Colombia Summer Time#,
				'generic' => q#Colombia Time#,
				'standard' => q#Colombia Standard Time#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cook Islands Half Summer Time#,
				'generic' => q#Cook Islands Time#,
				'standard' => q#Cook Islands Standard Time#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cuba Daylight Time#,
				'generic' => q#Cuba Time#,
				'standard' => q#Cuba Standard Time#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis Time#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville Time#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#East Timor Time#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Easter Island Summer Time#,
				'generic' => q#Easter Island Time#,
				'standard' => q#Easter Island Standard Time#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuador Time#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Coordinated Universal Time#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Unknown City#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irish Standard Time#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#British Summer Time#,
			},
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Central European Summer Time#,
				'generic' => q#Central European Time#,
				'standard' => q#Central European Standard Time#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Eastern European Summer Time#,
				'generic' => q#Eastern European Time#,
				'standard' => q#Eastern European Standard Time#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Further-eastern European Time#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Western European Summer Time#,
				'generic' => q#Western European Time#,
				'standard' => q#Western European Standard Time#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falkland Islands Summer Time#,
				'generic' => q#Falkland Islands Time#,
				'standard' => q#Falkland Islands Standard Time#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji Summer Time#,
				'generic' => q#Fiji Time#,
				'standard' => q#Fiji Standard Time#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#French Guiana Time#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#French Southern & Antarctic Time#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos Time#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier Time#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgia Summer Time#,
				'generic' => q#Georgia Time#,
				'standard' => q#Georgia Standard Time#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert Islands Time#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#East Greenland Summer Time#,
				'generic' => q#East Greenland Time#,
				'standard' => q#East Greenland Standard Time#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#West Greenland Summer Time#,
				'generic' => q#West Greenland Time#,
				'standard' => q#West Greenland Standard Time#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Gulf Standard Time#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana Time#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutian Daylight Time#,
				'generic' => q#Hawaii-Aleutian Time#,
				'standard' => q#Hawaii-Aleutian Standard Time#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kong Summer Time#,
				'generic' => q#Hong Kong Time#,
				'standard' => q#Hong Kong Standard Time#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd Summer Time#,
				'generic' => q#Hovd Time#,
				'standard' => q#Hovd Standard Time#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India Standard Time#,
			},
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indian Ocean Time#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indochina Time#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Central Indonesia Time#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Eastern Indonesia Time#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Western Indonesia Time#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran Daylight Time#,
				'generic' => q#Iran Time#,
				'standard' => q#Iran Standard Time#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk Summer Time#,
				'generic' => q#Irkutsk Time#,
				'standard' => q#Irkutsk Standard Time#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel Daylight Time#,
				'generic' => q#Israel Time#,
				'standard' => q#Israel Standard Time#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan Daylight Time#,
				'generic' => q#Japan Time#,
				'standard' => q#Japan Standard Time#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#East Kazakhstan Time#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#West Kazakhstan Time#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korean Daylight Time#,
				'generic' => q#Korean Time#,
				'standard' => q#Korean Standard Time#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae Time#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk Summer Time#,
				'generic' => q#Krasnoyarsk Time#,
				'standard' => q#Krasnoyarsk Standard Time#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kyrgyzstan Time#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line Islands Time#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe Daylight Time#,
				'generic' => q#Lord Howe Time#,
				'standard' => q#Lord Howe Standard Time#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie Island Time#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan Summer Time#,
				'generic' => q#Magadan Time#,
				'standard' => q#Magadan Standard Time#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysia Time#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldives Time#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas Time#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshall Islands Time#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius Summer Time#,
				'generic' => q#Mauritius Time#,
				'standard' => q#Mauritius Standard Time#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson Time#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Northwest Mexico Daylight Time#,
				'generic' => q#Northwest Mexico Time#,
				'standard' => q#Northwest Mexico Standard Time#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexican Pacific Daylight Time#,
				'generic' => q#Mexican Pacific Time#,
				'standard' => q#Mexican Pacific Standard Time#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar Summer Time#,
				'generic' => q#Ulaanbaatar Time#,
				'standard' => q#Ulaanbaatar Standard Time#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moscow Summer Time#,
				'generic' => q#Moscow Time#,
				'standard' => q#Moscow Standard Time#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar Time#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru Time#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal Time#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#New Caledonia Summer Time#,
				'generic' => q#New Caledonia Time#,
				'standard' => q#New Caledonia Standard Time#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#New Zealand Daylight Time#,
				'generic' => q#New Zealand Time#,
				'standard' => q#New Zealand Standard Time#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland Daylight Time#,
				'generic' => q#Newfoundland Time#,
				'standard' => q#Newfoundland Standard Time#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue Time#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Island Daylight Time#,
				'generic' => q#Norfolk Island Time#,
				'standard' => q#Norfolk Island Standard Time#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha Summer Time#,
				'generic' => q#Fernando de Noronha Time#,
				'standard' => q#Fernando de Noronha Standard Time#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk Summer Time#,
				'generic' => q#Novosibirsk Time#,
				'standard' => q#Novosibirsk Standard Time#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk Summer Time#,
				'generic' => q#Omsk Time#,
				'standard' => q#Omsk Standard Time#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan Summer Time#,
				'generic' => q#Pakistan Time#,
				'standard' => q#Pakistan Standard Time#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau Time#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua New Guinea Time#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguay Summer Time#,
				'generic' => q#Paraguay Time#,
				'standard' => q#Paraguay Standard Time#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru Summer Time#,
				'generic' => q#Peru Time#,
				'standard' => q#Peru Standard Time#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Philippine Summer Time#,
				'generic' => q#Philippine Time#,
				'standard' => q#Philippine Standard Time#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenix Islands Time#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre & Miquelon Daylight Time#,
				'generic' => q#St. Pierre & Miquelon Time#,
				'standard' => q#St. Pierre & Miquelon Standard Time#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn Time#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape Time#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang Time#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion Time#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera Time#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin Summer Time#,
				'generic' => q#Sakhalin Time#,
				'standard' => q#Sakhalin Standard Time#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Daylight Time#,
				'generic' => q#Samoa Time#,
				'standard' => q#Samoa Standard Time#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelles Time#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapore Standard Time#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon Islands Time#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#South Georgia Time#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname Time#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa Time#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti Time#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei Daylight Time#,
				'generic' => q#Taipei Time#,
				'standard' => q#Taipei Standard Time#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tajikistan Time#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau Time#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga Summer Time#,
				'generic' => q#Tonga Time#,
				'standard' => q#Tonga Standard Time#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk Time#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan Summer Time#,
				'generic' => q#Turkmenistan Time#,
				'standard' => q#Turkmenistan Standard Time#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu Time#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguay Summer Time#,
				'generic' => q#Uruguay Time#,
				'standard' => q#Uruguay Standard Time#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistan Summer Time#,
				'generic' => q#Uzbekistan Time#,
				'standard' => q#Uzbekistan Standard Time#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu Summer Time#,
				'generic' => q#Vanuatu Time#,
				'standard' => q#Vanuatu Standard Time#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela Time#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok Summer Time#,
				'generic' => q#Vladivostok Time#,
				'standard' => q#Vladivostok Standard Time#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd Summer Time#,
				'generic' => q#Volgograd Time#,
				'standard' => q#Volgograd Standard Time#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok Time#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake Island Time#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis & Futuna Time#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk Summer Time#,
				'generic' => q#Yakutsk Time#,
				'standard' => q#Yakutsk Standard Time#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinburg Summer Time#,
				'generic' => q#Yekaterinburg Time#,
				'standard' => q#Yekaterinburg Standard Time#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
