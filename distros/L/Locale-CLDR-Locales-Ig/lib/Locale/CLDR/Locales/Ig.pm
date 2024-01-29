=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ig - Package for language Igbo

=cut

package Locale::CLDR::Locales::Ig;
# This file auto generated from Data\common\main\ig.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'af' => 'Afrikaans',
 				'agq' => 'Aghem',
 				'ak' => 'Akan',
 				'am' => 'Amariikị',
 				'ar' => 'Arabiikị',
 				'ar_001' => 'Ụdị Arabiikị nke oge a',
 				'asa' => 'Asụ',
 				'az' => 'Azerbajanị',
 				'az@alt=short' => 'Azeri',
 				'be' => 'Belarusianụ',
 				'bez' => 'Bena',
 				'bg' => 'Bọlụgarịa',
 				'bm' => 'Bambara',
 				'bn' => 'Bengali',
 				'bo' => 'Tibetan',
 				'br' => 'Breton',
 				'brx' => 'Bọdọ',
 				'bs' => 'Bosnia',
 				'ca' => 'Catalan',
 				'ccp' => 'Chakma',
 				'ce' => 'Chechen',
 				'ceb' => 'Cebụanọ',
 				'chr' => 'Cheroke',
 				'ckb@alt=menu' => 'Kurdish ọsote',
 				'ckb@alt=variant' => 'Kurdish ọzọ',
 				'co' => 'Kọsịan',
 				'cs' => 'Cheekị',
 				'cu' => 'Church slavic',
 				'cy' => 'Wesh',
 				'da' => 'Danịsh',
 				'dav' => 'Taịta',
 				'de' => 'Jamanị',
 				'de_AT' => 'Jaman ndị Austria',
 				'de_CH' => 'Jaman Izugbe ndị Switzerland',
 				'dje' => 'Zarma',
 				'dsb' => 'Lowa Sorbịan',
 				'dua' => 'Dụala',
 				'dyo' => 'Jọla-Fọnyị',
 				'dz' => 'Dọzngọka',
 				'ebu' => 'Ebụm',
 				'ee' => 'Ewe',
 				'el' => 'Giriikị',
 				'en' => 'Bekee',
 				'en_AU' => 'Bekee ndị Australia',
 				'en_CA' => 'Bekee ndị Canada',
 				'en_GB' => 'Bekee ndị United Kingdom',
 				'en_GB@alt=short' => 'Bekee ndị UK',
 				'en_US' => 'Bekee ndị America',
 				'en_US@alt=short' => 'Bekee ndị US',
 				'eo' => 'Ndị Esperantọ',
 				'es' => 'Spanishi',
 				'es_419' => 'Spanishi ndị Latin America',
 				'es_ES' => 'Spanishi ndị Europe',
 				'es_MX' => 'Spanishi ndị Mexico',
 				'et' => 'Ndị Estọnịa',
 				'eu' => 'Baskwe',
 				'ewo' => 'Ewọndọ',
 				'fa' => 'Peshianụ',
 				'ff' => 'Fula',
 				'fi' => 'Fịnịsh',
 				'fil' => 'Fịlịpịnọ',
 				'fo' => 'Farọse',
 				'fr' => 'Fụrenchị',
 				'fr_CA' => 'Fụrench ndị Canada',
 				'fr_CH' => 'Fụrench ndị Switzerland',
 				'fur' => 'Frụlịan',
 				'fy' => 'Westan Frịsịan',
 				'ga' => 'Ịrịsh',
 				'gd' => 'Sụkọtịs Gelị',
 				'gl' => 'Galịcịan',
 				'gsw' => 'German Swiss',
 				'gu' => 'Gụaratị',
 				'guz' => 'Gụshị',
 				'gv' => 'Mansị',
 				'ha' => 'Hausa',
 				'haw' => 'Hawaịlịan',
 				'he' => 'Hebrew',
 				'hi' => 'Hindị',
 				'hmn' => 'Hmong',
 				'hr' => 'Kọrọtịan',
 				'hsb' => 'Ụpa Sọrbịa',
 				'ht' => 'Haịtịan ndị Cerọle',
 				'hu' => 'Hụngarian',
 				'ia' => 'Intalịgụa',
 				'id' => 'Indonisia',
 				'ig' => 'Igbo',
 				'ii' => 'Sịchụayị',
 				'is' => 'Icịlandịk',
 				'it' => 'Italịanu',
 				'ja' => 'Japaniisi',
 				'jgo' => 'Ngọmba',
 				'jmc' => 'Machame',
 				'jv' => 'Java',
 				'ka' => 'Geọjịan',
 				'kab' => 'Kabyle',
 				'kam' => 'Kamba',
 				'kde' => 'Makọnde',
 				'kea' => 'Kabụverdịanụ',
 				'khq' => 'Kọyra Chịnị',
 				'ki' => 'Kịkụyụ',
 				'kk' => 'Kazak',
 				'kkj' => 'Kakọ',
 				'kl' => 'Kalaalịsụt',
 				'kln' => 'Kalenjịn',
 				'km' => 'Keme',
 				'kn' => 'Kanhada',
 				'ko' => 'Korịa',
 				'kok' => 'Kọnkanị',
 				'ks' => 'Kashmịrị',
 				'ksb' => 'Shabala',
 				'ksf' => 'Bafịa',
 				'ksh' => 'Colognịan',
 				'ku' => 'Ndị Kụrdịsh',
 				'kw' => 'Kọnịsh',
 				'ky' => 'Kyrayz',
 				'la' => 'Latịn',
 				'lag' => 'Langị',
 				'lb' => 'Lụxenbọụgịsh',
 				'lg' => 'Ganda',
 				'ln' => 'Lịngala',
 				'lo' => 'Laọ',
 				'lrc' => 'Nọrtụ Lụrị',
 				'lt' => 'Lituanian',
 				'lu' => 'Lịba-Katanga',
 				'luy' => 'Lụyịa',
 				'lv' => 'Latviani',
 				'mai' => 'Maịtịlị',
 				'mas' => 'Masaị',
 				'mer' => 'Merụ',
 				'mfe' => 'Mọrịsye',
 				'mg' => 'Malagasị',
 				'mgh' => 'Makụwa Metọ',
 				'mgo' => 'Meta',
 				'mi' => 'Maọrị',
 				'mk' => 'Masedọnịa',
 				'ml' => 'Malayalam',
 				'mn' => 'Mọngolịan',
 				'mni' => 'Manịpụrị',
 				'mr' => 'Maratị',
 				'ms' => 'Maleyi',
 				'mt' => 'Matịse',
 				'mua' => 'Mụdang',
 				'mul' => 'Ọtụtụ asụsụ',
 				'my' => 'Bụrmese',
 				'mzn' => 'Mazandaranị',
 				'naq' => 'Nama',
 				'nb' => 'Nọrweyịan Bọkmal',
 				'nd' => 'Nọrtụ Ndabede',
 				'nds' => 'Lowa German',
 				'ne' => 'Nepali',
 				'nl' => 'Dọchị',
 				'nmg' => 'Kwasịọ',
 				'nn' => 'Nọrweyịan Nynersk',
 				'nnh' => 'Nglembọn',
 				'nus' => 'Nụer',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyakọle',
 				'om' => 'Ọromo',
 				'or' => 'Ọdịa',
 				'os' => 'Osetik',
 				'pa' => 'Punjabi',
 				'pcm' => 'Pidgịn',
 				'pl' => 'Poliishi',
 				'prg' => 'Prụssịan',
 				'ps' => 'Pashọ',
 				'pt' => 'Pọrtụgụese',
 				'pt_BR' => 'Pọrtụgụese ndị Brazil',
 				'pt_PT' => 'Asụsụ Portuguese ndị Europe',
 				'qu' => 'Qụechụa',
 				'rm' => 'Rọmansị',
 				'rn' => 'Rụndị',
 				'ro' => 'Romania',
 				'rof' => 'Rọmbọ',
 				'ru' => 'Rọshian',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sansịkịt',
 				'sah' => 'Saka',
 				'saq' => 'Sambụrụ',
 				'sat' => 'Santalị',
 				'sbp' => 'Sangụ',
 				'sd' => 'Sịndh',
 				'se' => 'Nọrtan Samị',
 				'seh' => 'Sena',
 				'ses' => 'Kọyraboro Senị',
 				'sg' => 'Sangọ',
 				'shi' => 'Tachịkịt',
 				'si' => 'Sinhala',
 				'sk' => 'Slova',
 				'sl' => 'Slovịan',
 				'sm' => 'Samọa',
 				'smn' => 'Inarị Samị',
 				'sn' => 'Shọna',
 				'so' => 'Somali',
 				'sr' => 'Sebịan',
 				'st' => 'Sọụth Soto',
 				'sv' => 'Sụwidiishi',
 				'ta' => 'Tamil',
 				'te' => 'Telụgụ',
 				'teo' => 'Tesọ',
 				'tg' => 'Tajịk',
 				'th' => 'Taị',
 				'ti' => 'Tịgrịnya',
 				'tk' => 'Turkịs',
 				'to' => 'Tọngan',
 				'tr' => 'Tọkiishi',
 				'tt' => 'Tata',
 				'twq' => 'Tasawa',
 				'ug' => 'Ụyghụr',
 				'uk' => 'Ukureenị',
 				'und' => 'Asụsụ amaghị',
 				'ur' => 'Urdụ',
 				'uz' => 'Ụzbek',
 				'vai' => 'Val',
 				'vi' => 'Vietnamisi',
 				'vo' => 'Volapụ',
 				'vun' => 'Vụnjọ',
 				'wae' => 'Wasa',
 				'wo' => 'Wolọf',
 				'xh' => 'Xhọsa',
 				'xog' => 'Sọga',
 				'yav' => 'Yangben',
 				'yi' => 'Yịdịsh',
 				'yo' => 'Yoruba',
 				'yue' => 'Katọnịse',
 				'yue@alt=menu' => 'Chinese,Cantonese',
 				'zh' => 'Chainisi',
 				'zh_Hans' => 'Asụsụ Chinese dị mfe',
 				'zh_Hant' => 'Asụsụ Chinese Izugbe',
 				'zu' => 'Zulu',
 				'zxx' => 'Ndị ọzọ abụghị asụsụ',

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
			'Arab' => 'Mkpụrụ Okwu Arabic',
 			'Armn' => 'Mkpụrụ ọkwụ Armenịan',
 			'Beng' => 'Mkpụrụ ọkwụ Bangla',
 			'Bopo' => 'Mkpụrụ ọkwụ Bopomofo',
 			'Brai' => 'Braịlle',
 			'Cyrl' => 'Mkpụrụ Okwu Cyrillic',
 			'Deva' => 'Mkpụrụ ọkwụ Devangarị',
 			'Ethi' => 'Mkpụrụ ọkwụ Etọpịa',
 			'Geor' => 'Mkpụrụ ọkwụ Geọjịan',
 			'Grek' => 'Mkpụrụ ọkwụ grịk',
 			'Gujr' => 'Mkpụrụ ọkwụ Gụjaratị',
 			'Guru' => 'Mkpụrụ ọkwụ Gụrmụkị',
 			'Hanb' => 'Han na Bopomofo',
 			'Hang' => 'Mkpụrụ ọkwụ Hangụl',
 			'Hani' => 'Mkpụrụ ọkwụ Han',
 			'Hans' => 'Nke dị mfe',
 			'Hans@alt=stand-alone' => 'Han di mfe',
 			'Hant' => 'Izugbe',
 			'Hant@alt=stand-alone' => 'Han Izugbe',
 			'Hebr' => 'Mkpụrụ ọkwụ Hebrew',
 			'Hira' => 'Mkpụrụ okwụ Hịragana',
 			'Hrkt' => 'mkpụrụ ọkwụ Japanịsị',
 			'Jamo' => 'Jamọ',
 			'Jpan' => 'Japanese',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannaada',
 			'Kore' => 'Korea',
 			'Laoo' => 'Laọ',
 			'Latn' => 'Latin',
 			'Mlym' => 'Malayala',
 			'Mong' => 'Mọngọlịan',
 			'Mymr' => 'Myanmar',
 			'Orya' => 'Ọdịa',
 			'Sinh' => 'Sinhala',
 			'Taml' => 'Tamịl',
 			'Telu' => 'Telụgụ',
 			'Thaa' => 'Taa',
 			'Tibt' => 'Tịbeta',
 			'Zmth' => 'Mkpụrụ ọkwụ Mgbakọ',
 			'Zsye' => 'Emojị',
 			'Zsym' => 'Akara',
 			'Zxxx' => 'Edeghị ede',
 			'Zyyy' => 'kọmọn',
 			'Zzzz' => 'Mkpụrụ okwu amaghị',

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
			'001' => 'Uwa',
 			'002' => 'Afrika',
 			'003' => 'Mpaghara Ugwu Amerịka',
 			'005' => 'Mpaghara Mgbada Ugwu America',
 			'009' => 'Oceania',
 			'011' => 'Mpaghara Ọdịda Anyanwụ Afrịka',
 			'013' => 'Etiti America',
 			'014' => 'Mpaghara Ọwụwa Anyanwụ Afrịka',
 			'015' => 'Mpaghara Ugwu Afrịka',
 			'017' => 'Etiti Afrịka',
 			'018' => 'Mpaghara Mgbada Ugwu Afrịka',
 			'019' => 'Amerịka',
 			'021' => 'Mpaghara Ugwu America',
 			'029' => 'Onye Carrabean',
 			'030' => 'Mpaghara Ọwụwa Anyanwụ Asia',
 			'034' => 'Mpaghara Mgbada Ugwu Asia',
 			'035' => 'Mpaghara Mgbada Ugwu Asia dị na Ọwụwa Anyanwụ',
 			'039' => 'Mpaghara Mgbada Ugwu Europe',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Mpaghara Micronesian',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Etiti Asia',
 			'145' => 'Mpaghara Ọdịda Anyanwụ Asia',
 			'150' => 'Europe',
 			'151' => 'Mpaghara Ọwụwa Anyanwụ Europe',
 			'154' => 'Mpaghara Ugwu Europe',
 			'155' => 'Mpaghara Ọdịda Anyanwụ Europe',
 			'202' => 'Sub-Saharan Afrịka',
 			'419' => 'Latin America',
 			'AC' => 'Ascension Island',
 			'AD' => 'Andorra',
 			'AE' => 'United Arab Emirates',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua na Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentina',
 			'AS' => 'American Samoa',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Agwaetiti Aland',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia & Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgium',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Binin',
 			'BL' => 'Barthélemy Dị nsọ',
 			'BM' => 'Bemuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribbean Netherlands',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Agwaetiti Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Agwaetiti Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Central African Republik',
 			'CG' => 'Congo',
 			'CG@alt=variant' => 'Congo (Republik)',
 			'CH' => 'Switzerland',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Ivory Coast',
 			'CK' => 'Agwaetiti Cook',
 			'CL' => 'Chile',
 			'CM' => 'Cameroon',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Agwaetiti Clipperton',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Kurakao',
 			'CX' => 'Agwaetiti Christmas',
 			'CY' => 'Cyprus',
 			'CZ' => 'Czechia',
 			'CZ@alt=variant' => 'Czech Republik',
 			'DE' => 'Jamanị',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominika',
 			'DO' => 'Dominican Republik',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta & Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egypt',
 			'EH' => 'Ọdịda Anyanwụ Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spain',
 			'ET' => 'Ethiopia',
 			'EU' => 'Otu nzukọ mba Europe',
 			'EZ' => 'Gburugburu Euro',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Agwaetiti Falkland',
 			'FM' => 'Micronesia',
 			'FO' => 'Agwaetiti Faroe',
 			'FR' => 'France',
 			'GA' => 'Gabon',
 			'GB' => 'United Kingdom',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Frenchi Guiana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorial Guinea',
 			'GR' => 'Greece',
 			'GS' => 'South Georgia na Agwaetiti South Sandwich',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR China',
 			'HM' => 'Agwaetiti Heard na Agwaetiti McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Hati',
 			'HU' => 'Hungary',
 			'IC' => 'Agwaetiti Kanarị',
 			'ID' => 'Indonesia',
 			'IE' => 'Ireland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'British Indian Ocean Territory',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Iceland',
 			'IT' => 'Italy',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Cambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comorosu',
 			'KN' => 'Kitts na Nevis Dị nsọ',
 			'KP' => 'Ugwu Korea',
 			'KR' => 'South Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Agwaetiti Cayman',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Lebanon',
 			'LC' => 'Lucia Dị nsọ',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libia',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Martin Dị nsọ',
 			'MG' => 'Madagaskar',
 			'MH' => 'Agwaetiti Marshall',
 			'MK' => 'North Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao SAR China',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Agwaetiti Northern Mariana',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldivesa',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibia',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Agwaetiti Norfolk',
 			'NG' => 'Naịjịrịa',
 			'NI' => 'Nicaragua',
 			'NL' => 'Netherlands',
 			'NO' => 'Norway',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Frenchi Polynesia',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Philippines',
 			'PK' => 'Pakistan',
 			'PL' => 'Poland',
 			'PM' => 'Pierre na Miquelon Dị nsọ',
 			'PN' => 'Agwaetiti Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinian Territories',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Outlying Oceania',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Rụssịa',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Agwaetiti Solomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Sweden',
 			'SG' => 'Singapore',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard & Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'South Sudan',
 			'ST' => 'São Tomé & Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Agwaetiti Turks na Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Ụmụ ngalaba Frenchi Southern',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'East Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkey',
 			'TT' => 'Trinidad na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'Obere Agwaetiti Dị Na Mpụga U.S',
 			'UN' => 'Mba Ụwa Jikọrọ Ọnụ',
 			'US' => 'United States',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatican City',
 			'VC' => 'Vincent na Grenadines Dị nsọ',
 			'VE' => 'Venezuela',
 			'VG' => 'Agwaetiti British Virgin',
 			'VI' => 'Agwaetiti Virgin nke US',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis & Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-Accents',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'South Africa',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Mpaghara Amaghị',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalịnda',
 			'cf' => 'Ụsọrọ egọ',
 			'collation' => 'Ụsọrọ Nhazị',
 			'currency' => 'Egọ',
 			'hc' => 'Ọge ọkịrịkịrị',
 			'lb' => 'Akara akanka nkwụsị',
 			'ms' => 'Ụsọrọ Mmeshọ',
 			'numbers' => 'Nọmba',

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
 				'buddhist' => q{Kalịnda Bụddịst},
 				'chinese' => q{Kalịnda Chinese},
 				'dangi' => q{Kalịnda Dang},
 				'ethiopic' => q{Kalịnda Etopịa},
 				'gregorian' => q{Kalenda Gregory},
 				'hebrew' => q{Kalịnda Hebrew},
 				'islamic' => q{Kalịnda Islam},
 				'iso8601' => q{Kalenda ISO-8601},
 				'japanese' => q{Kalịnda Japanese},
 				'persian' => q{Kalịnda Persian},
 				'roc' => q{Kalịnda repụblic nke China},
 			},
 			'cf' => {
 				'account' => q{Ụsọrọ akantụ egọ},
 				'standard' => q{Ụsọrọ egọ nzụgbe},
 			},
 			'collation' => {
 				'search' => q{Ọchụchụ nịle},
 				'standard' => q{Usoro Nhazi},
 			},
 			'hc' => {
 				'h11' => q{Ụsọrọ Ọge ọkịrịkịri 12},
 				'h12' => q{Ụsọrọ Oge okịrịkịri 12},
 				'h23' => q{Ụsọrọ Oge okịrịkịrị 24},
 				'h24' => q{Ụsọrọ Ọge okịrịkịrị 24},
 			},
 			'lb' => {
 				'loose' => q{Akara akanka nkwụsị esịghị ịke},
 				'normal' => q{Akara akanka nkwụsị kwesịrị},
 				'strict' => q{Akara akanka nkwụsị sịrị ịke},
 			},
 			'ms' => {
 				'metric' => q{Ụsọrọ Metịrịk},
 				'uksystem' => q{Ụsọrọ Mmeshọ ịmperịa},
 				'ussystem' => q{Ụsọrọ Mmeshọ US},
 			},
 			'numbers' => {
 				'arab' => q{Ọnụ ọgụgụ Arab na Indị},
 				'arabext' => q{Ọnụ ọgụgụ Arab na Indị agbatịrị},
 				'armn' => q{Ọnụ ọgụgụ Armenịan},
 				'armnlow' => q{ọbere ọnụ ọgụgụ Armenịan},
 				'beng' => q{Ọnụ ọgụgụ Bang},
 				'deva' => q{Ọnụ ọgụgụ Devanagarị},
 				'ethi' => q{Ọnụ ọgụgụ Etọpịa},
 				'fullwide' => q{Ọnụ ọgụgụ ọbọsara},
 				'geor' => q{Ọnụ ọgụgụ Geọjịan},
 				'grek' => q{Ọnụ ọgụgụ Greek},
 				'greklow' => q{Ọbere ọnụ ọgụgụ Greek},
 				'gujr' => q{Ọnụ ọgụgụ Gụjaratị},
 				'guru' => q{Onụ ọgụgụ Gụmụkh},
 				'hanidec' => q{Ọnụ ọgụgụ ntụpọ Chịnese},
 				'hans' => q{Ọnụ ọgụgụ mfe Chịnese},
 				'hansfin' => q{Ọnụ ọgụgụ akantụ mfe nke Chinese},
 				'hant' => q{Ọnụ ọgụgụ ọdinala chinese},
 				'hantfin' => q{Ọnụ ọgụgụ akantụ ọdịnala Chinese},
 				'hebr' => q{Ọnụ ọgụgụ Hebrew},
 				'jpan' => q{Ọnụ ọgụgụ Japanese},
 				'jpanfin' => q{Ọnụ ọgụgụ akantụ Japanese},
 				'khmr' => q{Ọnụ ọgụgụ Khmer},
 				'knda' => q{Ọnụ ọgụgụ Kanada},
 				'laoo' => q{Ọnụ ọgụgụ Laọ},
 				'latn' => q{Ọnụ Ọgụgụ Mpaghara Ọdịda Anyanwụ},
 				'mlym' => q{Ọnụ ọgụgụ Malayala},
 				'mymr' => q{Ọnụ ọgụgụ Myamar},
 				'orya' => q{Ọnụ ọgụgụ Ọdịa},
 				'roman' => q{Ọnụ ọgụgụ Roman},
 				'romanlow' => q{Ọbere Ọnụ ọgụgụ Roman},
 				'taml' => q{Ọnụ ọgụgụ ọdịnala Tamịl},
 				'tamldec' => q{Ọnụ ọgụgụ Tamị},
 				'telu' => q{Ọnụ ọgụgụ Telụgụ},
 				'thai' => q{Ọnụ ọgụgụ Taị},
 				'tibt' => q{Ọnụ ọgụgụ Tịbeta},
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
			'metric' => q{Metriik},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Asụsụ: {0}',
 			'script' => 'Mkpụrụ Okwu: {0}',
 			'region' => 'Mpaghara: {0}',

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
			auxiliary => qr{[á à ā c é è ē í ì ī {ị́} {ị̀} ḿ {m̀} ń ǹ ó ò ō {ọ́} {ọ̀} q ú ù ū {ụ́} {ụ̀} x]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b {ch} d e ẹ f g {gb} {gh} {gw} h i ị j k {kp} {kw} l m n ṅ {nw} {ny} o ọ p r s {sh} t u ụ v w y z]},
			punctuation => qr{[\- ‑ , ; \: ! ? . ‘ ’ “ ” ( ) \[ \] \{ \}]},
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
					'duration-century' => {
						'name' => q(Ọtụtụ nari afọ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(Ọtụtụ nari afọ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Ọtụtụ Ubochi),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Ọtụtụ Ubochi),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(Ọtụtụ afọ iri),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(Ọtụtụ afọ iri),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Ọtụtụ Ọnwa),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Ọtụtụ Ọnwa),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Ọtụtụ Izu),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Ọtụtụ Izu),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Ọtụtụ Afọ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Ọtụtụ Afọ),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radius uwa),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radius uwa),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ngaji mégharia onu),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ngaji mégharia onu),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(mmiri dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(mmiri dram),
					},
				},
				'short' => {
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dobé),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dobé),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Eye|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Mba|M|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				middle => q({0}, {1}),
				end => q({0}, na {1}),
				2 => q({0}, {1}),
		} }
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
		'arab' => {
			'decimal' => q(٫),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(‏-),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪‏),
			'plusSign' => q(‏+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
		'arabext' => {
			'decimal' => q(٫),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(‎-‎),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‎+‎),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(٫),
		},
		'bali' => {
			'timeSeparator' => q(:),
		},
		'beng' => {
			'timeSeparator' => q(:),
		},
		'brah' => {
			'timeSeparator' => q(:),
		},
		'cakm' => {
			'timeSeparator' => q(:),
		},
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
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
		'arab' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤#,##0.00',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤#,##0.00)',
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
			display_name => {
				'currency' => q(Ego Dirham obodo United Arab Emirates),
				'other' => q(Ego dirhams obodo UAE),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Ego Afghani Obodo Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Ego Lek Obodo Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Ego Dram obodo Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Ego Antillean Guilder obodo Netherlands),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Ego Kwanza obodo Angola),
				'other' => q(Ego kwanzas obodo Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Ego Peso obodo Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Australia),
				'other' => q(Ego dollars obodo Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Ego Florin obodo Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Ego Manat obodo Azerbaijan),
				'other' => q(Ego manats obodo Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Akara mgbanwe ego obodo Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Ego Taka obodo Bangladesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Ego Lev mba Bulgaria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dollar Bermuda),
				'other' => q(Dollars Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Brunei),
				'other' => q(Ego dollars obodo Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Ego Boliviano obodo Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brazil),
				'other' => q(Real Brazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Ego Dollar Obodo Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ego Ngultrum obodo Bhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Ego Pula obodo Bostwana),
				'other' => q(Ego pulas obodo Bostwana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Ego Ruble mba Belarus),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dollar Belize),
				'other' => q(Dollars Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dollar Canada),
				'other' => q(Dollars Canada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Congo),
				'other' => q(Ego francs mba Congo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Ego Franc mba Switzerland),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Ego Peso obodo Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Ego Yuan Obodo China \(ndị bi na mmiri\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan China),
				'other' => q(Yuan China),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Ego Peso obodo Columbia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Ego Colón obodo Costa Rica),
				'other' => q(Ego colóns obodo Costa Rica),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Ego Peso e nwere ike ịgbanwe nke obodo Cuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Ego Peso obodo Cuba),
				'other' => q(Ego pesos obodo Cuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Caboverdiano),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Ego Koruna obodo Czech),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Djibouti),
				'other' => q(ego francs obodo Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Ego Krone Obodo Denmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Ego Peso Obodo Dominica),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Egypt),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Ego Nakfa obodo Eritrea),
				'other' => q(Ego nakfas obodo Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ego Birr obodo Ethiopia),
				'other' => q(Ego birrs obodo Ethiopia),
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
				'currency' => q(Ego Dollar obodo Fiji),
				'other' => q(Ego dollars obodo Fijian),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Falkland Islands),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pound British),
				'other' => q(Pound British),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Ego Lari Obodo Georgia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ego Cedi obodo Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Ego Dalasi obodo Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Guinea),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Ego Quetzal obodo Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Ego Dollar Obodo Honk Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Ego Lempira obodo Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Ego Kuna obodo Croatia),
				'other' => q(Ego kunas obodo Croatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Ego Gourde obodo Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ego Forint obodo Hungary),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Ego Rupiah Obodo Indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Ego Shekel ọhụrụ obodo Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupee India),
				'other' => q(Rupee India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Ego Dinar obodo Iraq),
				'other' => q(Ego dinars obodo Iraq),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Ego Rial obodo Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Ego Króna obodo Iceland),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Jamaica),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Jordan),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen Japan),
				'other' => q(Yen Japan),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Ego Shilling obodo Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Ego Som Obodo Kyrgyzstan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Ego Riel obodo Cambodia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Comoros),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Ego Won Obodo North Korea),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Ego Won Obodo South Korea),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Cayman Islands),
				'other' => q(Ego dollars obodo Cayman Islands),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Ego Tenge obodo Kazakhstani),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Ego Kip Obodo Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Lebanon),
				'other' => q(Ego Pound Obodo Lebanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(This is not a translation),
				'other' => q(This is not a translation),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Ego Dinar obodo Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Ego Dirham obodo Morocco),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Ego Leu obodo Moldova),
				'other' => q(Ego leu mba Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ego Ariary obodo Madagascar),
				'other' => q(Ego ariaries obodo Madagascar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Ego Denar Obodo Macedonia),
				'other' => q(Ego denari mba Macedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Ego Kyat obodo Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Ego Turgik Obodo Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Ego Pataca ndị Obodo Macanese),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ego Ouguiya Obodo Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Mauritania),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Ego Rufiyaa obodo Moldova),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Ego Kwacha obodo Malawi),
				'other' => q(Ego kwachas obodo Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Ego Peso obodo Mexico),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ego Ringgit obodo Malaysia),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Ego Metical obodo Mozambique),
				'other' => q(Ego meticals obodo Mozambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Namibia),
			},
		},
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(Naịra),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Ego Córodoba obodo Nicaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Ego Krone Obodo Norway),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo New Zealand),
				'other' => q(Ego dollars obodo New Zealand),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Ego Rial obodo Oman),
				'other' => q(Ego rials Obodo Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Ego Balboa obodo Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Ego Sol obodo Peru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Ego Kina obodo Papua New Guinea),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Ego piso obodo Philippine),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Ego Zloty mba Poland),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Ego Guarani obodo Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Ego Rial obodo Qatar),
				'other' => q(Ego rials obodo Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Ego Leu obodo Romania),
				'other' => q(Ego leu Obodo Romania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Ego Dinar obodo Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Ruble Russia),
				'other' => q(Ruble Russia),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Ego Riyal obodo Saudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Solomon Islands),
				'other' => q(Ego dollars obodo Solomon Islands),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Seychelles),
				'other' => q(Ego rupees obodo Seychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Ego Pound obodo Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Ego Krona Obodo Sweden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Ego Pound obodo St Helena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Ego Leone obodo Sierra Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Ego shilling obodo Somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dollar Surinamese),
				'other' => q(Dollar Surinamese),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Ego Pound obodo South Sudan),
				'other' => q(Ego pounds mba ọdịda anyanwụ Sudan),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Ego Dobra nke obodo Sāo Tomé na Principe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Syria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Ego Lilangeni obodo Swaziland),
				'other' => q(Ego emalangeni obodo Swaziland),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Ego Baht obodo Thai),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Who Somoni obodo Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Ego Manat Obodo Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Ego paʻanga obodo Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Ego Lira obodo Turkey),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dollar Trinidad & Tobago),
				'other' => q(Dollars Trinidad & Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dollar obodo New Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Ego Shilling Obodo Tanzania),
				'other' => q(Ego Shillings Obodo Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ego Hryvnia obodo Ukraine),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ego Shilling obodo Uganda),
				'other' => q(Ego shillings obodo Uganda),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dollar US),
				'other' => q(Dollars US),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Ego Peso obodo Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Ego Som obodo Uzbekistan),
				'other' => q(Ego som obodo Uzbekistan),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Ego Bolivar obodo Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Ego Dong obodo Vietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Ego Vatu obodo Vanuatu),
				'other' => q(Ego Vanuatu vatus obodo Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Ego Tala obodo Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Ego Franc mba etiti Africa),
				'other' => q(Ego francs mba etiti Africa),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo East Carribbean),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Ego CFA Franc obodo West Africa),
				'other' => q(Ego CFA francs mba ọdịda anyanwụ Afrịka),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Ego Franc obodo CFP),
				'other' => q(Ego francs obodo CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Ego Amaghị),
				'other' => q(\(ego amaghị\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Ego Rial obodo Yemeni),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Ego Rand obodo South Africa),
				'other' => q(Ego rand obodo South Africa),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Ego Kwacha Obodo Zambia),
				'other' => q(Ego kwachas obodo Zambia),
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
							'Jen',
							'Feb',
							'Maa',
							'Epr',
							'Mee',
							'Juu',
							'Jul',
							'Ọgọ',
							'Sep',
							'Ọkt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'E',
							'M',
							'J',
							'J',
							'Ọ',
							'S',
							'Ọ',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jenụwarị',
							'Febrụwarị',
							'Maachị',
							'Epreel',
							'Mee',
							'Juun',
							'Julaị',
							'Ọgọọst',
							'Septemba',
							'Ọktoba',
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
							'Jen',
							'Feb',
							'Maa',
							'Epr',
							'Mee',
							'Juu',
							'Jul',
							'Ọgọ',
							'Sep',
							'Ọkt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'E',
							'M',
							'J',
							'J',
							'Ọ',
							'S',
							'Ọ',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jenụwarị',
							'Febrụwarị',
							'Maachị',
							'Epreel',
							'Mee',
							'Juun',
							'Julaị',
							'Ọgọọst',
							'Septemba',
							'Ọktoba',
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
						mon => 'Mọn',
						tue => 'Tiu',
						wed => 'Wen',
						thu => 'Tọọ',
						fri => 'Fraị',
						sat => 'Sat',
						sun => 'Sọn'
					},
					short => {
						mon => 'Mọn',
						tue => 'Tiu',
						wed => 'Wen',
						thu => 'Tọọ',
						fri => 'Fraị',
						sat => 'Sat',
						sun => 'Sọn'
					},
					wide => {
						mon => 'Mọnde',
						tue => 'Tiuzdee',
						wed => 'Wenezdee',
						thu => 'Tọọzdee',
						fri => 'Fraịdee',
						sat => 'Satọdee',
						sun => 'Sọndee'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mọn',
						tue => 'Tiu',
						wed => 'Wen',
						thu => 'Tọọ',
						fri => 'Fraị',
						sat => 'Sat',
						sun => 'Sọn'
					},
					short => {
						mon => 'Mọn',
						tue => 'Tiu',
						wed => 'Wen',
						thu => 'Tọọ',
						fri => 'Fraị',
						sat => 'Sat',
						sun => 'Sọn'
					},
					wide => {
						mon => 'Mọnde',
						tue => 'Tiuzdee',
						wed => 'Wenezdee',
						thu => 'Tọọzdee',
						fri => 'Fraịdee',
						sat => 'Satọdee',
						sun => 'Sọndee'
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
					abbreviated => {0 => 'Ọ1',
						1 => 'Ọ2',
						2 => 'Ọ3',
						3 => 'Ọ4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Ọkara 1',
						1 => 'Ọkara 2',
						2 => 'Ọkara 3',
						3 => 'Ọkara 4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Ọ1',
						1 => 'Ọ2',
						2 => 'Ọ3',
						3 => 'Ọ4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Ọkara 1',
						1 => 'Ọkara 2',
						2 => 'Ọkara 3',
						3 => 'Ọkara 4'
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
					'am' => q{A.M.},
					'pm' => q{P.M.},
				},
				'narrow' => {
					'am' => q{A.M.},
					'pm' => q{P.M.},
				},
				'wide' => {
					'am' => q{N’ụtụtụ},
					'pm' => q{N’abali},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{A.M.},
					'pm' => q{P.M.},
				},
				'narrow' => {
					'am' => q{A.M.},
					'pm' => q{P.M.},
				},
				'wide' => {
					'am' => q{A.M.},
					'pm' => q{P.M.},
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
				'0' => 'T.K.',
				'1' => 'A.K.'
			},
			narrow => {
				'0' => 'T.K.',
				'1' => 'A.K.'
			},
			wide => {
				'0' => 'Tupu Kraist',
				'1' => 'Afọ Kraịst'
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
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
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
			'full' => q{{1} 'na' {0}},
			'long' => q{{1} 'na' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'na' {0}},
			'long' => q{{1} 'na' {0}},
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
			hm => q{h:mm a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			GyMMM => q{MMM G y},
			GyMMMEd => q{E, d MMM, G y},
			GyMMMd => q{d MMM, G y},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'Izu' W 'n'‘'ime' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'Izu' w 'n' 'ime' Y},
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
				d => q{E, MM/dd – E, MM/dd},
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
				M => q{MM/dd – MM/dd},
				d => q{MM/dd – MM/dd},
			},
			d => {
				d => q{d–d},
			},
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
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q(Oge {0}),
		regionFormat => q(Oge Ihe {0}),
		regionFormat => q(Oge Izugbe {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Oge Afghanistan#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Oge Etiti Afrịka#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oge Mpaghara Ọwụwa Anyanwụ Afrịka#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Oge Izugbe Mpaghara Mgbada Ugwu Afrịka#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọdịda Anyanwụ Afrịka#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Afrịka#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Afrịka#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Oge Ihe Alaska#,
				'generic' => q#Oge Alaska#,
				'standard' => q#Oge Izugbe Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Amazon#,
				'generic' => q#Oge Amazon#,
				'standard' => q#Oge Izugbe Amazon#,
			},
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Etiti#,
				'generic' => q#Oge Mpaghara Etiti#,
				'standard' => q#Oge Izugbe Mpaghara Etiti#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ọwụwa Anyanwụ#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ugwu#,
				'generic' => q#Oge Mpaghara Ugwu#,
				'standard' => q#Oge Izugbe Mpaghara Ugwu#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Pacific#,
				'generic' => q#Oge Mpaghara Pacific#,
				'standard' => q#Oge Izugbe Mpaghara Pacific#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Oge Ihe Apia#,
				'generic' => q#Oge Apia#,
				'standard' => q#Oge Izugbe Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Oge Ihe Arab#,
				'generic' => q#Oge Arab#,
				'standard' => q#Oge Izugbe Arab#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Argentina#,
				'generic' => q#Oge Argentina#,
				'standard' => q#Oge Izugbe Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọdịda Anyanwụ Argentina#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Argentina#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Armenia#,
				'generic' => q#Oge Armenia#,
				'standard' => q#Oge Izugbe Armenia#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Atlantic#,
				'generic' => q#Oge Mpaghara Atlantic#,
				'standard' => q#Oge Izugbe Mpaghara Atlantic#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Oge Ihe Etiti Australia#,
				'generic' => q#Oge Etiti Australia#,
				'standard' => q#Oge Izugbe Etiti Australia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ọdịda Anyanwụ Etiti Australia#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Etiti Australia#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Etiti Australia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ọwụwa Anyanwụ Australia#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ Australia#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ Australia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ọdịda Anyanwụ Australia#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Australia#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Australia#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Azerbaijan#,
				'generic' => q#Oge Azerbaijan#,
				'standard' => q#Oge Izugbe Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Azores#,
				'generic' => q#Oge Azores#,
				'standard' => q#Oge Izugbe Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Bangladesh#,
				'generic' => q#Oge Bangladesh#,
				'standard' => q#Oge Izugbe Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Oge Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Oge Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Brasilia#,
				'generic' => q#Oge Brasilia#,
				'standard' => q#Oge Izugbe Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Oge Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Cape Verde#,
				'generic' => q#Oge Cape Verde#,
				'standard' => q#Oge Izugbe Cape Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Oge Izugbe Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Oge Ihe Chatham#,
				'generic' => q#Oge Chatham#,
				'standard' => q#Oge Izugbe Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Chile#,
				'generic' => q#Oge Chile#,
				'standard' => q#Oge Izugbe Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Oge Ihe China#,
				'generic' => q#Oge China#,
				'standard' => q#Oge Izugbe China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Choibals#,
				'generic' => q#Oge Choibals#,
				'standard' => q#Oge Izugbe Choibals#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Oge Ekeresimesi Island#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Oge Cocos Islands#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Columbia#,
				'generic' => q#Oge Columbia#,
				'standard' => q#Oge Izugbe Columbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Oge Ọkara Okpomọkụ Cook Islands#,
				'generic' => q#Oge Cook Islands#,
				'standard' => q#Oge Izugbe Cook Islands#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Cuba#,
				'generic' => q#Oge Cuba#,
				'standard' => q#Oge Izugbe Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Oge Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Oge Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Oge Mpaghara Ọwụwa Anyanwụ Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọwụwa Anyanwụ Island#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ Island#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ Island#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Oge Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Nhazi Oge Ụwa Niile#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Obodo Amaghị#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Ireland#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Britain#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Etiti Europe#,
				'generic' => q#Oge Mpaghara Etiti Europe#,
				'standard' => q#Oge Izugbe Mpaghara Etiti Europe#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọwụwa Anyanwụ Europe#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ Europe#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ Europe#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Further-eastern European Time#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọdịda Anyanwụ Europe#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Europe#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Europe#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Falkland Islands#,
				'generic' => q#Oge Falkland Islands#,
				'standard' => q#Oge Izugbe Falkland Islands#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Fiji#,
				'generic' => q#Oge Fiji#,
				'standard' => q#Oge Izugbe Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Oge French Guiana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Oge French Southern & Antarctic#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Oge Mpaghara Greemwich Mean#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Oge Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Oge Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Georgia#,
				'generic' => q#Oge Georgia#,
				'standard' => q#Oge Izugbe Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Oge Gilbert Islands#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọwụwa Anyanwụ Greenland#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ Greenland#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọdịda Anyanwụ Greenland#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Greenland#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Greenland#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Oge Izugbe Gulf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Oge Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Oge Ihe Hawaii-Aleutian#,
				'generic' => q#Oge Hawaii-Aleutian#,
				'standard' => q#Oge Izugbe Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Hong Kong#,
				'generic' => q#Oge Hong Kong#,
				'standard' => q#Oge Izugbe Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Hovd#,
				'generic' => q#Oge Hovd#,
				'standard' => q#Oge Izugbe Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Oge Izugbe India#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Oge Osimiri India#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Oge Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Oge Etiti Indonesia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Oge Mpaghara Ọwụwa Anyanwụ Indonesia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Oge Mpaghara Ọdịda Anyanwụ Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Oge Ihe Iran#,
				'generic' => q#Oge Iran#,
				'standard' => q#Oge Izugbe Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Irkutsk#,
				'generic' => q#Oge Irkutsk#,
				'standard' => q#Oge Izugbe Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Oge Ihe Israel#,
				'generic' => q#Oge Israel#,
				'standard' => q#Oge Izugbe Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Oge Ihe Japan#,
				'generic' => q#Oge Japan#,
				'standard' => q#Oge Izugbe Japan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Oge Mpaghara Ọwụwa Anyanwụ Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Oge Mpaghara Ọdịda Anyanwụ Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Oge Ihe Korea#,
				'generic' => q#Oge Korea#,
				'standard' => q#Oge Izugbe Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Oge Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Krasnoyarsk#,
				'generic' => q#Oge Krasnoyarsk#,
				'standard' => q#Oge Izugbe Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Oge Kyrgyzstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Oge Line Islands#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Oge Ihe Lord Howe#,
				'generic' => q#Oge Lord Howe#,
				'standard' => q#Oge Izugbe Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Oge Macquarie Island#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Magadan#,
				'generic' => q#Oge Magadan#,
				'standard' => q#Oge Izugbe Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Oge Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Oge Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Oge Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Oge Marshall Islands#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mauritius#,
				'generic' => q#Oge Mauritius#,
				'standard' => q#Oge Izugbe Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Oge Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Oge Ihe Northwest Mexico#,
				'generic' => q#Oge Northwest Mexico#,
				'standard' => q#Oge Izugbe Northwest Mexico#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Oge Ihe Mexican Pacific#,
				'generic' => q#Oge Mexican Pacific#,
				'standard' => q#Oge Izugbe Mexican Pacific#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Ulaanbaatar#,
				'generic' => q#Oge Ulaanbaatar#,
				'standard' => q#Oge Izugbe Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Moscow#,
				'generic' => q#Oge Moscow#,
				'standard' => q#Oge Izugbe Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Oge Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Oge Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Oge Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ New Caledonia#,
				'generic' => q#Oge New Caledonia#,
				'standard' => q#Oge Izugbe New Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Oge Ihe New Zealand#,
				'generic' => q#Oge New Zealand#,
				'standard' => q#Oge Izugbe New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Oge Ihe Newfoundland#,
				'generic' => q#Oge Newfoundland#,
				'standard' => q#Oge Izugbe Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Oge Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Norfolk Island#,
				'generic' => q#Oge Norfolk Island#,
				'standard' => q#Oge Izugbe Norfolk Island#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Fernando de Noronha#,
				'generic' => q#Oge Fernando de Noronha#,
				'standard' => q#Oge Izugbe Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Novosibirsk#,
				'generic' => q#Oge Novosibirsk#,
				'standard' => q#Oge Izugbe Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Omsk#,
				'generic' => q#Oge Omsk#,
				'standard' => q#Oge Izugbe Omsk#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Pakistan#,
				'generic' => q#Oge Pakistan#,
				'standard' => q#Oge Izugbe Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Oge Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Oge Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Paraguay#,
				'generic' => q#Oge Paraguay#,
				'standard' => q#Oge Izugbe Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Peru#,
				'generic' => q#Oge Peru#,
				'standard' => q#Oge Izugbe Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Philippine#,
				'generic' => q#Oge Philippine#,
				'standard' => q#Oge Izugbe Philippine#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Oge Phoenix Islands#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Oge Ihe St. Pierre & Miquelon#,
				'generic' => q#Oge St. Pierre & Miquelon#,
				'standard' => q#Oge Izugbe St. Pierre & Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Oge Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Oge Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Oge Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Oge Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Oge Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Sakhalin#,
				'generic' => q#Oge Sakhalin#,
				'standard' => q#Oge Izugbe Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Oge Ihe Samoa#,
				'generic' => q#Oge Samoa#,
				'standard' => q#Oge Izugbe Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Oge Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Oge Izugbe Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Oge Solomon Islands#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Oge South Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Oge Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Oge Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Oge Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Oge Ihe Taipei#,
				'generic' => q#Oge Taipei#,
				'standard' => q#Oge Izugbe Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Oge Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Oge Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Tonga#,
				'generic' => q#Oge Tonga#,
				'standard' => q#Oge Izugbe Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Oge Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Turkmenist#,
				'generic' => q#Oge Turkmenist#,
				'standard' => q#Oge Izugbe Turkmenist#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Oge Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Uruguay#,
				'generic' => q#Oge Uruguay#,
				'standard' => q#Oge Izugbe Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Uzbekist#,
				'generic' => q#Oge Uzbekist#,
				'standard' => q#Oge Izugbe Uzbekist#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Vanuatu#,
				'generic' => q#Oge Vanuatu#,
				'standard' => q#Oge Izugbe Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Oge Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Vladivostok#,
				'generic' => q#Oge Vladivostok#,
				'standard' => q#Oge Izugbe Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Volgograd#,
				'generic' => q#Oge Volgograd#,
				'standard' => q#Oge Izugbe Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Oge Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Oge Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Oge Wallis & Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Yakutsk#,
				'generic' => q#Oge Yakutsk#,
				'standard' => q#Oge Izugbe Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Yekaterinburg#,
				'generic' => q#Oge Yekaterinburg#,
				'standard' => q#Oge Izugbe Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Oge Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
