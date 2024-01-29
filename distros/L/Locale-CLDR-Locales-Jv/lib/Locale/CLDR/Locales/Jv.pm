=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Jv - Package for language Javanese

=cut

package Locale::CLDR::Locales::Jv;
# This file auto generated from Data\common\main\jv.xml
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
				'af' => 'Afrika',
 				'agq' => 'Aghem',
 				'ak' => 'Akan',
 				'am' => 'Amharik',
 				'ar' => 'Arab',
 				'ar_001' => 'Arab Standar Anyar',
 				'as' => 'Assam',
 				'asa' => 'Asu',
 				'ast' => 'Asturia',
 				'az' => 'Azerbaijan',
 				'az@alt=short' => 'Azeri',
 				'bas' => 'Basaa',
 				'be' => 'Belarus',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgaria',
 				'bm' => 'Bambara',
 				'bn' => 'Bengali',
 				'bo' => 'Tibet',
 				'br' => 'Breton',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnia lan Hercegovina',
 				'ca' => 'Katala',
 				'ccp' => 'Chakma',
 				'ce' => 'Chechen',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'chr' => 'Cherokee',
 				'ckb' => 'Kurdi Tengah',
 				'co' => 'Korsika',
 				'cs' => 'Ceska',
 				'cu' => 'Slavia Gerejani',
 				'cy' => 'Welsh',
 				'da' => 'Dansk',
 				'dav' => 'Taita',
 				'de' => 'Jérman',
 				'de_AT' => 'Jérman Ostenrik',
 				'de_CH' => 'Jérman Switserlan',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Sorbia Non Standar',
 				'dua' => 'Duala',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dzongkha',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'el' => 'Yunani',
 				'en' => 'Inggris',
 				'en_AU' => 'Inggris Ostrali',
 				'en_CA' => 'Inggris Kanada',
 				'en_GB' => 'Inggris Karajan Manunggal',
 				'en_GB@alt=short' => 'Inggris (Britania)',
 				'en_US' => 'Inggris Amérika Sarékat',
 				'eo' => 'Esperanto',
 				'es' => 'Spanyol',
 				'es_419' => 'Spanyol (Amerika Latin)',
 				'es_ES' => 'Spanyol (Eropah)',
 				'es_MX' => 'Spanyol (Meksiko)',
 				'et' => 'Estonia',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persia',
 				'ff' => 'Fulah',
 				'fi' => 'Suomi',
 				'fil' => 'Tagalog',
 				'fo' => 'Faroe',
 				'fr' => 'Prancis',
 				'fr_CA' => 'Prancis Kanada',
 				'fr_CH' => 'Prancis Switserlan',
 				'fur' => 'Friulian',
 				'fy' => 'Frisia Sisih Kulon',
 				'ga' => 'Irlandia',
 				'gd' => 'Gaulia',
 				'gl' => 'Galisia',
 				'gsw' => 'Jerman Swiss',
 				'gu' => 'Gujarat',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'ha' => 'Hausa',
 				'haw' => 'Hawaii',
 				'he' => 'Ibrani',
 				'hi' => 'India',
 				'hmn' => 'Hmong',
 				'hr' => 'Kroasia',
 				'hsb' => 'Sorbia Standar',
 				'ht' => 'Kreol Haiti',
 				'hu' => 'Hungaria',
 				'hy' => 'Armenia',
 				'ia' => 'Interlingua',
 				'id' => 'Indonesia',
 				'ig' => 'Iqbo',
 				'ii' => 'Sichuan Yi',
 				'is' => 'Islandia',
 				'it' => 'Italia',
 				'ja' => 'Jepang',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jv' => 'Jawa',
 				'ka' => 'Georgia',
 				'kab' => 'Kabyle',
 				'kam' => 'Kamba',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'khq' => 'Koyra Chiini',
 				'ki' => 'Kikuyu',
 				'kk' => 'Kazakh',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kn' => 'Kannada',
 				'ko' => 'Korea',
 				'kok' => 'Konkani',
 				'ks' => 'Kashmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Colonia',
 				'ku' => 'Kurdis',
 				'kw' => 'Kernowek',
 				'ky' => 'Kirgis',
 				'la' => 'Latin',
 				'lag' => 'Langi',
 				'lb' => 'Luksemburg',
 				'lg' => 'Ganda',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingala',
 				'lo' => 'Laos',
 				'lrc' => 'Luri Sisih Lor',
 				'lt' => 'Lithuania',
 				'lu' => 'Luba-Katanga',
 				'luo' => 'Luo',
 				'luy' => 'Luyia',
 				'lv' => 'Latvia',
 				'mai' => 'Maithili',
 				'mas' => 'Masai',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasi',
 				'mgh' => 'Makhuwa-Meeto',
 				'mgo' => 'Meta’',
 				'mi' => 'Maori',
 				'mk' => 'Makedonia',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolia',
 				'mni' => 'Manipuri',
 				'mr' => 'Marathi',
 				'ms' => 'Melayu',
 				'mt' => 'Malta',
 				'mua' => 'Mundang',
 				'mul' => 'Basa Multilingua',
 				'my' => 'Myanmar',
 				'mzn' => 'Mazanderani',
 				'naq' => 'Nama',
 				'nb' => 'Bokmål Norwegia',
 				'nd' => 'Ndebele Lor',
 				'nds' => 'Jerman Non Standar',
 				'ne' => 'Nepal',
 				'nl' => 'Walanda',
 				'nl_BE' => 'Flemis',
 				'nmg' => 'Kwasio',
 				'nn' => 'Nynorsk Norwegia',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norwegia',
 				'nus' => 'Nuer',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyankole',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossetia',
 				'pa' => 'Punjab',
 				'pcm' => 'Nigeria Pidgin',
 				'pl' => 'Polandia',
 				'prg' => 'Prusia',
 				'ps' => 'Pashto',
 				'pt' => 'Portugis',
 				'pt_BR' => 'Portugis Brasil',
 				'pt_PT' => 'Portugis Portugal',
 				'qu' => 'Quechua',
 				'rhg' => 'Rohingya',
 				'rm' => 'Roman',
 				'rn' => 'Rundi',
 				'ro' => 'Rumania',
 				'rof' => 'Rombo',
 				'ru' => 'Rusia',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskerta',
 				'sah' => 'Sakha',
 				'saq' => 'Samburu',
 				'sat' => 'Santali',
 				'sbp' => 'Sangu',
 				'sd' => 'Sindhi',
 				'se' => 'Sami Sisih Lor',
 				'seh' => 'Sena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'shi' => 'Tachelhit',
 				'si' => 'Sinhala',
 				'sk' => 'Slowakia',
 				'sl' => 'Slovenia',
 				'sm' => 'Samoa',
 				'smn' => 'Inari Sami',
 				'sn' => 'Shona',
 				'so' => 'Somalia',
 				'sq' => 'Albania',
 				'sr' => 'Serbia',
 				'st' => 'Sotho Sisih Kidul',
 				'su' => 'Sunda',
 				'sv' => 'Swedia',
 				'sw' => 'Swahili',
 				'ta' => 'Tamil',
 				'te' => 'Telugu',
 				'teo' => 'Teso',
 				'tg' => 'Tajik',
 				'th' => 'Thailand',
 				'ti' => 'Tigrinya',
 				'tk' => 'Turkmen',
 				'to' => 'Tonga',
 				'tr' => 'Turki',
 				'tt' => 'Tatar',
 				'twq' => 'Tasawaq',
 				'tzm' => 'Tamazight Atlas Tengah',
 				'ug' => 'Uighur',
 				'uk' => 'Ukraina',
 				'und' => 'Basa Ora Dikenali',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbek',
 				'vai' => 'Vai',
 				'vi' => 'Vietnam',
 				'vo' => 'Volapuk',
 				'vun' => 'Vunjo',
 				'wae' => 'Walser',
 				'wo' => 'Wolof',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yue' => 'Kanton',
 				'yue@alt=menu' => 'Tyonghwa, Kanton',
 				'zgh' => 'Tamazight Moroko Standar',
 				'zh' => 'Tyonghwa',
 				'zh@alt=menu' => 'Tyonghwa, Mandarin',
 				'zh_Hans' => 'Tyonghwa (Ringkes)',
 				'zh_Hans@alt=long' => 'Tyonghwa Mandarin (Ringkes)',
 				'zh_Hant' => 'Tyonghwa (Tradisional)',
 				'zh_Hant@alt=long' => 'Tyonghwa Mandarin (Tradisional)',
 				'zu' => 'Zulu',
 				'zxx' => 'Konten tanpa linguistik',

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
			'Arab' => 'hija’iyah',
 			'Armn' => 'Armenia',
 			'Beng' => 'Bangla',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Cyrl' => 'Sirilik',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Ethiopik',
 			'Geor' => 'Georgia',
 			'Grek' => 'Yunani',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han nganggo Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Prasaja',
 			'Hans@alt=stand-alone' => 'Han Prasaja',
 			'Hant' => 'Tradhisional',
 			'Hant@alt=stand-alone' => 'Han Tradhisional',
 			'Hebr' => 'Ibrani',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Silabaris Jepang',
 			'Jpan' => 'Jepang',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korea',
 			'Laoo' => 'Lao',
 			'Latn' => 'Latin',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongolia',
 			'Mymr' => 'Myanmar',
 			'Orya' => 'Odia',
 			'Sinh' => 'Sinhala',
 			'Taml' => 'Tamil',
 			'Telu' => 'Telugu',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thailand',
 			'Tibt' => 'Tibetan',
 			'Zmth' => 'Notasi Matematika',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Simbol',
 			'Zxxx' => 'Ora Ketulis',
 			'Zyyy' => 'Umum',
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
 			'003' => 'Amérika Lor',
 			'005' => 'Amérika Kidul',
 			'009' => 'Oséania',
 			'011' => 'Afrika Kulon',
 			'013' => 'Amérika Tengah',
 			'014' => 'Afrika Wétan',
 			'015' => 'Afrika Lor',
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
 			'154' => 'Éropah Lor',
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
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadélup',
 			'GQ' => 'Guinéa Katulistiwa',
 			'GR' => 'Grikenlan',
 			'GS' => 'Georgia Kidul lan Kapuloan Sandwich Kidul',
 			'GT' => 'Guatémala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
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
 			'IN' => 'Indhia',
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
 			'KP' => 'Korea Lor',
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
 			'MK' => 'Républik Makédonia Lor',
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
 			'NZ' => 'Selandia Anyar',
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
 			'SZ@alt=variant' => '(Swasiland)',
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
 			'UM' => 'Kapuloan AS Paling Njaba',
 			'UN' => 'Pasarékatan Bangsa-Bangsa',
 			'US' => 'Amérika Sarékat',
 			'US@alt=short' => 'AS',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbèkistan',
 			'VA' => 'Kutha Vatikan',
 			'VC' => 'Saint Vinsen lan Grénadin',
 			'VE' => 'Vénésuéla',
 			'VG' => 'Kapuloan Virgin Britania',
 			'VI' => 'Kapuloan Virgin Amérika',
 			'VN' => 'Viètnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis lan Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Logat Semu',
 			'XB' => 'Rong Arah Semu',
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

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Tanggalan',
 			'cf' => 'Format Mata Uang',
 			'collation' => 'Urutan Pamilahan',
 			'currency' => 'Mata Uang',
 			'hc' => 'Siklus Jam (12 vs 24)',
 			'lb' => 'Gaya Ganti Baris',
 			'ms' => 'Sistem Pangukuran',
 			'numbers' => 'Angka',

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
 				'buddhist' => q{Tanggalan Buddha},
 				'chinese' => q{Tanggalan Cina},
 				'dangi' => q{Tanggalan Dangi},
 				'ethiopic' => q{Tanggalan Etiopia},
 				'gregorian' => q{Tanggalan Gregorian},
 				'hebrew' => q{Tanggalan Ibrani},
 				'islamic' => q{Tanggalan Islam},
 				'iso8601' => q{Tanggalan ISO-8601},
 				'japanese' => q{Tanggalan Jepang},
 				'persian' => q{Tanggalan Persia},
 				'roc' => q{Tanggalan Minguo},
 			},
 			'cf' => {
 				'account' => q{Format Mata Uang Akuntansi},
 				'standard' => q{Format Mata Uang Standar},
 			},
 			'collation' => {
 				'ducet' => q{Urutan Pamilahan Unicode Default},
 				'search' => q{Panlusuran Tujuan Umum},
 				'standard' => q{Standar Ngurutke Urutan},
 			},
 			'hc' => {
 				'h11' => q{Sistem 12 Jam (0–11)},
 				'h12' => q{Sistem 12 Jam (1–12)},
 				'h23' => q{Sistem 24 Jam (0–23)},
 				'h24' => q{Sistem 24 Jam (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Gaya Ganti Baris Longgar},
 				'normal' => q{Gaya Ganti Baris Normal},
 				'strict' => q{Gaya Ganti Baris Strik},
 			},
 			'ms' => {
 				'metric' => q{Sistem Metrik},
 				'uksystem' => q{Sistem Pangukuran Imperial},
 				'ussystem' => q{Sistem Pangukuran AS},
 			},
 			'numbers' => {
 				'arab' => q{Digit Hindu-Arab},
 				'arabext' => q{Digit Hindu-Arab Diambakake},
 				'armn' => q{Angka Armenia},
 				'armnlow' => q{Angka Huruf Cilik Armenia},
 				'beng' => q{Digit Bengali},
 				'deva' => q{Digit Devanagari},
 				'ethi' => q{Angka Etiopia},
 				'fullwide' => q{Digit Amba Kebak},
 				'geor' => q{Angka Georgian},
 				'grek' => q{Angka Yunani},
 				'greklow' => q{Angka Huruf Cilik Yunani},
 				'gujr' => q{Digit Gujarat},
 				'guru' => q{Digit Gurmukhi},
 				'hanidec' => q{Angka Desimal Mandarin},
 				'hans' => q{Angka Mandarin Ringkes},
 				'hansfin' => q{Angka Finansial Mandarin Ringkes},
 				'hant' => q{Angka Mandarin Tradisional},
 				'hantfin' => q{Angka Finansial Mandarin Tradisional},
 				'hebr' => q{Angka Ibrani},
 				'jpan' => q{Angka Jepang},
 				'jpanfin' => q{Angka Finansial Jepang},
 				'khmr' => q{Digit Khmer},
 				'knda' => q{Digit Kannada},
 				'laoo' => q{Digit Lao},
 				'latn' => q{Digit Latin},
 				'mlym' => q{Digit Malayalam},
 				'mymr' => q{Digit Myanmar},
 				'orya' => q{Digit Odia},
 				'roman' => q{Angka Romawi},
 				'romanlow' => q{Angka Huruf Cilik Romawi},
 				'taml' => q{Angka Tamil Tradisional},
 				'tamldec' => q{Digit Tamil},
 				'telu' => q{Digit Telugu},
 				'thai' => q{Digit Thailand},
 				'tibt' => q{Digit Tibet},
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
					# Long Unit Identifier
					'' => {
						'name' => q(arah kardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah kardinal),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(desi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(desi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(senti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(senti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(tenaga-g),
						'other' => q({0} tenaga-g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(tenaga-g),
						'other' => q({0} tenaga-g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter saben detik kuadrat),
						'other' => q({0} meter saben detik kuadrat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter saben detik kuadrat),
						'other' => q({0} meter saben detik kuadrat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(menit saka busur),
						'other' => q({0} menit saka busur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(menit saka busur),
						'other' => q({0} menit saka busur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(detik saka busur),
						'other' => q({0} detik saka busur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(detik saka busur),
						'other' => q({0} detik saka busur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(derajat),
						'other' => q({0} derajat),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(derajat),
						'other' => q({0} derajat),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(revolusi),
						'other' => q({0} revolusi),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(revolusi),
						'other' => q({0} revolusi),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(are),
						'other' => q({0} are),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(are),
						'other' => q({0} are),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
						'other' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
						'other' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sentimeter pesagi),
						'other' => q({0} sentimeter pesagi),
						'per' => q({0} saben sentimeter pesagi),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sentimeter pesagi),
						'other' => q({0} sentimeter pesagi),
						'per' => q({0} saben sentimeter pesagi),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kaki pesagi),
						'other' => q({0} kaki pesagi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kaki pesagi),
						'other' => q({0} kaki pesagi),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci pesagi),
						'other' => q({0} inci pesagi),
						'per' => q({0} saben inci pesagi),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci pesagi),
						'other' => q({0} inci pesagi),
						'per' => q({0} saben inci pesagi),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometer pesagi),
						'other' => q({0} kilometer pesagi),
						'per' => q({0} saben kilometer pesagi),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometer pesagi),
						'other' => q({0} kilometer pesagi),
						'per' => q({0} saben kilometer pesagi),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(meter pesagi),
						'other' => q({0} meter pesagi),
						'per' => q({0} saben meter pesagi),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meter pesagi),
						'other' => q({0} meter pesagi),
						'per' => q({0} saben meter pesagi),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mil pesagi),
						'other' => q({0} mil pesagi),
						'per' => q({0} saben mil pesagi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mil pesagi),
						'other' => q({0} mil pesagi),
						'per' => q({0} saben mil pesagi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard pesagi),
						'other' => q({0} yard pesagi),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard pesagi),
						'other' => q({0} yard pesagi),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(iji),
						'other' => q({0} iji),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(iji),
						'other' => q({0} iji),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram saben desiliter),
						'other' => q({0} miligram saben desiliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram saben desiliter),
						'other' => q({0} miligram saben desiliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol saben liter),
						'other' => q({0} milimol saben liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol saben liter),
						'other' => q({0} milimol saben liter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(persen),
						'other' => q({0} persen),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(persen),
						'other' => q({0} persen),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permil),
						'other' => q({0} permil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permil),
						'other' => q({0} permil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bagean saben yuta),
						'other' => q({0} bagean saben yuta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bagean saben yuta),
						'other' => q({0} bagean saben yuta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permiriad),
						'other' => q({0} permiriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permiriad),
						'other' => q({0} permiriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(liter saben 100 kilometer),
						'other' => q({0} liter saben 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(liter saben 100 kilometer),
						'other' => q({0} liter saben 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter saben kilometer),
						'other' => q({0} liter saben kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter saben kilometer),
						'other' => q({0} liter saben kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil saben galon),
						'other' => q({0} mil saben galon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil saben galon),
						'other' => q({0} mil saben galon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil saben galon inggris),
						'other' => q({0} mil saben galon inggris),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil saben galon inggris),
						'other' => q({0} mil saben galon inggris),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bite),
						'other' => q({0} bite),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bite),
						'other' => q({0} bite),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabite),
						'other' => q({0} gigabite),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabite),
						'other' => q({0} gigabite),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobite),
						'other' => q({0} kilobite),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobite),
						'other' => q({0} kilobite),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabite),
						'other' => q({0} megabite),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabite),
						'other' => q({0} megabite),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabite),
						'other' => q({0} petabite),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabite),
						'other' => q({0} petabite),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabite),
						'other' => q({0} terabite),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabite),
						'other' => q({0} terabite),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dina),
						'other' => q({0} dina),
						'per' => q({0} saben dina),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dina),
						'other' => q({0} dina),
						'per' => q({0} saben dina),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dasawarsa),
						'other' => q({0} dasawarsa),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dasawarsa),
						'other' => q({0} dasawarsa),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0} saben jam),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0} saben jam),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrodetik),
						'other' => q({0} mikrodetik),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrodetik),
						'other' => q({0} mikrodetik),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milidetik),
						'other' => q({0} milidetik),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milidetik),
						'other' => q({0} milidetik),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} saben menit),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} saben menit),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
						'per' => q({0} saben sasi),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
						'per' => q({0} saben sasi),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanodetik),
						'other' => q({0} nanodetik),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanodetik),
						'other' => q({0} nanodetik),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(detik),
						'other' => q({0} detik),
						'per' => q({0} saben detik),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(detik),
						'other' => q({0} detik),
						'per' => q({0} saben detik),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(peken),
						'other' => q({0} peken),
						'per' => q({0} saben peken),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(peken),
						'other' => q({0} peken),
						'per' => q({0} saben peken),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(taun),
						'other' => q({0} taun),
						'per' => q({0} saben taun),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(taun),
						'other' => q({0} taun),
						'per' => q({0} saben taun),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamper),
						'other' => q({0} miliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamper),
						'other' => q({0} miliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(takeran panas Britania),
						'other' => q({0} takeran panas Britania),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(takeran panas Britania),
						'other' => q({0} takeran panas Britania),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(jol),
						'other' => q({0} jol),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(jol),
						'other' => q({0} jol),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojol),
						'other' => q({0} kilojol),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojol),
						'other' => q({0} kilojol),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt-jam),
						'other' => q({0} kilowatt-jam),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-jam),
						'other' => q({0} kilowatt-jam),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(takeran panas AS),
						'other' => q({0} takeran panas AS),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(takeran panas AS),
						'other' => q({0} takeran panas AS),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-jam saben 100 kilometer),
						'other' => q({0} kilowatt-jam saben 100 kilometer),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-jam saben 100 kilometer),
						'other' => q({0} kilowatt-jam saben 100 kilometer),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pon gaya),
						'other' => q({0} pon gaya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pon gaya),
						'other' => q({0} pon gaya),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahet),
						'other' => q({0} gigahet),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahet),
						'other' => q({0} gigahet),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(het),
						'other' => q({0} het),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(het),
						'other' => q({0} het),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohet),
						'other' => q({0} kilohet),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohet),
						'other' => q({0} kilohet),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahet),
						'other' => q({0} megahet),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahet),
						'other' => q({0} megahet),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(titik),
						'other' => q({0} titik),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(titik),
						'other' => q({0} titik),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(titek saben sentimeter),
						'other' => q({0} titek saben sentimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(titek saben sentimeter),
						'other' => q({0} titek saben sentimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(titek saben inci),
						'other' => q({0} titek saben inci),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(titek saben inci),
						'other' => q({0} titek saben inci),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipografi em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipografi em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapiksel),
						'other' => q({0} megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksel),
						'other' => q({0} megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unit astronomi),
						'other' => q({0} unit astronomi),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unit astronomi),
						'other' => q({0} unit astronomi),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} saben sentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} saben sentimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimeter),
						'other' => q({0} desimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimeter),
						'other' => q({0} desimeter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radius donya),
						'other' => q({0} radius donya),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radius donya),
						'other' => q({0} radius donya),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathoms),
						'other' => q({0} fathoms),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathoms),
						'other' => q({0} fathoms),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0} saben kaki),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0} saben kaki),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inci),
						'other' => q({0} inci),
						'per' => q({0} saben inci),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inci),
						'other' => q({0} inci),
						'per' => q({0} saben inci),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} saben kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} saben kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(taun cahya),
						'other' => q({0} taun cahya),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(taun cahya),
						'other' => q({0} taun cahya),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meter),
						'other' => q({0} meter),
						'per' => q({0} saben meter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meter),
						'other' => q({0} meter),
						'per' => q({0} saben meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometer),
						'other' => q({0} mikrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometer),
						'other' => q({0} mikrometer),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mil-skandinavia),
						'other' => q({0} mil-skandinavia),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mil-skandinavia),
						'other' => q({0} mil-skandinavia),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimeter),
						'other' => q({0} milimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimeter),
						'other' => q({0} milimeter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometer),
						'other' => q({0} nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometer),
						'other' => q({0} nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mil segoro),
						'other' => q({0} mil segoro),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mil segoro),
						'other' => q({0} mil segoro),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(poin),
						'other' => q({0} poin),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(poin),
						'other' => q({0} poin),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radii srengenge),
						'other' => q({0} radii srengenge),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radii srengenge),
						'other' => q({0} radii srengenge),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luk),
						'other' => q({0} luk),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luk),
						'other' => q({0} luk),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminositas srengenge),
						'other' => q({0} luminositas srengenge),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminositas srengenge),
						'other' => q({0} luminositas srengenge),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(massa Bumi),
						'other' => q({0} massa Bumi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(massa Bumi),
						'other' => q({0} massa Bumi),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(wiji),
						'other' => q({0} wiji),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(wiji),
						'other' => q({0} wiji),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gram),
						'other' => q({0} gram),
						'per' => q({0} saben gram),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gram),
						'other' => q({0} gram),
						'per' => q({0} saben gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} saben kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} saben kilogram),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0} saben ons),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0} saben ons),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0} saben pon),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0} saben pon),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(massa srengenge),
						'other' => q({0} massa srengenge),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(massa srengenge),
						'other' => q({0} massa srengenge),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(watu),
						'other' => q({0} watu),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(watu),
						'other' => q({0} watu),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} saben {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} saben {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(tenogo jaran),
						'other' => q({0} tenogo jaran),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(tenogo jaran),
						'other' => q({0} tenogo jaran),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt),
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(peng loro {0}),
						'other' => q(pesagi {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(peng loro {0}),
						'other' => q(pesagi {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(peng telu {0}),
						'other' => q(kubik {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(peng telu {0}),
						'other' => q(kubik {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfer),
						'other' => q({0} atmosfer),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfer),
						'other' => q({0} atmosfer),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inci saka raksa),
						'other' => q({0} inci saka raksa),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inci saka raksa),
						'other' => q({0} inci saka raksa),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskal),
						'other' => q({0} megapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskal),
						'other' => q({0} megapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimeter saka raksa),
						'other' => q({0} milimeter saka raksa),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimeter saka raksa),
						'other' => q({0} milimeter saka raksa),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskal),
						'other' => q({0} paskal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskal),
						'other' => q({0} paskal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pon saben inci kuadrat),
						'other' => q({0} pon saben inci kuadrat),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pon saben inci kuadrat),
						'other' => q({0} pon saben inci kuadrat),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometer saben jam),
						'other' => q({0} kilometer saben jam),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometer saben jam),
						'other' => q({0} kilometer saben jam),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter saben detik),
						'other' => q({0} meter saben detik),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter saben detik),
						'other' => q({0} meter saben detik),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil saben jam),
						'other' => q({0} mil saben jam),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil saben jam),
						'other' => q({0} mil saben jam),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(derajat celsius),
						'other' => q({0} derajat celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(derajat celsius),
						'other' => q({0} derajat celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(derajat Fahrenhet),
						'other' => q({0} derajat Fahrenhet),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(derajat Fahrenhet),
						'other' => q({0} derajat Fahrenhet),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton-meter),
						'other' => q({0} newton-meter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-meter),
						'other' => q({0} newton-meter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pon-kaki),
						'other' => q({0} pon-kaki),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pon-kaki),
						'other' => q({0} pon-kaki),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(are-kaki),
						'other' => q({0} are-kaki),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(are-kaki),
						'other' => q({0} are-kaki),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barel),
						'other' => q({0} barel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barel),
						'other' => q({0} barel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(gantang),
						'other' => q({0} gantang),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(gantang),
						'other' => q({0} gantang),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sentimeter kubik),
						'other' => q({0} sentimeter kubik),
						'per' => q({0} saben sentimeter kubik),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sentimeter kubik),
						'other' => q({0} sentimeter kubik),
						'per' => q({0} saben sentimeter kubik),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kaki kubik),
						'other' => q({0} kaki kubik),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kaki kubik),
						'other' => q({0} kaki kubik),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci kubik),
						'other' => q({0} inci kubik),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci kubik),
						'other' => q({0} inci kubik),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilometer kubik),
						'other' => q({0} kilometer kubik),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilometer kubik),
						'other' => q({0} kilometer kubik),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(meter kubik),
						'other' => q({0} meter kubik),
						'per' => q({0} saben meter kubik),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(meter kubik),
						'other' => q({0} meter kubik),
						'per' => q({0} saben meter kubik),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil kubik),
						'other' => q({0} mil kubik),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil kubik),
						'other' => q({0} mil kubik),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard kubik),
						'other' => q({0} yard kubik),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard kubik),
						'other' => q({0} yard kubik),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kup),
						'other' => q({0} kup),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kup),
						'other' => q({0} kup),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrik kup),
						'other' => q({0} metrik kup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrik kup),
						'other' => q({0} metrik kup),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desiliter),
						'other' => q({0} desiliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desiliter),
						'other' => q({0} desiliter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(sendok es),
						'other' => q({0} sendok es),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(sendok es),
						'other' => q({0} sendok es),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. sendok es),
						'other' => q({0} Imp. sendok es),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. sendok es),
						'other' => q({0} Imp. sendok es),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(banyu dram),
						'other' => q({0} banyu dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(banyu dram),
						'other' => q({0} banyu dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tetes),
						'other' => q({0} tetes),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tetes),
						'other' => q({0} tetes),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ons banyu),
						'other' => q({0} ons banyu),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ons banyu),
						'other' => q({0} ons banyu),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. ons banyu),
						'other' => q({0} Imp. ons banyu),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. ons banyu),
						'other' => q({0} Imp. ons banyu),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0} saben galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0} saben galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galon inggris),
						'other' => q({0} galon inggris),
						'per' => q({0} saben galon inggris),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galon inggris),
						'other' => q({0} galon inggris),
						'per' => q({0} saben galon inggris),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektoliter),
						'other' => q({0} hektoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektoliter),
						'other' => q({0} hektoliter),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liter),
						'other' => q({0} liter),
						'per' => q({0} saben liter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liter),
						'other' => q({0} liter),
						'per' => q({0} saben liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliter),
						'other' => q({0} megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliter),
						'other' => q({0} megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililiter),
						'other' => q({0} mililiter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililiter),
						'other' => q({0} mililiter),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(sak juwit),
						'other' => q({0} sak juwit),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(sak juwit),
						'other' => q({0} sak juwit),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pin),
						'other' => q({0} pin),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pin),
						'other' => q({0} pin),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrik pin),
						'other' => q({0} metrik pin),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrik pin),
						'other' => q({0} metrik pin),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(seprapat galon),
						'other' => q({0} seprapat galon),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(seprapat galon),
						'other' => q({0} seprapat galon),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. seprapat galon),
						'other' => q({0} Imp. seprapat galon),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. seprapat galon),
						'other' => q({0} Imp. seprapat galon),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sendok mangan),
						'other' => q({0} sendok mangan),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sendok mangan),
						'other' => q({0} sendok mangan),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sendok teh),
						'other' => q({0} sendok teh),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sendok teh),
						'other' => q({0} sendok teh),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q({0} kaki²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q({0} kaki²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'other' => q({0} iji),
					},
					# Core Unit Identifier
					'item' => {
						'other' => q({0} iji),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'other' => q({0}bpj),
					},
					# Core Unit Identifier
					'permillion' => {
						'other' => q({0}bpj),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg inggris),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg inggris),
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dina),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dina),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(jam),
						'other' => q({0}j),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(jam),
						'other' => q({0}j),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mdtk),
						'other' => q({0} md),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mdtk),
						'other' => q({0} md),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(peken),
						'other' => q({0} peken),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(peken),
						'other' => q({0} peken),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(taun),
						'other' => q({0} taun),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(taun),
						'other' => q({0} taun),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'other' => q({0}panas AS),
					},
					# Core Unit Identifier
					'therm-us' => {
						'other' => q({0}panas AS),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'other' => q({0}kWh/km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'other' => q({0}kWh/km),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gram),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gram),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'other' => q({0}t),
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
						'other' => q({0}dj),
					},
					# Core Unit Identifier
					'horsepower' => {
						'other' => q({0}dj),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/jam),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/jam),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'other' => q({0}lbf⋅kaki),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'other' => q({0}lbf⋅kaki),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'other' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'other' => q({0}sde),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'other' => q({0}sde),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'other' => q({0}sde-lmp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'other' => q({0}sde-lmp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'other' => q({0}by.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'other' => q({0}by.dr.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'other' => q({0}ons by),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'other' => q({0}ons by),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'other' => q({0}oz lm by),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'other' => q({0}oz lm by),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'other' => q({0}gallm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'other' => q({0}gallm),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liter),
						'other' => q({0} L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liter),
						'other' => q({0} L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'other' => q({0}juwit),
					},
					# Core Unit Identifier
					'pinch' => {
						'other' => q({0}juwit),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'other' => q({0}sprt),
					},
					# Core Unit Identifier
					'quart' => {
						'other' => q({0}sprt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'other' => q({0}spt-lmp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'other' => q({0}spt-lmp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'other' => q({0}sdm),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'other' => q({0}sdm),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(tenaga-g),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(tenaga-g),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter/detik²),
						'other' => q({0} m/detik²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter/detik²),
						'other' => q({0} m/detik²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(menit saka busur),
						'other' => q({0} menit saka busur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(menit saka busur),
						'other' => q({0} menit saka busur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(detik saka busur),
						'other' => q({0} detik saka busur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(detik saka busur),
						'other' => q({0} detik saka busur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(derajat),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(derajat),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rev),
						'other' => q({0} rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rev),
						'other' => q({0} rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(are),
						'other' => q({0} are),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(are),
						'other' => q({0} are),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kaki pesagi),
						'other' => q({0} kaki pesagi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kaki pesagi),
						'other' => q({0} kaki pesagi),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci²),
						'other' => q({0} inci²),
						'per' => q({0}/inci²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci²),
						'other' => q({0} inci²),
						'per' => q({0}/inci²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mil²),
						'other' => q({0} mil²),
						'per' => q({0}/mil²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mil²),
						'other' => q({0} mil²),
						'per' => q({0}/mil²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard²),
						'other' => q({0} yard²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard²),
						'other' => q({0} yard²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(iji),
						'other' => q({0} iji),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(iji),
						'other' => q({0} iji),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'other' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'other' => q({0} mmol/L),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(persen),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(persen),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permil),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permil),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bagean/yuta),
						'other' => q({0} bagean saben yuta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bagean/yuta),
						'other' => q({0} bagean saben yuta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permiriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permiriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter/km),
						'other' => q({0} L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil/galon),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/galon),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/galon inggris),
						'other' => q({0} mpg inggris),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/galon inggris),
						'other' => q({0} mpg inggris),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bite),
						'other' => q({0} bite),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bite),
						'other' => q({0} bite),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GBite),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GBite),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kBite),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kBite),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MBite),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MBite),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PBite),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PBite),
						'other' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TBite),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TBite),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dina),
						'other' => q({0} dina),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dina),
						'other' => q({0} dina),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dsw),
						'other' => q({0} dsw),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dsw),
						'other' => q({0} dsw),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0}/jam),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0}/jam),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milidtk),
						'other' => q({0} md),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milidtk),
						'other' => q({0} md),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
						'per' => q({0}/sasi),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
						'per' => q({0}/sasi),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanodtk),
						'other' => q({0} nd),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanodtk),
						'other' => q({0} nd),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
						'per' => q({0}/dtk),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
						'per' => q({0}/dtk),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(peken),
						'other' => q({0} peken),
						'per' => q({0}/peken),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(peken),
						'other' => q({0} peken),
						'per' => q({0}/peken),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(taun),
						'other' => q({0} taun),
						'per' => q({0}/taun),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(taun),
						'other' => q({0} taun),
						'per' => q({0}/taun),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamper),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamper),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kal),
						'other' => q({0} Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kal),
						'other' => q({0} Kal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(jol),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(jol),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojol),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojol),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-jam),
						'other' => q({0} kW-jam),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-jam),
						'other' => q({0} kW-jam),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(takeran panas AS),
						'other' => q({0} takeran panas AS),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(takeran panas AS),
						'other' => q({0} takeran panas AS),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pon gaya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pon gaya),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(GHz),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GHz),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Hz),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Hz),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kHz),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kHz),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MHz),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MHz),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(titik),
						'other' => q({0} titik),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(titik),
						'other' => q({0} titik),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(tscm),
						'other' => q({0} tscm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(tscm),
						'other' => q({0} tscm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(tsi),
						'other' => q({0} tsi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(tsi),
						'other' => q({0} tsi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathoms),
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathoms),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0}/kaki),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0}/kaki),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'other' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'other' => q({0} fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inci),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inci),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(taun cahya),
						'other' => q({0} tc),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(taun cahya),
						'other' => q({0} tc),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μmeter),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmeter),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'other' => q({0} ps),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} ps),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(poin),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(poin),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radii srengenge),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radii srengenge),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luk),
						'other' => q({0} luk),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luk),
						'other' => q({0} luk),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminositas srengenge),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminositas srengenge),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(massa Bumi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(massa Bumi),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(wiji),
						'other' => q({0} wiji),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(wiji),
						'other' => q({0} wiji),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gram),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gram),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mg),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mg),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0}/ons),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0}/ons),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0}/pon),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0}/pon),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(massa srengenge),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(massa srengenge),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(watu),
						'other' => q({0} watu),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(watu),
						'other' => q({0} watu),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
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
					'power-gigawatt' => {
						'name' => q(GW),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GW),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(tenogo jaran),
						'other' => q({0} tenogo jaran),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(tenogo jaran),
						'other' => q({0} tenogo jaran),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MW),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MW),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mW),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mW),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm),
						'other' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm),
						'other' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'other' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'other' => q({0} mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mm Hg),
						'other' => q({0} mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mm Hg),
						'other' => q({0} mm Hg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/jam),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/jam),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter/dtk),
						'other' => q({0} m/dtk),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter/dtk),
						'other' => q({0} m/dtk),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil/jam),
						'other' => q({0} mil/jam),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/jam),
						'other' => q({0} mil/jam),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pon-kaki),
						'other' => q({0} pon-kaki),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pon-kaki),
						'other' => q({0} pon-kaki),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(are-kaki),
						'other' => q({0} are-kaki),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(are-kaki),
						'other' => q({0} are-kaki),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(gantang),
						'other' => q({0} gantang),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(gantang),
						'other' => q({0} gantang),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kaki³),
						'other' => q({0} kaki³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kaki³),
						'other' => q({0} kaki³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci³),
						'other' => q({0} inci³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci³),
						'other' => q({0} inci³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil³),
						'other' => q({0} mil³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil³),
						'other' => q({0} mil³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard³),
						'other' => q({0} yard³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard³),
						'other' => q({0} yard³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kup),
						'other' => q({0} kup),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kup),
						'other' => q({0} kup),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrik kup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrik kup),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dL),
						'other' => q({0} dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dL),
						'other' => q({0} dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(sendok es),
						'other' => q({0} sendok es),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(sendok es),
						'other' => q({0} sendok es),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. sendok es),
						'other' => q({0} Imp. sendok es),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. sendok es),
						'other' => q({0} Imp. sendok es),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(banyu dram),
						'other' => q({0} banyu dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(banyu dram),
						'other' => q({0} banyu dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tetes),
						'other' => q({0} tetes),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tetes),
						'other' => q({0} tetes),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ons banyu),
						'other' => q({0} ons banyu),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ons banyu),
						'other' => q({0} ons banyu),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. ons banyu),
						'other' => q({0} Imp. ons banyu),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. ons banyu),
						'other' => q({0} Imp. ons banyu),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0}/galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0}/galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galon inggris),
						'other' => q({0} gal inggris),
						'per' => q({0}/galon inggris),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galon inggris),
						'other' => q({0} gal inggris),
						'per' => q({0}/galon inggris),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'other' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'other' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liter),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liter),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ML),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ML),
						'other' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mL),
						'other' => q({0} mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mL),
						'other' => q({0} mL),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(juwit),
						'other' => q({0} sak juwit),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(juwit),
						'other' => q({0} sak juwit),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pin),
						'other' => q({0} pin),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pin),
						'other' => q({0} pin),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrik pin),
						'other' => q({0} metrik pin),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrik pin),
						'other' => q({0} metrik pin),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(seprapat galon),
						'other' => q({0} seprapat galon),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(seprapat galon),
						'other' => q({0} seprapat galon),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. seprapat galon),
						'other' => q({0} Imp. seprapat galon),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. seprapat galon),
						'other' => q({0} Imp. seprapat galon),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sdk mgn),
						'other' => q({0} sdk mgn),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sdk mgn),
						'other' => q({0} sdk mgn),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sdk teh),
						'other' => q({0} sdk teh),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sdk teh),
						'other' => q({0} sdk teh),
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
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
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
			'long' => {
				'1000' => {
					'other' => '0 èwu',
				},
				'10000' => {
					'other' => '00 èwu',
				},
				'100000' => {
					'other' => '000 èwu',
				},
				'1000000' => {
					'other' => '0 yuta',
				},
				'10000000' => {
					'other' => '00 yuta',
				},
				'100000000' => {
					'other' => '000 yuta',
				},
				'1000000000' => {
					'other' => '0 milyar',
				},
				'10000000000' => {
					'other' => '00 milyar',
				},
				'100000000000' => {
					'other' => '000 milyar',
				},
				'1000000000000' => {
					'other' => '0 trilyun',
				},
				'10000000000000' => {
					'other' => '00 trilyun',
				},
				'100000000000000' => {
					'other' => '000 trilyun',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0È',
				},
				'10000' => {
					'other' => '00È',
				},
				'100000' => {
					'other' => '000È',
				},
				'1000000' => {
					'other' => '0Y',
				},
				'10000000' => {
					'other' => '00Y',
				},
				'100000000' => {
					'other' => '000Y',
				},
				'1000000000' => {
					'other' => '0M',
				},
				'10000000000' => {
					'other' => '00M',
				},
				'100000000000' => {
					'other' => '000M',
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
			display_name => {
				'currency' => q(Dirham Uni Emirat Arab),
				'other' => q(Dirham Uni Emirat Arab),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani Afganistan),
				'other' => q(Afghani Afganistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek Albania),
				'other' => q(Lek Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Armenia),
				'other' => q(Dram Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Guilder Antilla Walanda),
				'other' => q(Guilder Antilla Walanda),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angola),
				'other' => q(Kwanza Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso Argentina),
				'other' => q(Peso Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolar Australia),
				'other' => q(Dolar Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin Aruban),
				'other' => q(Florin Aruban),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Azerbaijan),
				'other' => q(Manat Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Mark Konvertibel Bosnia-Herzegovina),
				'other' => q(Mark Konvertibel Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dolar Barbadian),
				'other' => q(Dolar Barbadian),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Bangladesh),
				'other' => q(Taka Bangladesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev Bulgaria),
				'other' => q(Lev Bulgaria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahrain Dinar),
				'other' => q(Bahrain Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franc Burundi),
				'other' => q(Franc Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dolar Bermuda),
				'other' => q(Dolar Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dolar Brunai),
				'other' => q(Dolar Brunai),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano Bolivia),
				'other' => q(Boliviano Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brasil),
				'other' => q(Real Brasil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dolar Bahamian),
				'other' => q(Dolar Bahamian),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Bhutan),
				'other' => q(Ngultrum Bhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Botswana),
				'other' => q(Pula Botswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Ruble Belarusia),
				'other' => q(Ruble Belarusia),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dolar Belise),
				'other' => q(Dolar Belise),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolar Kanada),
				'other' => q(Dolar Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franc Kongo),
				'other' => q(Franc Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franc Swiss),
				'other' => q(Franc Swiss),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Chili),
				'other' => q(Peso Chili),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan Tyongkok \(Jaban Rangkah\)),
				'other' => q(Yuan Tyongkok \(Jaban Rangkah\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Tyongkok),
				'other' => q(Yuan Tyongkok),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Kolumbia),
				'other' => q(Peso Kolumbia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colon Kosta Rika),
				'other' => q(Colon Kosta Rika),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Konvertibel Kuba),
				'other' => q(Peso Konvertibel Kuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Kuba),
				'other' => q(Peso Kuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Tanjung Verde),
				'other' => q(Escudo Tanjung Verde),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Czech),
				'other' => q(Koruna Czech),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franc Djibouti),
				'other' => q(Franc Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone Denmark),
				'other' => q(Krone Denmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Dominika),
				'other' => q(Peso Dominika),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Algeria),
				'other' => q(Dinar Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pound Mesir),
				'other' => q(Pound Mesir),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eritrea),
				'other' => q(Nakfa Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Ethiopia),
				'other' => q(Birr Ethiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(Euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dolar Fiji),
				'other' => q(Dolar Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pound Kepuloan Falkland),
				'other' => q(Pound Kepuloan Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pound Inggris),
				'other' => q(Pound Inggris),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Georgia),
				'other' => q(Lari Georgia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Ghana),
				'other' => q(Cedi Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pound Gibraltar),
				'other' => q(Pound Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Gambia),
				'other' => q(Dalasi Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franc Guinea),
				'other' => q(Franc Guinea),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Guatemala),
				'other' => q(Quetzal Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dolar Guyana),
				'other' => q(Dolar Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dolar Hong Kong),
				'other' => q(Dolar Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Honduras),
				'other' => q(Lempira Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Kroasia),
				'other' => q(Kuna Kroasia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haiti),
				'other' => q(Gourde Haiti),
			},
		},
		'HUF' => {
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
			display_name => {
				'currency' => q(Shekel Anyar Israel),
				'other' => q(Shekel Anyar Israel),
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
				'currency' => q(Dinar Irak),
				'other' => q(Dinar Irak),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iran),
				'other' => q(Rial Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Krona Islandia),
				'other' => q(Krona Islandia),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolar Jamaika),
				'other' => q(Dolar Jamaika),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Yordania),
				'other' => q(Dinar Yordania),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Jepang),
				'other' => q(Yen Jepang),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilling Kenya),
				'other' => q(Shilling Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Kirgistan),
				'other' => q(Som Kirgistan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Kamboja),
				'other' => q(Riel Kamboja),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franc Komoro),
				'other' => q(Franc Komoro),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Korea Lor),
				'other' => q(Won Korea Lor),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Korea Kidul),
				'other' => q(Won Korea Kidul),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Kuwait),
				'other' => q(Dinar Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dolar Kepuloan Caiman),
				'other' => q(Dolar Kepuloan Caiman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge Kasakhstan),
				'other' => q(Tenge Kasakhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Laos),
				'other' => q(Kip Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pound Libanon),
				'other' => q(Pound Libanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupee Sri Lanka),
				'other' => q(Rupee Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolar Liberia),
				'other' => q(Dolar Liberia),
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
				'currency' => q(Dinar Libya),
				'other' => q(Dinar Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Maroko),
				'other' => q(Dirham Moroko),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Moldova),
				'other' => q(Leu Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Malagasi),
				'other' => q(Ariary Malagasi),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar Masedonia),
				'other' => q(Denar Masedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Myanmar),
				'other' => q(Kyat Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Mongol),
				'other' => q(Tugrik Mongol),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Macau),
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
			display_name => {
				'currency' => q(Ouguiya Mauritania),
				'other' => q(Ouguiya Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupee Mauritius),
				'other' => q(Rupee Mauritius),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa Maladewa),
				'other' => q(Rufiyaa Maladewa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Malawi),
				'other' => q(Kwacha Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Meksiko),
				'other' => q(Peso Meksiko),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Malaysia),
				'other' => q(Ringgit Malaysia),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mosambik),
				'other' => q(Metical Mosambik),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolar Namibia),
				'other' => q(Dolar Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigeria),
				'other' => q(Naira Nigeria),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Cordoba Nikaragua),
				'other' => q(Cordoba Nikaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone Norwegia),
				'other' => q(Krone Norwegia),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupee Nepal),
				'other' => q(Rupee Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dolar Selandia Anyar),
				'other' => q(Dolar Selandia Anyar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Oman),
				'other' => q(Rial Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panama),
				'other' => q(Balboa Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Peru),
				'other' => q(Sol Peru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papua Nugini),
				'other' => q(Kina Papua Nugini),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Piso Filipina),
				'other' => q(Piso Filipina),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupee Pakistan),
				'other' => q(Rupee Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty Polandia),
				'other' => q(Zloty Polandia),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani Paraguay),
				'other' => q(Guarani Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial Qatar),
				'other' => q(Rial Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Rumania),
				'other' => q(Leu Rumania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Serbia),
				'other' => q(Dinar Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubel Rusia),
				'other' => q(Rubel Rusia),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franc Rwanda),
				'other' => q(Franc Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Saudi),
				'other' => q(Riyal Saudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dolar Kepuloan Solomon),
				'other' => q(Dolar Kepuloan Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupee Seichelles),
				'other' => q(Rupee Seichelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pound Sudan),
				'other' => q(Pound Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona Swedia),
				'other' => q(Krona Swedia),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dolar Singapura),
				'other' => q(Dolar Singapura),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pound Santa Helena),
				'other' => q(Pound Santa Helena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone Sierra Leone),
				'other' => q(Leone Sierra Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilling Somalia),
				'other' => q(Shilling Somalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dolar Suriname),
				'other' => q(Dolar Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pound Sudan Kidul),
				'other' => q(Pound Sudan Kidul),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra Sao Tome lan Principe),
				'other' => q(Dobra Sao Tome lan Principe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Pound Siria),
				'other' => q(Pound Siria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Swasi),
				'other' => q(Lilangeni Swasi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht Thai),
				'other' => q(Baht Thai),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Tajikistan),
				'other' => q(Somoni Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Turmenistan),
				'other' => q(Manat Turmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tunisia),
				'other' => q(Dinar Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga Tonga),
				'other' => q(Paʻanga Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira Turki),
				'other' => q(Lira Turki),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dolar Trinidad lan Tobago),
				'other' => q(Dolar Trinidad lan Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dolar Anyar Taiwan),
				'other' => q(Dolar Anyar Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilling Tansania),
				'other' => q(Shilling Tansania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Ukrania),
				'other' => q(Hryvnia Ukrania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilling Uganda),
				'other' => q(Shilling Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolar Amerika Serikat),
				'other' => q(Dolar Amerika Serikat),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Uruguay),
				'other' => q(Peso Uruguay),
			},
		},
		'UZS' => {
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
			display_name => {
				'currency' => q(Bolivar Venezuela),
				'other' => q(Bolivar Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Vietnam),
				'other' => q(Dong Vietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Vanuatu),
				'other' => q(Vatu Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Samoa),
				'other' => q(Tala Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA Franc Afrika Tengah),
				'other' => q(CFA Franc Afrika Tengah),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolar Karibia Wetan),
				'other' => q(Dolar Karibia Wetan),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA Franc Afrika Kulon),
				'other' => q(CFA Franc Afrika Kulon),
			},
		},
		'XPF' => {
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
			display_name => {
				'currency' => q(Rial Yaman),
				'other' => q(Rial Yaman),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand Afrika Kidul),
				'other' => q(Rand Afrika Kidul),
			},
		},
		'ZMW' => {
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
						sun => 'Ahad'
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
						sun => 'Ahad'
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
						sun => 'Ahad'
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
						sun => 'Ahad'
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
			GyMd => q{GGGGG dd-MM-y},
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
			GyMd => q{d/M/y GGGGG},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{'pekan' W 'ing' MMMM},
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
			yw => q{'pekan' w 'ing' Y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM, y G – E, d MMM, y G},
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				G => q{d MMM, y G – d MMM, y G},
				M => q{d MMM – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
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
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanai#,
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
			exemplarCity => q#Santa Helena#,
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
				'standard' => q#Wektu Chamorro#,
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
				'standard' => q#Wektu Universal Kakoordhinasi#,
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
				'daylight' => q#Wektu Ketigo Pulo Norfolk#,
				'generic' => q#Wektu Pulo Norfolk#,
				'standard' => q#Wektu Standar Pulo Norfolk#,
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
				'standard' => q#Wektu Singapura#,
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
		'Yukon' => {
			long => {
				'standard' => q#Wektu Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
