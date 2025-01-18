=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Om - Package for language Oromo

=cut

package Locale::CLDR::Locales::Om;
# This file auto generated from Data\common\main\om.xml
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
				'af' => 'Afrikoota',
 				'am' => 'Afaan Amaaraa',
 				'ar' => 'Arabiffaa',
 				'ar_001' => 'Arabiffa Istaandaardii Ammayyaa',
 				'as' => 'Assamese',
 				'ast' => 'Astuuriyaan',
 				'az' => 'Afaan Azerbaijani',
 				'az@alt=short' => 'Afaan Azeerii',
 				'be' => 'Afaan Belarusia',
 				'bg' => 'Afaan Bulgariya',
 				'bgc' => 'Haryanvi',
 				'bho' => 'Bihoojpuurii',
 				'blo' => 'Anii',
 				'bn' => 'Afaan Baangladeshi',
 				'br' => 'Bireetoon',
 				'brx' => 'Bodo',
 				'bs' => 'Afaan Bosniyaa',
 				'ca' => 'Afaan Katalaa',
 				'ceb' => 'Kubuwanoo',
 				'chr' => 'Cherokee',
 				'cs' => 'Afaan Czech',
 				'cv' => 'Chuvash',
 				'cy' => 'Welishiffaa',
 				'da' => 'Afaan Deenmaark',
 				'de' => 'Afaan Jarmanii',
 				'de_AT' => 'Jarmanii Awustiriyaa',
 				'de_CH' => 'Jarmanii Siwiiz Haay',
 				'doi' => 'Dogri',
 				'el' => 'Afaan Giriiki',
 				'en' => 'Afaan Ingilizii',
 				'en_AU' => 'Ingiliffa Awustiraaliyaa',
 				'en_CA' => 'Ingiliffa Kanaadaa',
 				'en_GB' => 'Ingliffa Biritishii',
 				'en_GB@alt=short' => 'Ingliffa UK',
 				'en_US' => 'Ingliffa Ameekiraa',
 				'en_US@alt=short' => 'Ingliffa US',
 				'eo' => 'Afaan Esperantoo',
 				'es' => 'Afaan Ispeen',
 				'es_419' => 'Laatinii Ispaanishii Ameerikaa',
 				'es_ES' => 'Ispaanishii Awurooppaa',
 				'es_MX' => 'Ispaanishii Meeksiikoo',
 				'et' => 'Afaan Istooniya',
 				'eu' => 'Afaan Baskuu',
 				'fa' => 'Afaan Persia',
 				'ff' => 'Fula',
 				'fi' => 'Afaan Fiilaandi',
 				'fil' => 'Afaan Filippinii',
 				'fo' => 'Afaan Faroese',
 				'fr' => 'Afaan Faransaayii',
 				'fy' => 'Afaan Firisiyaani',
 				'ga' => 'Afaan Ayirishii',
 				'gd' => 'Scots Gaelic',
 				'gl' => 'Afaan Galishii',
 				'gn' => 'Afaan Guarani',
 				'gu' => 'Afaan Gujarati',
 				'ha' => 'Hawusaa',
 				'he' => 'Afaan Hebrew',
 				'hi' => 'Afaan Hindii',
 				'hi_Latn' => 'Hindii (Laatiin)',
 				'hi_Latn@alt=variant' => 'Hinglishii',
 				'hr' => 'Afaan Croatian',
 				'hu' => 'Afaan Hangaari',
 				'hy' => 'Armeeniyaa',
 				'ia' => 'Interlingua',
 				'id' => 'Afaan Indoneziya',
 				'is' => 'Ayiislandiffaa',
 				'it' => 'Afaan Xaaliyaani',
 				'ja' => 'Afaan Japanii',
 				'jv' => 'Afaan Java',
 				'ka' => 'Afaan Georgian',
 				'kn' => 'Afaan Kannada',
 				'ko' => 'Afaan Korea',
 				'la' => 'Afaan Laatini',
 				'lt' => 'Afaan Liituniyaa',
 				'lv' => 'Afaan Lativiyaa',
 				'mk' => 'Afaan Macedooniyaa',
 				'ml' => 'Malayaalamiffaa',
 				'mr' => 'Afaan Maratii',
 				'ms' => 'Malaayiffaa',
 				'mt' => 'Afaan Maltesii',
 				'my' => 'Burmeesee',
 				'ne' => 'Afaan Nepalii',
 				'nl' => 'Afaan Dachii',
 				'nl_BE' => 'Flemish',
 				'nn' => 'Afaan Norwegian',
 				'no' => 'Afaan Norweyii',
 				'oc' => 'Afaan Occit',
 				'om' => 'Oromoo',
 				'pa' => 'Afaan Punjabii',
 				'pl' => 'Afaan Polandii',
 				'pt' => 'Afaan Porchugaal',
 				'pt_BR' => 'Afaan Portugali (Braazil)',
 				'pt_PT' => 'Afaan Protuguese',
 				'ro' => 'Afaan Romaniyaa',
 				'ru' => 'Afaan Rushiyaa',
 				'si' => 'Afaan Sinhalese',
 				'sk' => 'Afaan Slovak',
 				'sl' => 'Afaan Islovaniyaa',
 				'sq' => 'Afaan Albaniyaa',
 				'sr' => 'Afaan Serbiya',
 				'su' => 'Afaan Sudaanii',
 				'sv' => 'Afaan Suwidiin',
 				'sw' => 'Suwahilii',
 				'ta' => 'Afaan Tamilii',
 				'te' => 'Afaan Telugu',
 				'th' => 'Afaan Tayii',
 				'ti' => 'Afaan Tigiree',
 				'tk' => 'Lammii Turkii',
 				'tlh' => 'Afaan Kilingon',
 				'tr' => 'Afaan Turkii',
 				'uk' => 'Afaan Ukreenii',
 				'und' => 'Afaan hin beekamne',
 				'ur' => 'Afaan Urdu',
 				'uz' => 'Afaan Uzbek',
 				'vi' => 'Afaan Veetinam',
 				'xh' => 'Afaan Xhosa',
 				'yue' => 'Kantonoosee',
 				'yue@alt=menu' => 'Chaayinisee Kantonoosee',
 				'zh' => 'Chinese',
 				'zh@alt=menu' => 'Chinese Mandariin',
 				'zh_Hans' => 'Chinese Salphifame',
 				'zh_Hans@alt=long' => 'Mandariinii Chinese Salphifame',
 				'zh_Hant' => 'Chinese Durii',
 				'zh_Hant@alt=long' => 'Mandariinii Chinese Durii',
 				'zu' => 'Afaan Zuulu',

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
			'Arab' => 'Arabiffa',
 			'Cyrl' => 'Saayiriilik',
 			'Hans' => 'Salphifame',
 			'Hans@alt=stand-alone' => 'Han Salphifame',
 			'Hant' => 'Kan Durii',
 			'Hant@alt=stand-alone' => 'Han Kan Durii',
 			'Jpan' => 'Afaan Jaappaan',
 			'Kore' => 'Afaan Kooriyaa',
 			'Latn' => 'Laatinii',
 			'Zxxx' => 'Kan Hin Barreeffamne',
 			'Zzzz' => 'Barreeffama Hin Beekamne',

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
			'001' => 'addunyaa',
 			'002' => 'Afrikaa',
 			'003' => 'Ameerikaa Kaabaa',
 			'005' => 'Ameerikaa Kibbaa',
 			'009' => 'Oshiiniyaa',
 			'011' => 'Afrikaa Dhihaa',
 			'013' => 'Ameerikaa Gidduugaleessaa',
 			'014' => 'Afrikaa Bahaa',
 			'015' => 'Afrikaa Kabaa',
 			'017' => 'Afrikaa Gidduugaleessaa',
 			'018' => 'Kibba Afrikaa',
 			'019' => 'Ameerikaa',
 			'021' => 'Ameerikaa Kaaba',
 			'029' => 'Kariibiyaan',
 			'030' => 'Eeshiyaa Bahaa',
 			'034' => 'Eeshiyaa Kibbaa',
 			'035' => 'Kibba baha Eeshiyaa',
 			'039' => 'Awurooppaa Kibbaa',
 			'053' => 'Awustiralashiyaa',
 			'054' => 'Melaaneeshiyaa',
 			'057' => 'Naannoo Maleeshiyaa',
 			'061' => 'Poolineeshiyaa',
 			'142' => 'Eeshiyaa',
 			'143' => 'Eeshiyaa Gidduugaleessaa',
 			'145' => 'Eeshiyaa Dhihaa',
 			'150' => 'Awurooppaa',
 			'151' => 'Awurooppaa Bahaa',
 			'154' => 'Awurooppaa Kaabaa',
 			'155' => 'Awurooppaa Dhihaa',
 			'202' => 'Afrikaa Sahaaraan Gadii',
 			'419' => 'Laatin Ameerikaa',
 			'AC' => 'Odola Asenshiin',
 			'AD' => 'Andooraa',
 			'AE' => 'Yuunaatid Arab Emereet',
 			'AF' => 'Afgaanistaan',
 			'AG' => 'Antiiguyaa fi Barbuudaa',
 			'AI' => 'Anguyilaa',
 			'AL' => 'Albaaniyaa',
 			'AM' => 'Armeeniyaa',
 			'AO' => 'Angoolaa',
 			'AQ' => 'Antaarkitikaa',
 			'AR' => 'Arjentiinaa',
 			'AS' => 'Saamowa Ameerikaa',
 			'AT' => 'Awustiriyaa',
 			'AU' => 'Awustiraaliyaa',
 			'AW' => 'Arubaa',
 			'AX' => 'Odoloota Alaand',
 			'AZ' => 'Azerbaajiyaan',
 			'BA' => 'Bosiiniyaa fi Herzoogovinaa',
 			'BB' => 'Barbaaros',
 			'BD' => 'Banglaadish',
 			'BE' => 'Beeljiyeem',
 			'BF' => 'Burkiinaa Faasoo',
 			'BG' => 'Bulgaariyaa',
 			'BH' => 'Baahireen',
 			'BI' => 'Burundii',
 			'BJ' => 'Beenii',
 			'BL' => 'St. Barzeleemii',
 			'BM' => 'Beermudaa',
 			'BN' => 'Biruniyee',
 			'BO' => 'Boliiviyaa',
 			'BQ' => 'Neezerlaandota Kariibaan',
 			'BR' => 'Biraazil',
 			'BS' => 'Bahaamas',
 			'BT' => 'Bihuutan',
 			'BV' => 'Odola Bowuvet',
 			'BW' => 'Botosowaanaa',
 			'BY' => 'Beelaarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanaadaa',
 			'CC' => 'Odoloota Kokos (Keeliing)',
 			'CD' => 'Koongoo - Kinshaasaa',
 			'CD@alt=variant' => 'Koongoo (DRC)',
 			'CF' => 'Rippaablika Afrikaa Gidduugaleessaa',
 			'CG' => 'Koongoo - Biraazaavil',
 			'CG@alt=variant' => 'Koongoo (Rippaabilik)',
 			'CH' => 'Siwizerlaand',
 			'CI' => 'Koti divoor',
 			'CI@alt=variant' => 'Ayivoorii Koost',
 			'CK' => 'Odoloota Kuuk',
 			'CL' => 'Chiilii',
 			'CM' => 'Kaameruun',
 			'CN' => 'Chaayinaa',
 			'CO' => 'Kolombiyaa',
 			'CP' => 'Odola Kilippertoo',
 			'CR' => 'Kostaa Rikaa',
 			'CU' => 'Kuubaa',
 			'CV' => 'Keeppi Vaardee',
 			'CW' => 'Kurakowaa',
 			'CX' => 'Odola Kirismaas',
 			'CY' => 'Qoophiroos',
 			'CZ' => 'Cheechiya',
 			'CZ@alt=variant' => 'Cheek Rippaablik',
 			'DE' => 'Jarmanii',
 			'DG' => 'Diyeegoo Gaarshiyaa',
 			'DJ' => 'Jibuutii',
 			'DK' => 'Deenmaark',
 			'DM' => 'Dominiikaa',
 			'DO' => 'Dominikaa Rippaabilik',
 			'DZ' => 'Aljeeriyaa',
 			'EA' => 'Kewuta fi Mililaa',
 			'EC' => 'Ekuwaador',
 			'EE' => 'Istooniyaa',
 			'EG' => 'Missir',
 			'EH' => 'Sahaaraa Dhihaa',
 			'ER' => 'Eertiraa',
 			'ES' => 'Ispeen',
 			'ET' => 'Itoophiyaa',
 			'EU' => 'Gamtaa Awurooppaa',
 			'EZ' => 'Zooniiyuuroo',
 			'FI' => 'Fiinlaand',
 			'FJ' => 'Fiijii',
 			'FK' => 'Odoloota Faalklaand',
 			'FK@alt=variant' => 'Odoloota Faalklaand (Islaas Malviinas)',
 			'FM' => 'Maayikirooneeshiyaa',
 			'FO' => 'Odoloota Fafo’ee',
 			'FR' => 'Faransaay',
 			'GA' => 'Gaaboon',
 			'GB' => 'United Kingdom',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Girinaada',
 			'GE' => 'Joorjiyaa',
 			'GF' => 'Faransaay Guyiinaa',
 			'GG' => 'Guwernisey',
 			'GH' => 'Gaanaa',
 			'GI' => 'Gibraaltar',
 			'GL' => 'Giriinlaand',
 			'GM' => 'Gaambiyaa',
 			'GN' => 'Giinii',
 			'GP' => 'Gowadelowape',
 			'GQ' => 'Ikkuwaatooriyaal Giinii',
 			'GR' => 'Giriik',
 			'GS' => 'Joorjikaa Kibba fi Odoloota Saanduwiich Kibbaa',
 			'GT' => 'Guwaatimaalaa',
 			'GU' => 'Guwama',
 			'GW' => 'Giinii-Bisaawoo',
 			'GY' => 'Guyaanaa',
 			'HK' => 'Hoong Koong SAR Chaayinaa',
 			'HK@alt=short' => 'Hoong Koong',
 			'HM' => 'Odoloota Herdii fi MaakDoonaald',
 			'HN' => 'Hondurus',
 			'HR' => 'Kirooshiyaa',
 			'HT' => 'Haayitii',
 			'HU' => 'Hangaarii',
 			'IC' => 'Odoloota Kanaarii',
 			'ID' => 'Indooneeshiyaa',
 			'IE' => 'Ayeerlaand',
 			'IL' => 'Israa’eel',
 			'IM' => 'Islee oof Maan',
 			'IN' => 'Hindii',
 			'IO' => 'Daangaa Galaana Hindii Biritish',
 			'IO@alt=chagos' => 'Chagos Arkipeloog',
 			'IQ' => 'Iraaq',
 			'IR' => 'Iraan',
 			'IS' => 'Ayeslaand',
 			'IT' => 'Xaaliyaan',
 			'JE' => 'Jeersii',
 			'JM' => 'Jamaayikaa',
 			'JO' => 'Jirdaan',
 			'JP' => 'Jaappaan',
 			'KE' => 'Keeniyaa',
 			'KG' => 'Kiyirigiyizistan',
 			'KH' => 'Kamboodiyaa',
 			'KI' => 'Kiribaatii',
 			'KM' => 'Komoroos',
 			'KN' => 'St. Kiitis fi Neevis',
 			'KP' => 'Kooriyaa Kaaba',
 			'KR' => 'Kooriyaa Kibbaa',
 			'KW' => 'Kuweet',
 			'KY' => 'Odoloota Saaymaan',
 			'KZ' => 'Kazakistaan',
 			'LA' => 'Laa’oos',
 			'LB' => 'Libaanoon',
 			'LC' => 'St. Suusiyaa',
 			'LI' => 'Lichistensteyin',
 			'LK' => 'Siri Laankaa',
 			'LR' => 'Laayibeeriyaa',
 			'LS' => 'Leseettoo',
 			'LT' => 'Lutaaniyaa',
 			'LU' => 'Luksembarg',
 			'LV' => 'Lativiyaa',
 			'LY' => 'Liibiyaa',
 			'MA' => 'Morookoo',
 			'MC' => 'Moonaakoo',
 			'MD' => 'Moldoovaa',
 			'ME' => 'Montenegiroo',
 			'MF' => 'St. Martiin',
 			'MG' => 'Madagaaskaar',
 			'MH' => 'Odoloota Maarshaal',
 			'MK' => 'Maqdooniyaa Kaabaa',
 			'ML' => 'Maalii',
 			'MM' => 'Maayinaamar (Burma)',
 			'MN' => 'Mongoliyaa',
 			'MO' => 'Maka’oo SAR Chaayinaa',
 			'MO@alt=short' => 'Maka’oo',
 			'MP' => 'Odola Maariyaanaa Kaabaa',
 			'MQ' => 'Martinikuwee',
 			'MR' => 'Mawuritaaniyaa',
 			'MS' => 'Montiseerat',
 			'MT' => 'Maaltaa',
 			'MU' => 'Moorishiyees',
 			'MV' => 'Maaldiivs',
 			'MW' => 'Maalaawwii',
 			'MX' => 'Meeksiikoo',
 			'MY' => 'Maleeshiyaa',
 			'MZ' => 'Moozaambik',
 			'NA' => 'Namiibiyaa',
 			'NC' => 'Neewu Kaaleedoniyaa',
 			'NE' => 'Niijer',
 			'NF' => 'Odola Noorfoolk',
 			'NG' => 'Naayijeeriyaa',
 			'NI' => 'Nikaraguwaa',
 			'NL' => 'Neezerlaand',
 			'NO' => 'Noorwey',
 			'NP' => 'Neeppal',
 			'NR' => 'Naawuruu',
 			'NU' => 'Niwu’e',
 			'NZ' => 'Neewu Zilaand',
 			'NZ@alt=variant' => 'Awoteyarowa Neewu Zilaand',
 			'OM' => 'Omaan',
 			'PA' => 'Paanamaa',
 			'PE' => 'Peeruu',
 			'PF' => 'Polineeshiyaa Faransaay',
 			'PG' => 'Papuwa Neawu Giinii',
 			'PH' => 'Filippiins',
 			'PK' => 'Paakistaan',
 			'PL' => 'Poolaand',
 			'PM' => 'Ql. Piyeeree fi Mikuyelon',
 			'PN' => 'Odoloota Pitikaayirin',
 			'PR' => 'Poortaar Riikoo',
 			'PS' => 'Daangaawwan Paalestaayin',
 			'PS@alt=short' => 'Paalestaayin',
 			'PT' => 'Poorchugaal',
 			'PW' => 'Palaawu',
 			'PY' => 'Paaraguwaay',
 			'QA' => 'Kuwaatar',
 			'QO' => 'Ooshiiniyaa Alaa',
 			'RE' => 'Riyuuniyeen',
 			'RO' => 'Roomaaniyaa',
 			'RS' => 'Serbiyaa',
 			'RU' => 'Raashiyaa',
 			'RW' => 'Ruwwandaa',
 			'SA' => 'Saawud Arabiyaa',
 			'SB' => 'Odoloota Solomoon',
 			'SC' => 'Siisheels',
 			'SD' => 'Sudaan',
 			'SE' => 'Siwiidin',
 			'SG' => 'Singaapoor',
 			'SH' => 'St. Helenaa',
 			'SI' => 'Islooveeniyaa',
 			'SJ' => 'Isvaalbaard fi Jan Mayeen',
 			'SK' => 'Isloovaakiyaa',
 			'SL' => 'Seeraaliyoon',
 			'SM' => 'Saan Mariinoo',
 			'SN' => 'Senegaal',
 			'SO' => 'Somaaliyaa',
 			'SR' => 'Suriname',
 			'SS' => 'Sudaan Kibbaa',
 			'ST' => 'Sa’oo Toomee fi Prinsippee',
 			'SV' => 'El Salvaadoor',
 			'SX' => 'Siint Maarteen',
 			'SY' => 'Sooriyaa',
 			'SZ' => 'Iswaatinii',
 			'SZ@alt=variant' => 'Siwaazilaand',
 			'TA' => 'Tiristaan da Kanhaa',
 			'TC' => 'Turkis fi Odoloota Kaayikos',
 			'TD' => 'Chaad',
 			'TF' => 'Daangaawwan Kibbaa Faransaay',
 			'TG' => 'Toogoo',
 			'TH' => 'Taayilaand',
 			'TJ' => 'Tajikistaan',
 			'TK' => 'Tokelau',
 			'TL' => 'Tiimoor-Leestee',
 			'TL@alt=variant' => 'Tiimoor Bahaa',
 			'TM' => 'Turkimenistaan',
 			'TN' => 'Tuniiziyaa',
 			'TO' => 'Tonga',
 			'TR' => 'Tarkiye',
 			'TR@alt=variant' => 'Turkii',
 			'TT' => 'Tirinidan fi Tobaagoo',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taayiwwan',
 			'TZ' => 'Taanzaaniyaa',
 			'UA' => 'Yuukireen',
 			'UG' => 'Ugaandaa',
 			'UM' => 'U.S. Odoloota Alaa',
 			'UN' => 'Mootummoota Gamtooman',
 			'US' => 'Yiinaayitid Isteet',
 			'US@alt=short' => 'US',
 			'UY' => 'Yuraagaay',
 			'UZ' => 'Uzbeekistaan',
 			'VA' => 'Vaatikaan Siitii',
 			'VC' => 'St. Vinseet fi Gireenadines',
 			'VE' => 'Veenzuweelaa',
 			'VG' => 'Odoloota Varjiin Biritish',
 			'VI' => 'U.S. Odoloota Varjiin',
 			'VN' => 'Veetinaam',
 			'VU' => 'Vanuwaatu',
 			'WF' => 'Waalis fi Futtuuna',
 			'WS' => 'Saamowa',
 			'XA' => 'Loqoda Sobaa',
 			'XB' => 'Biidii Sobaa',
 			'XK' => 'Kosoovoo',
 			'YE' => 'Yemen',
 			'YT' => 'Maayootee',
 			'ZA' => 'Afrikaa Kibbaa',
 			'ZM' => 'Zaambiyaa',
 			'ZW' => 'Zimbaabuwee',
 			'ZZ' => 'Naannoo Hin Beekamne',

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
 				'ethiopic' => q{Dhaha Baraa Itoophiyaa},
 				'gregorian' => q{Dhaha Baraa Gorgooriyaa},
 				'iso8601' => q{Dhaba Baraa ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{Ajaja Calallii Istaandaardii},
 			},
 			'numbers' => {
 				'latn' => q{Dijiitiiwwan Warra Dhihaa},
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
			'metric' => q{Meetirikii},
 			'UK' => q{Inglizi},
 			'US' => q{Ameerikaa},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Afaan: {0}',
 			'script' => 'Barreeffama: {0}',
 			'region' => 'Naannoo: {0}',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] @ * / # ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has traditional_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'ethi',
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'one' => 'Kuma 0',
					'other' => 'kuma 0',
				},
				'10000' => {
					'one' => 'kuma 00',
					'other' => 'kuma 00',
				},
				'100000' => {
					'one' => 'kuma 000',
					'other' => 'kuma 000',
				},
				'1000000' => {
					'one' => 'miiliyoona 0',
					'other' => 'miiliyoona 0',
				},
				'10000000' => {
					'one' => 'miiliyoona 00',
					'other' => 'miiliyoona 00',
				},
				'100000000' => {
					'one' => 'miiliyoona 000',
					'other' => 'miiliyoona 000',
				},
				'1000000000' => {
					'one' => 'biiliyoona 0',
					'other' => 'biiliyoona 0',
				},
				'10000000000' => {
					'one' => 'biiliyoona 00',
					'other' => 'biiliyoona 00',
				},
				'100000000000' => {
					'one' => 'biiliyoona 000',
					'other' => 'biiliyoona 000',
				},
				'1000000000000' => {
					'one' => 'tiriiliyoona 0',
					'other' => 'tiriiliyoona 0',
				},
				'10000000000000' => {
					'one' => 'tiriiliyoona 00',
					'other' => 'tiriiliyoona 00',
				},
				'100000000000000' => {
					'one' => 'tiriiliyoona 000',
					'other' => 'tiriiliyoona 000',
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
		'BMD' => {
			display_name => {
				'currency' => q(Doolaara Beermudaa),
				'one' => q(Doolaara Beermudaa),
				'other' => q(Doolaarota Beermudaa),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brazilian Real),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Doolaara Beliizee),
				'one' => q(Doolaara Beliizee),
				'other' => q(Doolaarota Beliizee),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Doolaara Kanaadaa),
				'one' => q(Doolaara Kanaadaa),
				'other' => q(Doolaarota Kanaadaa),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinese Yuan Renminbi),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Koloonii Kostaa Rikaa),
				'one' => q(Koloonii Kostaa Rikaa),
				'other' => q(Koloonota Kostaa Rikaa),
			},
		},
		'ETB' => {
			symbol => 'Br',
			display_name => {
				'currency' => q(Itoophiyaa Birrii),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(British Pound),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indian Rupee),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japanese Yen),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russian Ruble),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Doolaara Ameerikaa),
				'one' => q(Doolaara Ameerikaa),
				'other' => q(Doolarota Ameerikaa),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'ethiopic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Ful',
							'Onk',
							'Sad',
							'Mud',
							'Ama',
							'Gur',
							'Bit',
							'Ebi',
							'Cam',
							'Wax',
							'Ado',
							'Hag',
							'Qam'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Fulbaana',
							'Guraandhala',
							'Sadaasa',
							'Mudde',
							'Amajji',
							'Waxabajjii',
							'Bitootessa',
							'Eebila',
							'Caamsaa',
							'Onkoloolessa',
							'Adoolessa',
							'Hagayya',
							'Qaam’ee'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'F',
							'O',
							'S',
							'M',
							'Am',
							'G',
							'B',
							'E',
							'C',
							'W',
							'Ad',
							'H',
							'Q'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Fulbaana',
							'Guraandhala',
							'Sadaasa',
							'Mudde',
							'Amajji',
							'Waxabajjii',
							'Bitootessa',
							'Eebila',
							'Caamsaa',
							'Onkoloolessa',
							'Adoolessa',
							'Hagayya',
							'Qaam’ee'
						],
						leap => [
							
						],
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Ama',
							'Gur',
							'Bitootessa',
							'Elb',
							'Cam',
							'Wax',
							'Ado',
							'Hag',
							'Ful',
							'Onk',
							'Sadaasa',
							'Mud'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'A',
							'G',
							'B',
							'E',
							'C',
							'W',
							'A',
							'H',
							'F',
							'O',
							'S',
							'M'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Amajjii',
							'Guraandhala',
							'Bitootessa',
							'Eebila',
							'Caamsaa',
							'Waxabajjii',
							'Adoolessa',
							'Hagayya',
							'Fulbaana',
							'Onkoloolessa',
							'Sadaasa',
							'Mudde'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ama',
							'Gur',
							'Bitootessa',
							'Elb',
							'Cam',
							'Wax',
							'Ado',
							'Hag',
							'Ful',
							'Onk',
							'Sadaasa',
							'Mud'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'A',
							'G',
							'B',
							'E',
							'C',
							'W',
							'A',
							'H',
							'F',
							'O',
							'S',
							'M'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Amajjii',
							'Guraandhala',
							'Bitootessa',
							'Eebila',
							'Caamsaa',
							'Waxabajjii',
							'Adoolessa',
							'Hagayya',
							'Fulbaana',
							'Onkoloolessa',
							'Sadaasa',
							'Mudde'
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
						mon => 'Wix',
						tue => 'Kib',
						wed => 'Rob',
						thu => 'Kam',
						fri => 'Jim',
						sat => 'San',
						sun => 'Dil'
					},
					narrow => {
						mon => 'W',
						tue => 'K',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'Wix',
						tue => 'Kib',
						wed => 'Rob',
						thu => 'Kam',
						fri => 'Jim',
						sat => 'San',
						sun => 'Dil'
					},
					wide => {
						mon => 'Wiixata',
						tue => 'Kibxata',
						wed => 'Roobii',
						thu => 'Kamisa',
						fri => 'Jimaata',
						sat => 'Sanbata',
						sun => 'Dilbata'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Wix',
						tue => 'Kib',
						wed => 'Rob',
						thu => 'Kam',
						fri => 'Jim',
						sat => 'San',
						sun => 'Dil'
					},
					narrow => {
						mon => 'W',
						tue => 'K',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'Wix',
						tue => 'Kib',
						wed => 'Rob',
						thu => 'Kam',
						fri => 'Jim',
						sat => 'San',
						sun => 'Dil'
					},
					wide => {
						mon => 'Wiixata',
						tue => 'Kibxata',
						wed => 'Roobii',
						thu => 'Kamisa',
						fri => 'Jimaata',
						sat => 'Sanbata',
						sun => 'Dilbata'
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					wide => {0 => 'Kurmaana 1ffaa',
						1 => 'Kurmaana 2ffaa',
						2 => 'Kurmaana 3ffaa',
						3 => 'Kurmaana 4ffaa'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					wide => {0 => 'Kurmaana 1ffaa',
						1 => 'Kurmaana 2ffaa',
						2 => 'Kurmaana 3ffaa',
						3 => 'Kurmaana 4ffaa'
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
					'am' => q{WD},
					'pm' => q{WB},
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
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'DhKD',
				'1' => 'BA'
			},
			narrow => {
				'0' => 'Dh',
				'1' => 'B'
			},
			wide => {
				'0' => 'Dhaloota Kiristoos Dura',
				'1' => 'Bara Araaraa'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ethiopic' => {
		},
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
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ethiopic' => {
		},
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMdd => q{dd MMMM},
			MMdd => q{dd/MM},
			Md => q{M/d},
			y => q{y G},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
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
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMW => q{'torbee' W 'kan' MMMM},
			MMMMdd => q{MMMM dd},
			MMdd => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'torbee' w 'kan' Y},
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
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
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
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			h => {
				a => q{h a – h a },
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
				M => q{MMMM–MMMM y},
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
		regionFormat => q(Sa’aatii {0}),
		regionFormat => q(Sa’aatii Guyyaa {0}),
		regionFormat => q(Sa’aatii Istaandardii {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Sa’aatii Afgaanistaan#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Sa’aatii Afrikaa Gidduugaleessaa#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Sa’aatii Baha Afrikaa#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Sa’aatii Istaandaardii Afrikaa Kibbaa#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Afrikaa Dhihaa#,
				'generic' => q#Sa’aatii Afrikaa Dhihaa#,
				'standard' => q#Sa’aatii Istaandaardii Afrikaa Dhihaa#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Alaaskaa#,
				'generic' => q#Sa’aatii Alaaskaa#,
				'standard' => q#Sa’aatii Istaandaardii Alaaskaa#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Amazoon#,
				'generic' => q#Sa’aatii Amazoon#,
				'standard' => q#Sa’aatii Istaandaardii Amazoon#,
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Gidduugaleessaa#,
				'generic' => q#Sa’aatii Gidduugaleessaa#,
				'standard' => q#Sa’aatii Istaandaardii Gidduugaleessaa#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Bahaa#,
				'generic' => q#Sa’aatii Bahaa#,
				'standard' => q#Sa’aatii Istaandaardii Bahaa#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Maawonteen#,
				'generic' => q#Sa’aatii Maawonteen#,
				'standard' => q#Sa’aatii Istaandaardii Maawonteen#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Paasfiik#,
				'generic' => q#Sa’aatii Paasfiik#,
				'standard' => q#Sa’aatii Istaandaardii Paasfiik#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Apia#,
				'generic' => q#Sa’aatii Apia#,
				'standard' => q#Sa’aatii Istaandaardii Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Arabaa#,
				'generic' => q#Sa’aatii Arabaa#,
				'standard' => q#Sa’aatii Istaandaardii Arabaa#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Arjentiinaa#,
				'generic' => q#Sa’aatii Arjentiinaa#,
				'standard' => q#Sa’aatii Istaandaardii Arjentiinaa#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Arjentiinaa Dhihaa#,
				'generic' => q#Sa’aatii Arjentiinaa Dhihaa#,
				'standard' => q#Sa’aatii Istaandaardii Arjentiinaa Dhihaa#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Armaaniyaa#,
				'generic' => q#Sa’aatii Armaaniyaa#,
				'standard' => q#Sa’aatii Istaandaardii Armaaniyaa#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Atilaantiik#,
				'generic' => q#Sa’aatii Atilaantiik#,
				'standard' => q#Sa’aatii Istaandaardii Atilaantiik#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Awustiraaliyaa Gidduugaleessaa#,
				'generic' => q#Sa’aatii Awustiraaliyaa Gidduugaleessaa#,
				'standard' => q#Sa’aatii Istaandaardii Awustiraaliyaa Gidduugaleessaa#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Dhiha Awustiraaliyaa Gidduugaleessaa#,
				'generic' => q#Sa’aatii Dhiha Awustiraaliyaa Gidduugaleessaa#,
				'standard' => q#Sa’aatii Istaandaardii Dhiha Awustiraaliyaa Gidduugaleessaa#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Awustiraaliyaa Bahaa#,
				'generic' => q#Sa’aatii Awustiraaliyaa Bahaa#,
				'standard' => q#Sa’aatii Istaandaardii Awustiraaliyaa Bahaa#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Sa’aatii Guuyyaa Awustiraaliyaa Dhihaa#,
				'generic' => q#Sa’aatii Awustiraaliyaa Dhihaa#,
				'standard' => q#Sa’aatii Sa’aatii Istaandaardii Awustiraaliyaa DhihaaDhiha Awustiraaliyaa#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Azerbaajiyaan#,
				'generic' => q#Sa’aatii Azerbaajiyaan#,
				'standard' => q#Sa’aatii Istaandaardii Azerbaajiyaan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Azeeroos#,
				'generic' => q#Sa’aatii Azeeroos#,
				'standard' => q#Sa’aatii Istaandaardii Azeeroos#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Baangilaadish#,
				'generic' => q#Sa’aatii Baangilaadish#,
				'standard' => q#Sa’aatii Istaandaardii Baangilaadish#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Sa’aatii Bihutaan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Sa’aatii Boliiviyaa#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Biraaziliyaa#,
				'generic' => q#Sa’aatii Biraaziliyaa#,
				'standard' => q#Sa’aatii Istaandaardii Biraaziliyaa#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Sa’aatii Bruunee Darusalaam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Keep Veerdee#,
				'generic' => q#Sa’aatii Keep Veerdee#,
				'standard' => q#Sa’aatii Istaandaardii Keep Veerdee#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Sa’aatii Istaandaardii Kamoroo#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Chatham#,
				'generic' => q#Sa’aatii Chatham#,
				'standard' => q#Sa’aatii Istaandaardii Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Chiilii#,
				'generic' => q#Sa’aatii Chiilii#,
				'standard' => q#Sa’aatii Istaandaardii Chiilii#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Chaayinaa#,
				'generic' => q#Sa’aatii Chaayinaa#,
				'standard' => q#Sa’aatii Istaandaardii Chaayinaa#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Sa’aatii Odola Kirismaas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Sa’aatii Odoloota Kokos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Kolombiyaa#,
				'generic' => q#Sa’aatii Kolombiyaa#,
				'standard' => q#Sa’aatii Istaandaardii Kolombiyaa#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Sa’aatii Bona Walakkaa Odoloota Kuuk#,
				'generic' => q#Sa’aatii Odoloota Kuuk#,
				'standard' => q#Sa’aatii Istaandaardii Odoloota Kuuk#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Kuubaa#,
				'generic' => q#Sa’aatii Kuubaa#,
				'standard' => q#Sa’aatii Istaandaardii Kuubaa#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Sa’aatii Daaviis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Sa’aatii Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Sa’aatii Tiimoor Bahaa#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Odola Bahaa#,
				'generic' => q#Sa’aatii Odola Bahaa#,
				'standard' => q#Sa’aatii Istaandaardii Odola Bahaa#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Sa’aatii Ikkuwaadoor#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Sa’aatii Idil-Addunyaa Qindaa’e#,
			},
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Sa’aatii Istaandaardii Aayiriish#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Biritish#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Awurooppaa Gidduugaleessaa#,
				'generic' => q#Sa’aatii Awurooppaa Gidduugaleessaa#,
				'standard' => q#Sa’aatii Istaandaardii Awurooppaa Gidduugaleessaa#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Awurooppaa Bahaa#,
				'generic' => q#Saaatii Awurooppaa Bahaa#,
				'standard' => q#Sa’aatii Istaandaardii Awurooppaa Bahaa#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Sa’aatii Awurooppaa Bahaa Dabalataa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Awurooppaa Dhihaa#,
				'generic' => q#Sa’aatii Awurooppaa Dhihaa#,
				'standard' => q#Sa’aatii Istaandaardii Awurooppaa Dhihaa#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Odoloota Faalklaand#,
				'generic' => q#Sa’aatii Odoloota Faalklaand#,
				'standard' => q#Sa’aatii Istaandaardii Odoloota Faalklaand#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Fiijii#,
				'generic' => q#Sa’aatii Fiijii#,
				'standard' => q#Sa’aatii Istaandaardii Fiijii#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Sa’aatii Fireench Guyinaa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Sa’aatii Firaans Kibbaa fi Antaarktikaa#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Sa’aatii Giriinwiich Gidduugaleessaa#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Sa’aatii Galaapagoos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Sa’aatii Gaambiyeer#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Joorjiyaa#,
				'generic' => q#Sa’aatii Joorjiyaa#,
				'standard' => q#Sa’aatii Istaandaardii Joorjiyaa#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Sa’aatii Odoloota Giilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Giriinlaand Bahaa#,
				'generic' => q#Sa’aatii Giriinlaand Bahaa#,
				'standard' => q#Sa’aatii Istaandaardii Giriinlaand Bahaa#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Giriinlaand Dhihaa#,
				'generic' => q#Sa’aatii Giriinlaand Dhihaa#,
				'standard' => q#Sa’aatii Istaandaardii Giriinlaand Dhihaa#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Sa’aatii Istaandaardii Guwaam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Sa’aatii Istaandaardii Gaalfii#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Sa’aatii Guyaanaa#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Haawayi-Alewutiyan#,
				'generic' => q#Sa’aatii Haawayi-Alewutiyan#,
				'standard' => q#Sa’aatii Istaandaardii Haawayi-Alewutiyan#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAS#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Hoong Koong#,
				'generic' => q#Sa’aatii Hoong Koong#,
				'standard' => q#Sa’aatii Istaandaardii Hoong Koong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Hoovd#,
				'generic' => q#Sa’aatii Hoovd#,
				'standard' => q#Sa’aatii Istaandaardii Hoovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Sa’aatii Istaandaardii Hindii#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Sa’aatii Galaana Hindii#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Sa’aatii IndooChaayinaa#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Sa’aatii Indooneeshiyaa Gidduugaleessaa#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Sa’aatii Indooneshiyaa Bahaa#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Sa’aatii Indooneeshiyaa Dhihaa#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Iraan#,
				'generic' => q#Sa’aatii Iraan#,
				'standard' => q#Sa’aatii Istaandaardii Iraan#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Irkutsk#,
				'generic' => q#Sa’aatii Irkutsk#,
				'standard' => q#Sa’aatii Istaandaardii Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Israa’eel#,
				'generic' => q#Sa’aatii Israa’eel#,
				'standard' => q#Sa’aatii Istaandaardii Israa’eel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Jaappaan#,
				'generic' => q#Sa’aatii Jaappaan#,
				'standard' => q#Sa’aatii Istaandaardii Jaappaan#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Sa’aatii Kaazaakistaan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Sa’aatii Kaazaakistaan Bahaa#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Sa’aatii Kaazaakistaan Dhihaa#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Kooriyaa#,
				'generic' => q#Sa’aatii Kooriyaa#,
				'standard' => q#Sa’aatii Istaandaardii Kooriyaa#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Sa’aatii Koosreyaa#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Krasnoyarsk#,
				'generic' => q#Sa’aatii Krasnoyarsk#,
				'standard' => q#Sa’aatii Istaandaardii Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Sa’aatii Kiyirigiyistan#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Sa’aatii Laankaa#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Sa’aatii Odoloota Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Lord Howe#,
				'generic' => q#Sa’aatii Lord Howe#,
				'standard' => q#Sa’aatii Istaandaardii Lord Howe#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Magadan#,
				'generic' => q#Sa’aatii Magadan#,
				'standard' => q#Sa’aatii Istaandaardii Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Sa’aatii Maaleeshiyaa#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Sa’aatii Maaldiivs#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Sa’aatii Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Sa’aatii Odoloota Maarshaal#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Moorishiyees#,
				'generic' => q#Sa’aatii Mooriishiyees#,
				'standard' => q#Sa’aatii Istaandaardii Moorishiyees#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Sa’aatii Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Paasfiik Meksiikaan#,
				'generic' => q#Sa’aatii Paasfiik Meksiikaan#,
				'standard' => q#Sa’aatii Istaandaardii Paasfiik Meksiikaan#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Ulaanbaatar#,
				'generic' => q#Sa’aatii Ulaanbaatar#,
				'standard' => q#Sa’aatii Istaandaardii Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Mooskoo#,
				'generic' => q#Sa’aatii Mooskoo#,
				'standard' => q#Sa’aatii Istaandaardii Mooskoo#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Sa’aatii Maayinaamaar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Sa’aatii Naawuruu#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Sa’aatii Neeppaal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Kaaledooniyaa Haaraa#,
				'generic' => q#Sa’aatii Kaaledooniyaa Haaraa#,
				'standard' => q#Sa’aatii Istaandaardii Kaaledooniyaa Haaraa#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa New Zealand#,
				'generic' => q#Sa’aatii New Zealand#,
				'standard' => q#Sa’aatii Istaandaardii New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Newufaawondlaand#,
				'generic' => q#Sa’aatii Newufaawondlaand#,
				'standard' => q#Sa’aatii Istaandaardii Newufaawondlaand#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Sa’aatii Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Norfolk Island#,
				'generic' => q#Sa’aatii Norfolk Island#,
				'standard' => q#Sa’aatii Istaandaardii Norfolk Island#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Fernando de Noronha#,
				'generic' => q#Sa’aatii Fernando de Noronha#,
				'standard' => q#Sa’aatii Istaandaardii Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Sa’aatii Odoloota Maariyaanaa Kaabaa#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Novosibirisk#,
				'generic' => q#Sa’aatii Novosibirisk#,
				'standard' => q#Sa’aatii Istaandaardii Novosibirisk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Omsk#,
				'generic' => q#Sa’aatii Omsk#,
				'standard' => q#Sa’aatii Istaandaardii Omsk#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Paakistaan#,
				'generic' => q#Sa’aatii Paakistaan#,
				'standard' => q#Sa’aatii Istaandaardii Paakistaan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Sa’aatii Palawu#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Sa’aatii Paapuwaa Giinii Haaraa#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Paaraaguwaayi#,
				'generic' => q#Sa’aatii Paaraaguwaayi#,
				'standard' => q#Sa’aatii Istaandaardii Paaraaguwaayi#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Peeruu#,
				'generic' => q#Sa’aatii Peeruu#,
				'standard' => q#Sa’aatii Istaandaardii Peeruu#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Filippiins#,
				'generic' => q#Sa’aatii Filippiins#,
				'standard' => q#Sa’aatii Istaandaardii Filippiins#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Sa’aatii Odoloota Fooneeks#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Ql. Piyeeree fi Mikuyelo#,
				'generic' => q#Sa’aatii Ql. Piyeeree fi Mikuyelo#,
				'standard' => q#Sa’aatii Istaandaardii Ql. Piyeeree fi Mikuyelo#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Sa’aatii Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Sa’aatii Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Sa’aatii Piyoongyaang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Sa’aatii Riiyuuniyeen#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Sa’aatii Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Sakhalin#,
				'generic' => q#Sa’aatii Sakhalin#,
				'standard' => q#Sa’aatii Istaandaardii Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Saamowaa#,
				'generic' => q#Sa’aatii Saamowaa#,
				'standard' => q#Sa’aatii Istaandaardii Saamowaa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Sa’aatii Siisheels#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Sa’aatii Istaandaardii Singaapoor#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Sa’aatii Odoloota Solomoon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Sa’aatii Joorjiyaa Kibbaa#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Sa’aatii Surinaame#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Sa’aatii Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Sa’aatii Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Sa’aatii Guyyaa Tayipeyi#,
				'generic' => q#Sa’aatii Tayipeyi#,
				'standard' => q#Sa’aatii Istaandaardii Tayipeyi#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Sa’aatii Tajikistaan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Sa’aatii Takelawu#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Tonga#,
				'generic' => q#Sa’aatii Tonga#,
				'standard' => q#Sa’aatii Istaandaardii Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Sa’aatii Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Turkemenistaan#,
				'generic' => q#Sa’aatii Turkemenistaan#,
				'standard' => q#Sa’aatii Istaandaardii Turkemenistaan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Sa’aatii Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Yuraagaayi#,
				'generic' => q#Sa’aatii Yuraagaayi#,
				'standard' => q#Sa’aatii Istaandaardii Yuraagaayi#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Uzbeekistaan#,
				'generic' => q#Sa’aatii Uzbeekistaan#,
				'standard' => q#Sa’aatii Istaandaardii Uzbeekistaan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Vanuwatu#,
				'generic' => q#Sa’aatii Vanuwatu#,
				'standard' => q#Sa’aatii Istaandaardii Vanuwatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Sa’aatii Veenzuweelaa#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Vladivostok#,
				'generic' => q#Sa’aatii Vladivostok#,
				'standard' => q#Sa’aatii Istaandaardii Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Volgograd#,
				'generic' => q#Sa’aatii Volgograd#,
				'standard' => q#Sa’aatii Istaandaardii Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Sa’aatii Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Sa’aatii Odola Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Sa’aatii Wallis fi Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Yakutsk#,
				'generic' => q#Sa’aatii Yakutsk#,
				'standard' => q#Sa’aatii Istaandardii Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Sa’aatii Bonaa Yekaterinburg#,
				'generic' => q#Sa’aatii Yekaterinburg#,
				'standard' => q#Sa’aatii Istaandaardii Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Sa’aatii Yuukoon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
