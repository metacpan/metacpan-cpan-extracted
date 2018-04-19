=head1

Locale::CLDR::Locales::Ckb - Package for language Central Kurdish

=cut

package Locale::CLDR::Locales::Ckb;
# This file auto generated from Data\common\main\ckb.xml
#	on Fri 13 Apr  7:05:12 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
				'af' => 'ئه‌فریكای',
 				'am' => 'ئەمهەرینجی',
 				'ar' => 'عەرەبی',
 				'as' => 'ئاسامی',
 				'az' => 'ئازەربایجانی',
 				'az@alt=short' => 'ئازەربایجانی',
 				'az_Arab' => 'ئازەربایجانی باشووری',
 				'be' => 'بیلاڕووسی',
 				'bg' => 'بۆلگاری',
 				'bn' => 'بەنگلادێشی',
 				'br' => 'برێتونی',
 				'bs' => 'بۆسنی',
 				'ca' => 'كاتالۆنی',
 				'ckb' => 'کوردیی ناوەندی',
 				'cs' => 'چەكی',
 				'cy' => 'وێلزی',
 				'da' => 'دانماركی',
 				'de' => 'ئاڵمانی',
 				'el' => 'یۆنانی',
 				'en' => 'ئینگلیزی',
 				'en_AU' => 'ئینگلیزیی ئۆسترالیایی',
 				'en_CA' => 'ئینگلیزیی کەنەدایی',
 				'en_GB' => 'ئینگلیزیی بریتانیایی',
 				'en_US' => 'ئینگلیزیی ئەمەریکایی',
 				'en_US@alt=short' => 'ئینگلیزیی ئەمەریکایی',
 				'eo' => 'ئێسپیرانتۆ',
 				'es' => 'ئیسپانی',
 				'et' => 'ئیستۆنی',
 				'eu' => 'باسکی',
 				'fa' => 'فارسی',
 				'fi' => 'فینلەندی',
 				'fil' => 'تاگالۆگی',
 				'fo' => 'فه‌رئۆیی',
 				'fr' => 'فەرانسی',
 				'fy' => 'فریسیی ڕۆژاوا',
 				'ga' => 'ئیرلەندی',
 				'gd' => 'گه‌لیكی سكۆتله‌ندی',
 				'gl' => 'گالیسی',
 				'gn' => 'گووارانی',
 				'gu' => 'گوجاراتی',
 				'he' => 'هیبرێ',
 				'hi' => 'هیندی',
 				'hr' => 'كرواتی',
 				'hu' => 'هەنگاری (مەجاری)',
 				'hy' => 'ئەرمەنی',
 				'ia' => 'ئینترلینگوی',
 				'id' => 'ئێەندونیزی',
 				'ie' => 'ئینتەرلیگ',
 				'is' => 'ئیسلەندی',
 				'it' => 'ئیتالی',
 				'ja' => 'ژاپۆنی',
 				'jv' => 'جاڤانی',
 				'ka' => 'گۆرجستانی',
 				'kk' => 'کازاخی',
 				'km' => 'کامبۆجی (زوبان)',
 				'kn' => 'كه‌نه‌دایی',
 				'ko' => 'كۆری',
 				'ku' => 'کوردی',
 				'ky' => 'كرگیزی',
 				'la' => 'لاتینی',
 				'ln' => 'لينگالا',
 				'lo' => 'لاوی',
 				'lt' => 'لیتوانی',
 				'lv' => 'لێتۆنی',
 				'mk' => 'ماكێدۆنی',
 				'ml' => 'مالایلام',
 				'mn' => 'مەنگۆلی',
 				'mr' => 'ماراتی',
 				'ms' => 'مالیزی',
 				'mt' => 'ماڵتایی',
 				'mzn' => 'مازەندەرانی',
 				'ne' => 'نیپالی',
 				'nl' => 'هۆڵەندی',
 				'no' => 'نۆروێژی',
 				'oc' => 'ئۆسیتانی',
 				'or' => 'ئۆرییا',
 				'pa' => 'پەنجابی',
 				'pl' => 'پۆڵۆنیایی (لەهستانی)',
 				'ps' => 'پەشتوو',
 				'pt' => 'پورتوگالی',
 				'ro' => 'ڕۆمانی',
 				'ru' => 'ڕووسی',
 				'sa' => 'سانسکريت',
 				'sd' => 'سيندی',
 				'sdh' => 'کوردیی باشووری',
 				'sh' => 'سێربۆكرواتی',
 				'si' => 'سینهەلی',
 				'sk' => 'سلۆڤاكی',
 				'sl' => 'سلۆڤێنی',
 				'sma' => 'سامی باشووری',
 				'so' => 'سۆمالی',
 				'sq' => 'ئەڵبانی',
 				'sr' => 'سەربی',
 				'st' => 'سێسۆتۆ',
 				'su' => 'سودانی',
 				'sv' => 'سویدی',
 				'sw' => 'سواهیلی',
 				'ta' => 'تامیلی',
 				'te' => 'تەلۆگوی',
 				'tg' => 'تاجیکی',
 				'th' => 'تایلەندی',
 				'ti' => 'تیگرینیای',
 				'tk' => 'تورکمانی',
 				'tlh' => 'كلینگۆن',
 				'tr' => 'تورکی',
 				'tw' => 'توی',
 				'ug' => 'ئويخووری',
 				'uk' => 'ئۆكراینی',
 				'und' => 'زمانی نەناسراو',
 				'ur' => 'ئۆردوو',
 				'uz' => 'ئوزبەکی',
 				'vi' => 'ڤیەتنامی',
 				'xh' => 'سسوسا',
 				'yi' => 'یوددی',
 				'zh' => 'چینی',
 				'zu' => 'زولو',

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
			'Arab' => 'عەرەبی',
 			'Armn' => 'ئەرمەنی',
 			'Beng' => 'بەنگالی',
 			'Bopo' => 'بۆپۆمۆفۆ',
 			'Brai' => 'برەیل',
 			'Cyrl' => 'سریلیک',
 			'Deva' => 'دەڤەناگەری',
 			'Ethi' => 'ئەتیۆپیک',
 			'Geor' => 'گورجی',
 			'Grek' => 'یۆنانی',
 			'Gujr' => 'گوجەراتی',
 			'Guru' => 'گورموکھی',
 			'Hang' => 'ھانگول',
 			'Hani' => 'ھان',
 			'Hans' => 'چینیی ئاسانکراو',
 			'Hant' => 'چینیی دێرین',
 			'Hebr' => 'هیبرێ',
 			'Hira' => 'ھیراگانا',
 			'Jpan' => 'ژاپۆنی',
 			'Kana' => 'کاتاکانا',
 			'Khmr' => 'خمێری',
 			'Knda' => 'کەنەدا',
 			'Kore' => 'کۆریایی',
 			'Laoo' => 'لاو',
 			'Latn' => 'لاتینی',
 			'Mlym' => 'مالایالام',
 			'Mong' => 'مەنگۆلی',
 			'Mymr' => 'میانمار',
 			'Orya' => 'ئۆریا',
 			'Sinh' => 'سینھالا',
 			'Taml' => 'تامیلی',
 			'Telu' => 'تیلوگو',
 			'Thaa' => 'تانە',
 			'Thai' => 'تایلەندی',
 			'Zxxx' => 'نەنووسراو',
 			'Zzzz' => 'خەتی نەناسراو',

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
			'002' => 'ئەفریقا',
 			'003' => 'ئەمەریکای باکوور',
 			'005' => 'ئەمەریکای باشوور',
 			'009' => 'ئۆقیانووسیا',
 			'011' => 'ڕۆژاوای ئەفریقا',
 			'013' => 'ئەمریکای ناوەڕاست',
 			'014' => 'ڕۆژھەڵاتی ئەفریقا',
 			'018' => 'باشووری ئەفریقا',
 			'019' => 'ئەمریکاکان',
 			'021' => 'ئەمریکای باکوور',
 			'030' => 'ئاسیای ڕۆژھەڵات',
 			'034' => 'باشووری ئاسیا',
 			'035' => 'باشووری ڕۆژھەڵاتی ئاسیا',
 			'039' => 'ئەورووپای باشووری',
 			'057' => 'ناوچەی مایکرۆنیزیا',
 			'142' => 'ئاسیا',
 			'143' => 'ئاسیای ناوەندی',
 			'145' => 'ئاسیای ڕۆژاوا',
 			'150' => 'ئەورووپا',
 			'151' => 'ئەورووپای ڕۆژھەڵات',
 			'154' => 'ئەورووپای باکوور',
 			'155' => 'ڕۆژاوای ئەورووپا',
 			'419' => 'ئەمەریکای لاتین',
 			'AD' => 'ئاندۆرا',
 			'AE' => 'میرنشینە یەکگرتووە عەرەبییەکان',
 			'AF' => 'ئەفغانستان',
 			'AG' => 'ئانتیگوا و باربودا',
 			'AL' => 'ئەڵبانیا',
 			'AM' => 'ئەرمەنستان',
 			'AO' => 'ئەنگۆلا',
 			'AQ' => 'ئانتارکتیکا',
 			'AR' => 'ئەرژەنتین',
 			'AS' => 'ساموای ئەمەریکایی',
 			'AT' => 'نەمسا',
 			'AU' => 'ئوسترالیا',
 			'AW' => 'ئارووبا',
 			'AZ' => 'ئازەربایجان',
 			'BA' => 'بۆسنیا و ھەرزەگۆڤینا',
 			'BB' => 'باربادۆس',
 			'BD' => 'بەنگلادیش',
 			'BE' => 'بەلژیک',
 			'BF' => 'بورکینافاسۆ',
 			'BG' => 'بولگاریا',
 			'BH' => 'بەحرەین',
 			'BI' => 'بوروندی',
 			'BJ' => 'بێنین',
 			'BN' => 'بروونای',
 			'BO' => 'بۆلیڤیا',
 			'BR' => 'برازیل',
 			'BS' => 'بەھاما',
 			'BT' => 'بووتان',
 			'BW' => 'بۆتسوانا',
 			'BY' => 'بیلاڕووس',
 			'BZ' => 'بەلیز',
 			'CA' => 'کانەدا',
 			'CD' => 'کۆنگۆ کینشاسا',
 			'CD@alt=variant' => 'کۆماری دیموکراتیکی کۆنگۆ',
 			'CF' => 'کۆماری ئەفریقای ناوەڕاست',
 			'CG' => 'کۆنگۆ برازاڤیل',
 			'CG@alt=variant' => 'کۆماری کۆنگۆ',
 			'CH' => 'سویسرا',
 			'CI' => 'کۆتدیڤوار',
 			'CL' => 'چیلی',
 			'CM' => 'کامیرۆن',
 			'CN' => 'چین',
 			'CO' => 'کۆلۆمبیا',
 			'CR' => 'کۆستاریکا',
 			'CU' => 'کووبا',
 			'CV' => 'کەیپڤەرد',
 			'CY' => 'قیبرس',
 			'CZ' => 'کۆماری چیک',
 			'DE' => 'ئەڵمانیا',
 			'DJ' => 'جیبووتی',
 			'DK' => 'دانمارک',
 			'DM' => 'دۆمینیکا',
 			'DZ' => 'جەزایر',
 			'EC' => 'ئیکوادۆر',
 			'EG' => 'میسر',
 			'EH' => 'ڕۆژاوای سەحرا',
 			'ER' => 'ئەریتریا',
 			'ES' => 'ئیسپانیا',
 			'ET' => 'ئەتیۆپیا',
 			'EU' => 'یەکێتیی ئەورووپا',
 			'FI' => 'فینلاند',
 			'FJ' => 'فیجی',
 			'FM' => 'مایکرۆنیزیا',
 			'FR' => 'فەڕەنسا',
 			'GA' => 'گابۆن',
 			'GB' => 'شانشینی یەکگرتوو',
 			'GD' => 'گرینادا',
 			'GE' => 'گورجستان',
 			'GH' => 'غەنا',
 			'GL' => 'گرینلاند',
 			'GM' => 'گامبیا',
 			'GN' => 'گینێ',
 			'GR' => 'یۆنان',
 			'GT' => 'گواتیمالا',
 			'GU' => 'گوام',
 			'GW' => 'گینێ بیساو',
 			'GY' => 'گویانا',
 			'HN' => 'ھۆندووراس',
 			'HR' => 'کرۆواتیا',
 			'HT' => 'ھایتی',
 			'HU' => 'مەجارستان',
 			'ID' => 'ئیندۆنیزیا',
 			'IE' => 'ئیرلەند',
 			'IL' => 'ئیسرائیل',
 			'IN' => 'ھیندستان',
 			'IQ' => 'عێراق',
 			'IR' => 'ئێران',
 			'IS' => 'ئایسلەند',
 			'IT' => 'ئیتاڵی',
 			'JM' => 'جامایکا',
 			'JO' => 'ئوردن',
 			'JP' => 'ژاپۆن',
 			'KG' => 'قرغیزستان',
 			'KH' => 'کەمبۆدیا',
 			'KI' => 'کیریباس',
 			'KM' => 'دوورگەکانی کۆمۆر',
 			'KN' => 'سەینت کیتس و نیڤیس',
 			'KP' => 'کۆریای باکوور',
 			'KR' => 'کۆریای باشوور',
 			'KW' => 'کوەیت',
 			'KZ' => 'کازاخستان',
 			'LA' => 'لاوس',
 			'LB' => 'لوبنان',
 			'LC' => 'سەینت لووسیا',
 			'LI' => 'لیختنشتاین',
 			'LK' => 'سریلانکا',
 			'LR' => 'لیبەریا',
 			'LS' => 'لەسۆتۆ',
 			'LT' => 'لیتوانایا',
 			'LU' => 'لوکسەمبورگ',
 			'LV' => 'لاتڤیا',
 			'LY' => 'لیبیا',
 			'MA' => 'مەغریب',
 			'MC' => 'مۆناکۆ',
 			'MD' => 'مۆلدۆڤا',
 			'ME' => 'مۆنتینیگرۆ',
 			'MG' => 'ماداگاسکار',
 			'MH' => 'دوورگەکانی مارشاڵ',
 			'ML' => 'مالی',
 			'MM' => 'میانمار',
 			'MN' => 'مەنگۆلیا',
 			'MO@alt=short' => 'ماکاو',
 			'MR' => 'مۆریتانیا',
 			'MT' => 'ماڵتا',
 			'MV' => 'مالدیڤ',
 			'MW' => 'مالاوی',
 			'MX' => 'مەکسیک',
 			'MY' => 'مالیزیا',
 			'MZ' => 'مۆزامبیک',
 			'NA' => 'نامیبیا',
 			'NE' => 'نیجەر',
 			'NI' => 'نیکاراگوا',
 			'NL' => 'ھۆڵەندا',
 			'NO' => 'نۆرویژ',
 			'NP' => 'نیپال',
 			'NR' => 'نائوروو',
 			'NZ' => 'نیوزیلاند',
 			'OM' => 'عومان',
 			'PA' => 'پاناما',
 			'PE' => 'پیروو',
 			'PG' => 'پاپوا گینێی نوێ',
 			'PH' => 'فلیپین',
 			'PK' => 'پاکستان',
 			'PL' => 'پۆڵەندا',
 			'PS' => 'فەلەستین',
 			'PT' => 'پورتوگال',
 			'PW' => 'پالاو',
 			'PY' => 'پاراگوای',
 			'QA' => 'قەتەر',
 			'RO' => 'ڕۆمانیا',
 			'RS' => 'سربیا',
 			'RU' => 'ڕووسیا',
 			'RW' => 'ڕواندا',
 			'SA' => 'عەرەبستانی سەعوودی',
 			'SB' => 'دوورگەکانی سلێمان',
 			'SC' => 'سیشێل',
 			'SD' => 'سوودان',
 			'SE' => 'سوید',
 			'SG' => 'سینگاپور',
 			'SI' => 'سلۆڤێنیا',
 			'SK' => 'سلۆڤاکیا',
 			'SL' => 'سیەرالیۆن',
 			'SM' => 'سان مارینۆ',
 			'SN' => 'سینیگال',
 			'SO' => 'سۆمالیا',
 			'SR' => 'سورینام',
 			'ST' => 'ساوتۆمێ و پرینسیپی',
 			'SV' => 'ئێلسالڤادۆر',
 			'SY' => 'سووریا',
 			'SZ' => 'سوازیلاند',
 			'TD' => 'چاد',
 			'TG' => 'تۆگۆ',
 			'TH' => 'تایلەند',
 			'TJ' => 'تاجیکستان',
 			'TL@alt=variant' => 'تیمۆری ڕۆژھەڵات',
 			'TM' => 'تورکمانستان',
 			'TN' => 'توونس',
 			'TO' => 'تۆنگا',
 			'TR' => 'تورکیا',
 			'TT' => 'ترینیداد و تۆباگو',
 			'TV' => 'تووڤالوو',
 			'TW' => 'تایوان',
 			'TZ' => 'تانزانیا',
 			'UA' => 'ئۆکرانیا',
 			'UG' => 'ئوگاندا',
 			'US' => 'ویلایەتە یەکگرتووەکان',
 			'UY' => 'ئوروگوای',
 			'UZ' => 'ئوزبەکستان',
 			'VA' => 'ڤاتیکان',
 			'VC' => 'سەینت ڤینسەنت و گرینادینز',
 			'VN' => 'ڤیەتنام',
 			'VU' => 'ڤانوواتوو',
 			'WS' => 'ساموا',
 			'YE' => 'یەمەن',
 			'ZA' => 'ئەفریقای باشوور',
 			'ZM' => 'زامبیا',
 			'ZW' => 'زیمبابوی',
 			'ZZ' => 'نەناسراو',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'ڕۆژژمێر',
 			'collation' => 'ڕیزبەندی',
 			'currency' => 'دراو',
 			'numbers' => 'ژمارەکان',

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
 				'chinese' => q{ڕۆژژمێری چینی},
 				'gregorian' => q{ڕۆژژمێری گورجی},
 				'hebrew' => q{ڕۆژژمێری عیبری},
 				'indian' => q{ڕۆژژمێری نەتەوەیی ھیندی},
 				'islamic' => q{ڕۆژژمێری کۆچیی مانگی},
 				'persian' => q{ڕۆژژمێری کۆچیی ھەتاوی},
 			},
 			'numbers' => {
 				'arab' => q{ژمارە عەربی-ھیندییەکان},
 				'gujr' => q{ژمارە گوجەراتییەکان},
 				'khmr' => q{ژمارە خمێرییەکان},
 				'latn' => q{ژمارە ڕۆژاوایییەکان},
 				'mymr' => q{ژمارە میانمارییەکان},
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
			'metric' => q{مەتریک},
 			'UK' => q{بریتانی},
 			'US' => q{ئەمەریکی},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'زمان: {0}',
 			'script' => 'خەت: {0}',
 			'region' => 'ناوچە: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => '',
			characters => 'right-to-left',
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
			auxiliary => qr{[‎‏ ً ٌ ٍ َ ُ ِ ّ ْ ء آ أ ؤ إ ة ث ذ ص ض ط ظ ك ه ى ي]},
			index => ['ئ', 'ا', 'ب', 'پ', 'ت', 'ج', 'چ', 'ح', 'خ', 'د', 'ر', 'ز', 'ڕ', 'ژ', 'س', 'ش', 'ع', 'غ', 'ف', 'ڤ', 'ق', 'ک', 'گ', 'ل', 'ڵ', 'م', 'ن', 'ھ', 'ە', 'و', 'ۆ', 'ی', 'ێ'],
			main => qr{[ئ ا ب پ ت ج چ ح خ د ر ز ڕ ژ س ش ع غ ف ڤ ق ک گ ل ڵ م ن ھ ە و ۆ ی ێ]},
			numbers => qr{[‎‏ \- , ٫ ٬ . % ٪ ‰ ؉ + 0٠ 1١ 2٢ 3٣ 4٤ 5٥ 6٦ 7٧ 8٨ 9٩]},
		};
	},
EOT
: sub {
		return { index => ['ئ', 'ا', 'ب', 'پ', 'ت', 'ج', 'چ', 'ح', 'خ', 'د', 'ر', 'ز', 'ڕ', 'ژ', 'س', 'ش', 'ع', 'غ', 'ف', 'ڤ', 'ق', 'ک', 'گ', 'ل', 'ڵ', 'م', 'ن', 'ھ', 'ە', 'و', 'ۆ', 'ی', 'ێ'], };
},
);


has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arab',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arab',
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
			'exponential' => q(اس),
			'group' => q(٬),
			'infinity' => q(∞),
			'minusSign' => q(‏-),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‏+),
			'superscriptingExponent' => q(×),
		},
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(‎+),
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
		'arab' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '#,##0.00 ¤',
					},
				},
			},
		},
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
		'AFN' => {
			display_name => {
				'currency' => q(ئەفغانیی ئەفغانستان),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(دیناری بەحرەینی),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(دۆلاری بەلیزی),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(دیناری جەزائیری),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(یورۆ),
			},
		},
		'IQD' => {
			symbol => 'د.ع.‏',
			display_name => {
				'currency' => q(دیناری عێراقی),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(ڕیاڵی ئێرانی),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(دیناری ئوردنی),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(دیناری کووەیتی),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(ڕیاڵی عومانی),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(ڕیاڵی قەتەری),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(ڕیاڵی سەعوودی),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(دیناری توونس),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(لیرەی تورکیا),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(دۆلاری ترینیداد و تۆباگۆ),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(زێڕ),
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
							'کانوونی دووەم',
							'شوبات',
							'ئازار',
							'نیسان',
							'ئایار',
							'حوزەیران',
							'تەمووز',
							'ئاب',
							'ئەیلوول',
							'تشرینی یەکەم',
							'تشرینی دووەم',
							'کانونی یەکەم'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ک',
							'ش',
							'ئ',
							'ن',
							'ئ',
							'ح',
							'ت',
							'ئ',
							'ئ',
							'ت',
							'ت',
							'ک'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'کانوونی دووەم',
							'شوبات',
							'ئازار',
							'نیسان',
							'ئایار',
							'حوزەیران',
							'تەمووز',
							'ئاب',
							'ئەیلوول',
							'تشرینی یەکەم',
							'تشرینی دووەم',
							'کانونی یەکەم'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'کانوونی دووەم',
							'شوبات',
							'ئازار',
							'نیسان',
							'ئایار',
							'حوزەیران',
							'تەمووز',
							'ئاب',
							'ئەیلوول',
							'تشرینی یەکەم',
							'تشرینی دووەم',
							'کانونی یەکەم'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ک',
							'ش',
							'ئ',
							'ن',
							'ئ',
							'ح',
							'ت',
							'ئ',
							'ئ',
							'ت',
							'ت',
							'ک'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'کانوونی دووەم',
							'شوبات',
							'ئازار',
							'نیسان',
							'ئایار',
							'حوزەیران',
							'تەمووز',
							'ئاب',
							'ئەیلوول',
							'تشرینی یەکەم',
							'تشرینی دووەم',
							'کانونی یەکەم'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'خاکەلێوە',
							'بانەمەڕ',
							'جۆزەردان',
							'پووشپەڕ',
							'گەلاوێژ',
							'خەرمانان',
							'ڕەزبەر',
							'خەزەڵوەر',
							'سەرماوەز',
							'بەفرانبار',
							'ڕێبەندان',
							'رەشەمێ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'خاکەلێوە',
							'بانەمەڕ',
							'جۆزەردان',
							'پووشپەڕ',
							'گەلاوێژ',
							'خەرمانان',
							'ڕەزبەر',
							'خەزەڵوەر',
							'سەرماوەز',
							'بەفرانبار',
							'ڕێبەندان',
							'رەشەمێ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'خاکەلێوە',
							'بانەمەڕ',
							'جۆزەردان',
							'پووشپەڕ',
							'گەلاوێژ',
							'خەرمانان',
							'ڕەزبەر',
							'خەزەڵوەر',
							'سەرماوەز',
							'بەفرانبار',
							'ڕێبەندان',
							'رەشەمێ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'خاکەلێوە',
							'بانەمەڕ',
							'جۆزەردان',
							'پووشپەڕ',
							'گەلاوێژ',
							'خەرمانان',
							'ڕەزبەر',
							'خەزەڵوەر',
							'سەرماوەز',
							'بەفرانبار',
							'ڕێبەندان',
							'رەشەمێ'
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
			'generic' => {
				'format' => {
					abbreviated => {
						mon => 'دووشەممە',
						tue => 'سێشەممە',
						wed => 'چوارشەممە',
						thu => 'پێنجشەممە',
						fri => 'ھەینی',
						sat => 'شەممە',
						sun => 'یەکشەممە'
					},
					narrow => {
						mon => 'د',
						tue => 'س',
						wed => 'چ',
						thu => 'پ',
						fri => 'ھ',
						sat => 'ش',
						sun => 'ی'
					},
					wide => {
						mon => 'دووشەممە',
						tue => 'سێشەممە',
						wed => 'چوارشەممە',
						thu => 'پێنجشەممە',
						fri => 'ھەینی',
						sat => 'شەممە',
						sun => 'یەکشەممە'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'دووشەممە',
						tue => 'سێشەممە',
						wed => 'چوارشەممە',
						thu => 'پێنجشەممە',
						fri => 'ھەینی',
						sat => 'شەممە',
						sun => 'یەکشەممە'
					},
					narrow => {
						mon => 'د',
						tue => 'س',
						wed => 'چ',
						thu => 'پ',
						fri => 'ھ',
						sat => 'ش',
						sun => 'ی'
					},
					wide => {
						mon => 'دووشەممە',
						tue => 'سێشەممە',
						wed => 'چوارشەممە',
						thu => 'پێنجشەممە',
						fri => 'ھەینی',
						sat => 'شەممە',
						sun => 'یەکشەممە'
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						mon => 'دووشەممە',
						tue => 'سێشەممە',
						wed => 'چوارشەممە',
						thu => 'پێنجشەممە',
						fri => 'ھەینی',
						sat => 'شەممە',
						sun => 'یەکشەممە'
					},
					narrow => {
						mon => 'د',
						tue => 'س',
						wed => 'چ',
						thu => 'پ',
						fri => 'ھ',
						sat => 'ش',
						sun => 'ی'
					},
					short => {
						mon => '٢ش',
						tue => '٣ش',
						wed => '٤ش',
						thu => '٥ش',
						fri => 'ھ',
						sat => 'ش',
						sun => '١ش'
					},
					wide => {
						mon => 'دووشەممە',
						tue => 'سێشەممە',
						wed => 'چوارشەممە',
						thu => 'پێنجشەممە',
						fri => 'ھەینی',
						sat => 'شەممە',
						sun => 'یەکشەممە'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'دووشەممە',
						tue => 'سێشەممە',
						wed => 'چوارشەممە',
						thu => 'پێنجشەممە',
						fri => 'ھەینی',
						sat => 'شەممە',
						sun => 'یەکشەممە'
					},
					narrow => {
						mon => 'د',
						tue => 'س',
						wed => 'چ',
						thu => 'پ',
						fri => 'ھ',
						sat => 'ش',
						sun => 'ی'
					},
					short => {
						mon => '٢ش',
						tue => '٣ش',
						wed => '٤ش',
						thu => '٥ش',
						fri => 'ھ',
						sat => 'ش',
						sun => '١ش'
					},
					wide => {
						mon => 'دووشەممە',
						tue => 'سێشەممە',
						wed => 'چوارشەممە',
						thu => 'پێنجشەممە',
						fri => 'ھەینی',
						sat => 'شەممە',
						sun => 'یەکشەممە'
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
			'generic' => {
				'format' => {
					wide => {0 => 'چارەکی یەکەم',
						1 => 'چارەکی دووەم',
						2 => 'چارەکی سێەم',
						3 => 'چارەکی چوارەم'
					},
				},
				'stand-alone' => {
					wide => {0 => 'چارەکی یەکەم',
						1 => 'چارەکی دووەم',
						2 => 'چارەکی سێەم',
						3 => 'چارەکی چوارەم'
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {0 => 'چ١',
						1 => 'چ٢',
						2 => 'چ٣',
						3 => 'چ٤'
					},
					narrow => {0 => '١',
						1 => '٢',
						2 => '٣',
						3 => '٤'
					},
					wide => {0 => 'چارەکی یەکەم',
						1 => 'چارەکی دووەم',
						2 => 'چارەکی سێەم',
						3 => 'چارەکی چوارەم'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'چ١',
						1 => 'چ٢',
						2 => 'چ٣',
						3 => 'چ٤'
					},
					narrow => {0 => '١',
						1 => '٢',
						2 => '٣',
						3 => '٤'
					},
					wide => {0 => 'چارەکی یەکەم',
						1 => 'چارەکی دووەم',
						2 => 'چارەکی سێەم',
						3 => 'چارەکی چوارەم'
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
		'generic' => {
			'format' => {
				'wide' => {
					'am' => q{ب.ن},
					'pm' => q{د.ن},
				},
				'abbreviated' => {
					'pm' => q{د.ن},
					'am' => q{ب.ن},
				},
			},
		},
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{ب.ن},
					'pm' => q{د.ن},
				},
				'wide' => {
					'am' => q{ب.ن},
					'pm' => q{د.ن},
				},
				'narrow' => {
					'am' => q{ب.ن},
					'pm' => q{د.ن},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{ب.ن},
					'pm' => q{د.ن},
				},
				'wide' => {
					'pm' => q{د.ن},
					'am' => q{ب.ن},
				},
				'abbreviated' => {
					'am' => q{ب.ن},
					'pm' => q{د.ن},
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
				'0' => 'پێش زایین',
				'1' => 'زایینی'
			},
			narrow => {
				'0' => 'پ.ن',
				'1' => 'ز'
			},
			wide => {
				'0' => 'پێش زایین',
				'1' => 'زایینی'
			},
		},
		'persian' => {
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
			'long' => q{dی MMMMی y G},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{y MMMM d, EEEE},
			'long' => q{dی MMMMی y},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
		},
		'persian' => {
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
		'persian' => {
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
		'persian' => {
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
			Ed => q{E dھەم},
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
			MEd => q{E، M/d},
			MMM => q{LLL},
			MMMEd => q{E، dی MMM},
			MMMMW => q{هەفتەی W ی MMM},
			MMMMd => q{MMMM d},
			MMMd => q{dی MMM},
			Md => q{MM-dd},
			d => q{d},
			h => q{hی a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E، d/M/y},
			yMMM => q{MMMی y},
			yMMMEd => q{E، dی MMMی y},
			yMMMM => q{y MMMM},
			yMMMd => q{dی MMMی y},
			yMd => q{d/M/y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{هەفتەی w ی Y},
		},
		'generic' => {
			E => q{ccc},
			Ed => q{E dھەم},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			M => q{L},
			MEd => q{E، M/d},
			MMM => q{LLL},
			MMMEd => q{E، dی MMM},
			MMMMd => q{MMMM d},
			MMMd => q{dی MMM},
			Md => q{MM-dd},
			d => q{d},
			h => q{hی a},
			y => q{G y},
			yM => q{M/y},
			yMEd => q{E، d/M/y},
			yMMM => q{MMMی y},
			yMMMEd => q{E، dی MMMی y},
			yMMMd => q{dی MMMی y},
			yMd => q{d/M/y},
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
			MEd => {
				M => q{E، M/d – E، M/d},
				d => q{E، M/d – E، M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				d => q{E، dی MMM – E، dی MMM},
			},
			MMMd => {
				d => q{d–dی MMM},
			},
			yMEd => {
				M => q{E، d/M/y – E، d/M/y},
				d => q{E، d/M/y – E، d/M/y},
				y => q{E، d/M/y – E، d/M/y},
			},
			yMMM => {
				M => q{MMM–MMMی y},
				y => q{MMMی y – MMMی y},
			},
			yMMMd => {
				M => q{dی MMM – dی MMMی y},
				d => q{d–dی MMMی y},
				y => q{dی MMMMی y – dی MMMMی y},
			},
			yMd => {
				y => q{d/M/y – d/M/y},
			},
		},
		'generic' => {
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{E، M/d – E، M/d},
				d => q{E، M/d – E، M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{E، dی MMM – E، dی MMM},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{d–dی MMM},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			yMEd => {
				M => q{E، d/M/y – E، d/M/y},
				d => q{E، d/M/y – E، d/M/y},
				y => q{E، d/M/y – E، d/M/y},
			},
			yMMM => {
				M => q{MMM–MMMی y},
				y => q{MMMی y – MMMی y},
			},
			yMMMEd => {
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{G y MMMM–MMMM},
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{dی MMM – dی MMMی y},
				d => q{d–dی MMMی y},
				y => q{dی MMMMی y – dی MMMMی y},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
