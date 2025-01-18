=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Trw - Package for language Torwali

=cut

package Locale::CLDR::Locales::Trw;
# This file auto generated from Data\common\main\trw.xml
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
				'af' => 'افریقی',
 				'agq' => 'اگھیم',
 				'ak' => 'آکان',
 				'am' => 'امھاریک',
 				'ar' => 'عربی',
 				'ar_001' => 'ماڈرن اسٹینڈرڈ عربی',
 				'as' => 'اسامی',
 				'asa' => 'اسو',
 				'ast' => 'استوری',
 				'az' => 'ازری',
 				'bas' => 'باسا',
 				'be' => 'بیلاروسی',
 				'bem' => 'بیمبا',
 				'bez' => 'بینا',
 				'bg' => 'بلغاری',
 				'bm' => 'بمبارا',
 				'bn' => 'بنگلہ',
 				'br' => 'بریٹون',
 				'brx' => 'بوڈو',
 				'bs' => 'بوسنیائی',
 				'de' => 'جرمن',
 				'de_AT' => 'آسٹریائی جرمن',
 				'de_CH' => 'سوئس ہائی جرمن',
 				'en' => 'انگریزی',
 				'en_AU' => 'آسٹریلیائی انگریزی',
 				'en_CA' => 'کینیڈین انگریزی',
 				'en_GB' => 'برطانوی انگریزی',
 				'en_GB@alt=short' => 'انگریزی (یو کے)',
 				'en_US' => 'امریکی انگریزی',
 				'es' => 'ہسپانوی',
 				'es_419' => 'لاطینی امریکی ہسپانوی',
 				'es_ES' => 'یورپی ہسپانوی',
 				'es_MX' => 'میکسیکن ہسپانوی',
 				'fr' => 'فرانسیسی',
 				'fr_CA' => 'کینیڈین فرانسیسی',
 				'fr_CH' => 'سوئس فرینچ',
 				'hi' => 'ہندی',
 				'hy' => 'ارمینی',
 				'id' => 'انڈونیثیائی',
 				'it' => 'اطالوی',
 				'ja' => 'جاپانی',
 				'ko' => 'کوریائی',
 				'ksf' => 'بافیہ',
 				'my' => 'برمی',
 				'nl' => 'ڈچ',
 				'nl_BE' => 'فلیمِش',
 				'pl' => 'پولش',
 				'pt' => 'پُرتگالی',
 				'pt_BR' => 'برازیلی پرتگالی',
 				'pt_PT' => 'یورپی پرتگالی',
 				'ru' => 'روسی',
 				'sq' => 'البانی',
 				'th' => 'تھائی',
 				'tr' => 'ترکی',
 				'trw' => 'توروالی',
 				'und' => 'نامعلوم جِب',
 				'zh' => 'چینی',
 				'zh@alt=menu' => 'چینی، مندارن',
 				'zh_Hans' => 'چینی (آسان کوئیل)',
 				'zh_Hans@alt=long' => 'سادہ مندارن چینی',
 				'zh_Hant' => 'روایتی چینی',
 				'zh_Hant@alt=long' => 'روایتی مندارن چینی',

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
			'Arab' => 'عربی',
 			'Cyrl' => 'سیریلک',
 			'Hans' => 'آسان',
 			'Hans@alt=stand-alone' => 'آسان ہان',
 			'Hant' => 'روایتی',
 			'Hant@alt=stand-alone' => 'روایتی ہان',
 			'Jpan' => 'جاپانی',
 			'Kore' => 'کوریائی',
 			'Latn' => 'لاطینی',
 			'Zxxx' => 'اولِک',
 			'Zzzz' => 'نامعلوم جِب',

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
			'001' => 'دونیئ',
 			'002' => 'افریقہ',
 			'003' => 'شمالی امریکہ',
 			'005' => 'جنوبی امریکہ',
 			'009' => 'اوشیانیا',
 			'011' => 'مغربی افریقہ',
 			'013' => 'وسطی امریکہ',
 			'014' => 'مشرقی افریقہ',
 			'015' => 'شمالی افریقہ',
 			'017' => 'وسطی افریقہ',
 			'018' => 'جنوبی افریقہ سی علاقہ',
 			'019' => 'امیریکاز',
 			'021' => 'شمالی امریکہ سی علاقہ',
 			'029' => 'کریبیائی',
 			'030' => 'مشرقی ایشیا',
 			'034' => 'جنوبی ایشیا',
 			'035' => 'جنوب مشرقی ایشیا',
 			'039' => 'جنوبی یورپ',
 			'053' => 'آسٹریلیشیا',
 			'054' => 'مالینیشیا',
 			'057' => 'مائکرونیشیائی علاقہ',
 			'061' => 'پولینیشیا',
 			'142' => 'ایشیا',
 			'143' => 'وسطی ایشیا',
 			'145' => 'مغربی ایشیا',
 			'150' => 'یورپ',
 			'151' => 'مشرقی یورپ',
 			'154' => 'شمالی یورپ',
 			'155' => 'مغربی یورپ',
 			'202' => 'ذیلی صحارن افریقہ',
 			'419' => 'لاطینی امریکہ',
 			'AC' => 'اسینشن آئلینڈ',
 			'AD' => 'انڈورا',
 			'AE' => 'متحدہ عرب امارات',
 			'AF' => 'افغانستان',
 			'AG' => 'انٹیگوا اور باربودا',
 			'AI' => 'انگوئیلا',
 			'AL' => 'البانیہ',
 			'AM' => 'آرمینیا',
 			'AO' => 'انگولا',
 			'AQ' => 'انٹارکٹیکا',
 			'AR' => 'ارجنٹینا',
 			'AS' => 'امریکی ساموآ',
 			'AT' => 'آسٹریا',
 			'AU' => 'اسٹریلیا',
 			'AW' => 'اروبا',
 			'AX' => 'آلینڈ آئلینڈز',
 			'AZ' => 'آذربائیجان',
 			'BA' => 'بوسنیا آں ہرزیگووینا',
 			'BB' => 'بارباڈوس',
 			'BD' => 'بنگلہ دیش',
 			'BE' => 'بیلجیم',
 			'BF' => 'برکینا فاسو',
 			'BG' => 'بلغاریہ',
 			'BH' => 'بحرین',
 			'BI' => 'برونڈی',
 			'BJ' => 'بینن',
 			'BL' => 'سینٹ برتھلیمی',
 			'BM' => 'برمودا',
 			'BN' => 'برونائی',
 			'BO' => 'بولیویا',
 			'BQ' => 'کریبیائی نیدرلینڈز',
 			'BR' => 'برازیل',
 			'BS' => 'بہاماس',
 			'BT' => 'بھوٹان',
 			'BV' => 'بؤویٹ آئلینڈ',
 			'BW' => 'بوتسوانا',
 			'BY' => 'بیلاروس',
 			'BZ' => 'بیلائز',
 			'CA' => 'کینیڈا',
 			'CC' => 'کوکوس (کیلنگ) جزائر',
 			'CD' => 'کانگو - کنشاسا',
 			'CD@alt=variant' => 'کانگو (DRC)',
 			'CF' => 'وسط افریقی جمہوریہ',
 			'CG' => 'کانگو - برازاویلے',
 			'CG@alt=variant' => 'کانگو (جمہوریہ)',
 			'CH' => 'سوئٹزر لینڈ',
 			'CI' => 'کوٹ ڈی آئیوری',
 			'CI@alt=variant' => 'آئیوری کوسٹ',
 			'CK' => 'کک آئلینڈز',
 			'CL' => 'چلی',
 			'CM' => 'کیمرون',
 			'CN' => 'چین',
 			'CO' => 'کولمبیا',
 			'CP' => 'کلپرٹن آئلینڈ',
 			'CR' => 'کوسٹا ریکا',
 			'CU' => 'کیوبا',
 			'CV' => 'کیپ ورڈی',
 			'CW' => 'کیوراکاؤ',
 			'CX' => 'جزیرہ کرسمس',
 			'CY' => 'قبرص',
 			'CZ' => 'چیکیا',
 			'CZ@alt=variant' => 'چیک جمہوریہ',
 			'DE' => 'جرمنی',
 			'DG' => 'ڈائجو گارسیا',
 			'DJ' => 'جبوتی',
 			'DK' => 'ڈنمارک',
 			'DM' => 'ڈومنیکا',
 			'DO' => 'جمہوریہ ڈومينيکن',
 			'DZ' => 'الجیریا',
 			'EA' => 'سیئوٹا آں میلیلا',
 			'EC' => 'ایکواڈور',
 			'EE' => 'اسٹونیا',
 			'EG' => 'مصر',
 			'EH' => 'مغربی صحارا',
 			'ER' => 'اریٹیریا',
 			'ES' => 'ہسپانیہ',
 			'ET' => 'ایتھوپیا',
 			'EU' => 'یوروپی یونین',
 			'EZ' => 'یوروزون',
 			'FI' => 'فن لینڈ',
 			'FJ' => 'فجی',
 			'FK' => 'فاکلینڈ جزائر',
 			'FK@alt=variant' => 'فاکلینڈ جزائر (مالویناس)',
 			'FM' => 'مائکرونیشیا',
 			'FO' => 'جزائر فارو',
 			'FR' => 'فرانس',
 			'GA' => 'گیبون',
 			'GB' => 'سلطنت متحدہ',
 			'GB@alt=short' => 'یو کے سلطنت متحدہ',
 			'GD' => 'گریناڈا',
 			'GE' => 'جارجیا',
 			'GF' => 'فرینچ گیانا',
 			'GG' => 'گوئرنسی',
 			'GH' => 'گھانا',
 			'GI' => 'جبل الطارق',
 			'GL' => 'گرین لینڈ',
 			'GM' => 'گیمبیا',
 			'GN' => 'گنی',
 			'GP' => 'گواڈیلوپ',
 			'GQ' => 'استوائی گیانا',
 			'GR' => 'یونان',
 			'GS' => 'جنوبی جارجیا آں جنوبی سینڈوچ جزائر',
 			'GT' => 'گواٹے مالا',
 			'GU' => 'گوام',
 			'GW' => 'گنی بساؤ',
 			'GY' => 'گیانا',
 			'HK' => 'ہانگ کانگ SAR چین',
 			'HK@alt=short' => 'ہانگ کانگ ہانگ کانگ SAR چین',
 			'HM' => 'ہیرڈ جزیرہ و میکڈولینڈ جزائر',
 			'HN' => 'ہونڈاروس',
 			'HR' => 'کروشیا',
 			'HT' => 'ہیٹی',
 			'HU' => 'ہنگری',
 			'IC' => 'کینری آئلینڈز',
 			'ID' => 'انڈونیشیا',
 			'IE' => 'آئرلینڈ',
 			'IL' => 'اسرائیل',
 			'IM' => 'آئل آف مین',
 			'IN' => 'بھارت',
 			'IO' => 'برطانوی بحر ہند سی علاقہ',
 			'IQ' => 'عراق',
 			'IR' => 'ایران',
 			'IS' => 'آئس لینڈ',
 			'IT' => 'اٹلی',
 			'JE' => 'جرسی',
 			'JM' => 'جمائیکا',
 			'JO' => 'اردن',
 			'JP' => 'جاپان',
 			'KE' => 'کینیا',
 			'KG' => 'کرغزستان',
 			'KH' => 'کمبوڈیا',
 			'KI' => 'کریباتی',
 			'KM' => 'کوموروس',
 			'KN' => 'سینٹ کٹس اور نیویس',
 			'KP' => 'شمالی کوریا',
 			'KR' => 'جنوبی کوریا',
 			'KW' => 'کویت',
 			'KY' => 'کیمین آئلینڈز',
 			'KZ' => 'قزاخستان',
 			'LA' => 'لاؤس',
 			'LB' => 'لبنان',
 			'LC' => 'سینٹ لوسیا',
 			'LI' => 'لیشٹنسٹائن',
 			'LK' => 'سری لنکا',
 			'LR' => 'لائبیریا',
 			'LS' => 'لیسوتھو',
 			'LT' => 'لیتھونیا',
 			'LU' => 'لکسمبرگ',
 			'LV' => 'لٹویا',
 			'LY' => 'لیبیا',
 			'MA' => 'مراکش',
 			'MC' => 'موناکو',
 			'MD' => 'مالدووا',
 			'ME' => 'مونٹے نیگرو',
 			'MF' => 'سینٹ مارٹن',
 			'MG' => 'مڈغاسکر',
 			'MH' => 'مارشل آئلینڈز',
 			'MK' => 'شمالی مقدونیہ',
 			'ML' => 'مالی',
 			'MM' => 'میانمار (برما)',
 			'MN' => 'منگولیا',
 			'MO' => 'مکاؤ SAR چین',
 			'MO@alt=short' => 'مکاؤ مکاؤ SAR چین',
 			'MP' => 'شمالی ماریانا آئلینڈز',
 			'MQ' => 'مارٹینک',
 			'MR' => 'موریطانیہ',
 			'MS' => 'مونٹسیراٹ',
 			'MT' => 'مالٹا',
 			'MU' => 'ماریشس',
 			'MV' => 'مالدیپ',
 			'MW' => 'ملاوی',
 			'MX' => 'میکسیکو',
 			'MY' => 'ملائشیا',
 			'MZ' => 'موزمبیق',
 			'NA' => 'نامیبیا',
 			'NC' => 'نیو کلیڈونیا',
 			'NE' => 'نائجر',
 			'NF' => 'نارفوک آئلینڈ',
 			'NG' => 'نائجیریا',
 			'NI' => 'نکاراگووا',
 			'NL' => 'نیدر لینڈز',
 			'NO' => 'ناروے',
 			'NP' => 'نیپال',
 			'NR' => 'نؤرو',
 			'NU' => 'نیئو',
 			'NZ' => 'نیوزی لینڈ',
 			'OM' => 'عمان',
 			'PA' => 'پانامہ',
 			'PE' => 'پیرو',
 			'PF' => 'فرانسیسی پولینیشیا',
 			'PG' => 'پاپوآ نیو گنی',
 			'PH' => 'فلپائن',
 			'PK' => 'پاکستان',
 			'PL' => 'پولینڈ',
 			'PM' => 'سینٹ پیئر آں میکلیئون',
 			'PN' => 'پٹکائرن جزائر',
 			'PR' => 'پیورٹو ریکو',
 			'PS' => 'فلسطینی خطے',
 			'PS@alt=short' => 'فلسطین فلسطینی خطے',
 			'PT' => 'پرتگال',
 			'PW' => 'پلاؤ',
 			'PY' => 'پیراگوئے',
 			'QA' => 'قطر',
 			'QO' => 'بیرونی اوشیانیا',
 			'RE' => 'ری یونین',
 			'RO' => 'رومانیہ',
 			'RS' => 'سربیا',
 			'RU' => 'روس',
 			'RW' => 'روانڈا',
 			'SA' => 'سعودی عرب',
 			'SB' => 'سولومن آئلینڈز',
 			'SC' => 'سشلیز',
 			'SD' => 'سوڈان',
 			'SE' => 'سویڈن',
 			'SG' => 'سنگاپور',
 			'SH' => 'سینٹ ہیلینا',
 			'SI' => 'سلووینیا',
 			'SJ' => 'سوالبرڈ آں جان ماین',
 			'SK' => 'سلوواکیہ',
 			'SL' => 'سیرالیون',
 			'SM' => 'سان مارینو',
 			'SN' => 'سینیگل',
 			'SO' => 'صومالیہ',
 			'SR' => 'سورینام',
 			'SS' => 'جنوبی سوڈان',
 			'ST' => 'ساؤ ٹومے آں پرنسپے',
 			'SV' => 'ال سلواڈور',
 			'SX' => 'سنٹ مارٹن',
 			'SY' => 'شام',
 			'SZ' => 'سواتنی',
 			'SZ@alt=variant' => 'سوازی لینڈ',
 			'TA' => 'ٹرسٹن ڈا کیونہا',
 			'TC' => 'ٹرکس آں کیکوس جزائر',
 			'TD' => 'چاڈ',
 			'TF' => 'فرانسیسی جنوبی خطے',
 			'TG' => 'ٹوگو',
 			'TH' => 'تھائی لینڈ',
 			'TJ' => 'تاجکستان',
 			'TK' => 'ٹوکیلاؤ',
 			'TL' => 'تیمور لیسٹ',
 			'TL@alt=variant' => 'مشرقی تیمور تیمور لیسٹ',
 			'TM' => 'ترکمانستان',
 			'TN' => 'تونس',
 			'TO' => 'ٹونگا',
 			'TR' => 'ترکی',
 			'TT' => 'ترینیداد آں ٹوباگو',
 			'TV' => 'ٹووالو',
 			'TW' => 'تائیوان',
 			'TZ' => 'تنزانیہ',
 			'UA' => 'یوکرین',
 			'UG' => 'یوگنڈا',
 			'UM' => 'امریکہ ما باہرسی لَو جزائز',
 			'UN' => 'اقوام متحدہ',
 			'US' => 'ریاست ہائے متحدہ امریکہ',
 			'US@alt=short' => 'امریکا',
 			'UY' => 'یوروگوئے',
 			'UZ' => 'ازبکستان',
 			'VA' => 'ویٹیکن سٹی',
 			'VC' => 'سینٹ ونسنٹ آں گرینیڈائنز',
 			'VE' => 'وینزوئیلا',
 			'VG' => 'برٹش ورجن آئلینڈز',
 			'VI' => 'امریکی ورجن آئلینڈز',
 			'VN' => 'ویتنام',
 			'VU' => 'وینوآٹو',
 			'WF' => 'ویلیز آں فیوٹیونا',
 			'WS' => 'ساموآ',
 			'XA' => 'بناوٹی لہجے',
 			'XB' => 'مصنوعی بیڑی',
 			'XK' => 'کوسووو',
 			'YE' => 'یمن',
 			'YT' => 'مایوٹ',
 			'ZA' => 'جنوبی افریقہ',
 			'ZM' => 'زامبیا',
 			'ZW' => 'زمبابوے',
 			'ZZ' => 'نامعلوم علاقہ',

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
 				'gregorian' => q{جارجیائی کیلنڈر},
 				'iso8601' => q{ISO-8601 کیلنڈر},
 			},
 			'collation' => {
 				'standard' => q{معیاری چھانٹی سی ترتیب},
 			},
 			'numbers' => {
 				'arab' => q{عربی ہندی ہندسے},
 				'latn' => q{مغربی ہندسے},
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
			'metric' => q{میٹرک},
 			'UK' => q{برطانیہ},
 			'US' => q{ریاست ہائے متحدہ امریکہ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'جِب:{0}',
 			'script' => 'لِک:{0}',
 			'region' => 'علاقہ:{0}',

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
			auxiliary => qr{[؀؁؂؃‌‍‎‏ ً ٌ ٍ َ ُ ِ ّ ْ ٔ ٖ ٗ ٘ ٰ ٻ ٺ ټ ٽ ۃ ي]},
			index => ['ء', 'ٶ', 'آ', 'أ', 'ئ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ٹ', 'ج', 'چ', 'ڇ', 'ح', 'خ', 'څ', 'ݲ', 'د', 'ذ', 'ڈ', 'ر', 'ز', 'ڑ', 'ژ', 'ڙ', 'س', 'ش', 'ݜ', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ں', 'ھ', 'ہ', 'و', 'ی', 'ے'],
			main => qr{[ء ٶ آ أ ئ ا ب پ ت ث ٹ ج چ ڇ ح خ څ ݲ د ذ ڈ ر ز ڑ ژ ڙ س ش ݜ ص ض ط ظ ع غ ف ق ک گ ل م ن ں ھ ہ و ی ے]},
			numbers => qr{[‎ \- ‑ , ٫ ٬ . % ‰ + 0۰ 1۱ 2۲ 3۳ 4۴ 5۵ 6۶ 7۷ 8۸ 9۹]},
			punctuation => qr{[، ؍ ٫ ٬ ؛ \: ؟ . ۔ ( ) \[ \]]},
		};
	},
EOT
: sub {
		return { index => ['ء', 'ٶ', 'آ', 'أ', 'ئ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ٹ', 'ج', 'چ', 'ڇ', 'ح', 'خ', 'څ', 'ݲ', 'د', 'ذ', 'ڈ', 'ر', 'ز', 'ڑ', 'ژ', 'ڙ', 'س', 'ش', 'ݜ', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ں', 'ھ', 'ہ', 'و', 'ی', 'ے'], };
},
);


has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{؟},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(کارڈینل ڈائریکشن),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(کارڈینل ڈائریکشن),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(کیبی{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(کیبی{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(میبی{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(میبی{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(جیبی{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(جیبی{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(ٹیبی{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(ٹیبی{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(پیبی{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(پیبی{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ایکسبی{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ایکسبی{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(زیبی{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(زیبی{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(یوب{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(یوب{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(ڈیسی {0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ڈیسی {0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(پکو{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(پکو{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(فیمٹو{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(فیمٹو{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(اٹو{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(اٹو{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(سینٹی {0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(سینٹی {0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(زپٹو{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(زپٹو{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(ملی {0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(ملی {0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(مائکرو {0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(مائکرو {0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(نینو {0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(نینو {0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ڈیکا{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ڈیکا{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ٹیرا{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ٹیرا{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(پیٹا{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(پیٹا{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(اکسا{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(اکسا{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ہیکٹو{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ہیکٹو{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(زیٹا{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(زیٹا{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(یوٹا{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(یوٹا{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(کلو{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(کلو{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(میگا{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(میگا{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(گیگا {0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(گیگا {0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'other' => q({0} جی-فورس),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} جی-فورس),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(میٹر فی مربع سیکنڈ),
						'other' => q({0} میٹر فی مربع سیکنڈ),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(میٹر فی مربع سیکنڈ),
						'other' => q({0} میٹر فی مربع سیکنڈ),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(ریڈینس),
						'other' => q({0} ریڈین),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(ریڈینس),
						'other' => q({0} ریڈین),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(گردش),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(گردش),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(مربع سینٹی میٹر),
						'other' => q({0} مربع سینٹی میٹر),
						'per' => q({0} فی مربع سینٹی میٹر),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(مربع سینٹی میٹر),
						'other' => q({0} مربع سینٹی میٹر),
						'per' => q({0} فی مربع سینٹی میٹر),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'other' => q({0} مربع انچا),
						'per' => q({0} فی مربع انچا),
					},
					# Core Unit Identifier
					'square-inch' => {
						'other' => q({0} مربع انچا),
						'per' => q({0} فی مربع انچا),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(مربع کلو میٹر),
						'other' => q({0} مربع کلو میٹر),
						'per' => q({0} فی مربع کلو میٹر),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(مربع کلو میٹر),
						'other' => q({0} مربع کلو میٹر),
						'per' => q({0} فی مربع کلو میٹر),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'other' => q({0} مربع میٹر),
						'per' => q({0} فی مربع میٹر),
					},
					# Core Unit Identifier
					'square-meter' => {
						'other' => q({0} مربع میٹر),
						'per' => q({0} فی مربع میٹر),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q({0} مربع میل),
						'per' => q({0} فی مربع میل),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q({0} مربع میل),
						'per' => q({0} فی مربع میل),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'other' => q({0} مربع گز),
					},
					# Core Unit Identifier
					'square-yard' => {
						'other' => q({0} مربع گز),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'other' => q({0} قیراط),
					},
					# Core Unit Identifier
					'karat' => {
						'other' => q({0} قیراط),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(ملی گرام فی ڈیسی لیٹر),
						'other' => q({0} ملی گرام فی ڈیسی لیٹر),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(ملی گرام فی ڈیسی لیٹر),
						'other' => q({0} ملی گرام فی ڈیسی لیٹر),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ملی مولس فی لیٹر),
						'other' => q({0} ملی مول فی لیٹر),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ملی مولس فی لیٹر),
						'other' => q({0} ملی مول فی لیٹر),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(مولز),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(مولز),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q({0} فیصد),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q({0} فیصد),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(فی ملین حصے),
						'other' => q({0} فی ملین حصے),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(فی ملین حصے),
						'other' => q({0} فی ملین حصے),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'other' => q({0} پرمرئیڈ),
					},
					# Core Unit Identifier
					'permyriad' => {
						'other' => q({0} پرمرئیڈ),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(لیٹر فی 100 کلو میٹر),
						'other' => q({0} لیٹر فی 100 کلو میٹر),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(لیٹر فی 100 کلو میٹر),
						'other' => q({0} لیٹر فی 100 کلو میٹر),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(لیٹر فی کلومیٹر),
						'other' => q({0} لیٹر فی کلومیٹر),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(لیٹر فی کلومیٹر),
						'other' => q({0} لیٹر فی کلومیٹر),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(میل فی گیلن),
						'other' => q({0} میل فی گیلن),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(میل فی گیلن),
						'other' => q({0} میل فی گیلن),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(میل فی امپیریل گیلن),
						'other' => q({0} میل فی امپیریل گیلن),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(میل فی امپیریل گیلن),
						'other' => q({0} میل فی امپیریل گیلن),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} مشرق),
						'north' => q({0} شمال),
						'south' => q({0} جنوب),
						'west' => q({0} مغرب),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} مشرق),
						'north' => q({0} شمال),
						'south' => q({0} جنوب),
						'west' => q({0} مغرب),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(بٹس),
						'other' => q({0} بٹ),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(بٹس),
						'other' => q({0} بٹ),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'other' => q({0} بائٹ),
					},
					# Core Unit Identifier
					'byte' => {
						'other' => q({0} بائٹ),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(گیگابٹس),
						'other' => q({0} گیگابٹ),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(گیگابٹس),
						'other' => q({0} گیگابٹ),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(گیگابائٹس),
						'other' => q({0} گیگابائٹ),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(گیگابائٹس),
						'other' => q({0} گیگابائٹ),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(کلوبٹس),
						'other' => q({0} کلوبٹ),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(کلوبٹس),
						'other' => q({0} کلوبٹ),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(کلوبائٹس),
						'other' => q({0} کلوبائٹ),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(کلوبائٹس),
						'other' => q({0} کلوبائٹ),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(میگابٹس),
						'other' => q({0} میگابٹ),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(میگابٹس),
						'other' => q({0} میگابٹ),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(ميگابائٹس),
						'other' => q({0} میگابائٹ),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(ميگابائٹس),
						'other' => q({0} میگابائٹ),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(پیٹا بائٹس),
						'other' => q({0} پیٹا بائٹ),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(پیٹا بائٹس),
						'other' => q({0} پیٹا بائٹ),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(ٹیرابٹس),
						'other' => q({0} ٹیرابٹ),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(ٹیرابٹس),
						'other' => q({0} ٹیرابٹ),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ٹیرابائٹس),
						'other' => q({0} ٹیرابائٹ),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ٹیرابائٹس),
						'other' => q({0} ٹیرابائٹ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(دہائیاں),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(دہائیاں),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(مائیکرو سیکنڈز),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(مائیکرو سیکنڈز),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ملی سیکنڈز),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ملی سیکنڈز),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q(فی کال {0}),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q(فی کال {0}),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ایمپیئر),
						'other' => q({0} ایمپیئر),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ایمپیئر),
						'other' => q({0} ایمپیئر),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(ملی ایمپیئر),
						'other' => q({0} ملی ایمپیئر),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(ملی ایمپیئر),
						'other' => q({0} ملی ایمپیئر),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0} اوہم),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0} اوہم),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0} وولٹ),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0} وولٹ),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(برطانوی تھرمل اکائیاں),
						'other' => q({0} برطانوی تھرمل اکائی),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(برطانوی تھرمل اکائیاں),
						'other' => q({0} برطانوی تھرمل اکائی),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(کیلوریز),
						'other' => q({0} کیلوری),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(کیلوریز),
						'other' => q({0} کیلوری),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(الیکٹرون وولٹس),
						'other' => q({0} الیکٹرون وولٹ),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(الیکٹرون وولٹس),
						'other' => q({0} الیکٹرون وولٹ),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(کیلوریز),
						'other' => q({0} کیلوری),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(کیلوریز),
						'other' => q({0} کیلوری),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(جول),
						'other' => q({0} جول),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(جول),
						'other' => q({0} جول),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(کلو کیلوریز),
						'other' => q({0} کلو کیلوری),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(کلو کیلوریز),
						'other' => q({0} کلو کیلوری),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(کلو جول),
						'other' => q({0} کلو جول),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(کلو جول),
						'other' => q({0} کلو جول),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(کلو واٹ آور),
						'other' => q({0} کلو واٹ آور),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(کلو واٹ آور),
						'other' => q({0} کلو واٹ آور),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(امریکی تھرمز),
						'other' => q({0} امریکی تھرم),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(امریکی تھرمز),
						'other' => q({0} امریکی تھرم),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(نیوٹنز),
						'other' => q({0} نیوٹن),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(نیوٹنز),
						'other' => q({0} نیوٹن),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(پاؤنڈز قوت),
						'other' => q({0} پاؤنڈ قوت),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(پاؤنڈز قوت),
						'other' => q({0} پاؤنڈ قوت),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(گیگاہرٹز),
						'other' => q({0} گیگاہرٹز),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(گیگاہرٹز),
						'other' => q({0} گیگاہرٹز),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(ہرٹز),
						'other' => q({0} ہرٹز),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(ہرٹز),
						'other' => q({0} ہرٹز),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(کلوہرٹز),
						'other' => q({0} کلوہرٹز),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(کلوہرٹز),
						'other' => q({0} کلوہرٹز),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(میگاہرٹز),
						'other' => q({0} میگاہرٹز),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(میگاہرٹز),
						'other' => q({0} میگاہرٹز),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ڈاٹس فی سینٹی میٹر),
						'other' => q({0} ڈاٹ فی سینٹی میٹر),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ڈاٹس فی سینٹی میٹر),
						'other' => q({0} ڈاٹ فی سینٹی میٹر),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ڈاٹس فی انچا),
						'other' => q({0} ڈاٹ فی انچا),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ڈاٹس فی انچا),
						'other' => q({0} ڈاٹ فی انچا),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ٹائپوگرافک em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ٹائپوگرافک em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'other' => q({0} میگا پکسل),
					},
					# Core Unit Identifier
					'megapixel' => {
						'other' => q({0} میگا پکسل),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'other' => q({0} پکسل),
					},
					# Core Unit Identifier
					'pixel' => {
						'other' => q({0} پکسل),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(پکسلز فی سینٹی میٹر),
						'other' => q({0} پکسل فی سینٹی میٹر),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(پکسلز فی سینٹی میٹر),
						'other' => q({0} پکسل فی سینٹی میٹر),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(پکسلز فی انچا),
						'other' => q({0} پکسل فی انچا),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(پکسلز فی انچا),
						'other' => q({0} پکسل فی انچا),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ایسٹرونومیکل یونٹس),
						'other' => q({0} ایسٹرونومیکل یونٹ),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ایسٹرونومیکل یونٹس),
						'other' => q({0} ایسٹرونومیکل یونٹ),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'per' => q({0} فی سینٹی میٹر),
					},
					# Core Unit Identifier
					'centimeter' => {
						'per' => q({0} فی سینٹی میٹر),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(ڈیسی میٹر),
						'other' => q({0} ڈیسی میٹر),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(ڈیسی میٹر),
						'other' => q({0} ڈیسی میٹر),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(زمین کا رداس),
						'other' => q({0} زمین رداس),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(زمین کا رداس),
						'other' => q({0} زمین رداس),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0} فی فٹ),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0} فی فٹ),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q({0} فی انچا),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0} فی انچا),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'per' => q({0} فی کلومیٹر),
					},
					# Core Unit Identifier
					'kilometer' => {
						'per' => q({0} فی کلومیٹر),
					},
					# Long Unit Identifier
					'length-meter' => {
						'per' => q({0} فی میٹر),
					},
					# Core Unit Identifier
					'meter' => {
						'per' => q({0} فی میٹر),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(مائیکرو میٹر),
						'other' => q({0} مائیکرو میٹر),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(مائیکرو میٹر),
						'other' => q({0} مائیکرو میٹر),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(اسکینڈی نیویائی میل),
						'other' => q({0} اسکینڈی نیویائی میل),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(اسکینڈی نیویائی میل),
						'other' => q({0} اسکینڈی نیویائی میل),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'other' => q({0} ملیمیٹر),
					},
					# Core Unit Identifier
					'millimeter' => {
						'other' => q({0} ملیمیٹر),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(نینو میٹر),
						'other' => q({0} نینو میٹر),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(نینو میٹر),
						'other' => q({0} نینو میٹر),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(کنڈیلا),
						'other' => q({0} کنڈیلا),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(کنڈیلا),
						'other' => q({0} کنڈیلا),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(لیومِن),
						'other' => q({0} لیومِن),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(لیومِن),
						'other' => q({0} لیومِن),
					},
					# Long Unit Identifier
					'light-lux' => {
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(شمسی چمک),
						'other' => q({0} شمسی چمک),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(شمسی چمک),
						'other' => q({0} شمسی چمک),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'other' => q({0} قیراط),
					},
					# Core Unit Identifier
					'carat' => {
						'other' => q({0} قیراط),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'other' => q({0} ڈالٹن),
					},
					# Core Unit Identifier
					'dalton' => {
						'other' => q({0} ڈالٹن),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'other' => q({0} زمینی کمیت),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'other' => q({0} زمینی کمیت),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} گرام),
						'per' => q({0} فی گرام),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} گرام),
						'per' => q({0} فی گرام),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(کلو),
						'other' => q({0} کلو),
						'per' => q({0} فی کلو),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(کلو),
						'other' => q({0} کلو),
						'per' => q({0} فی کلو),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(مائکرو گرام),
						'other' => q({0} مائکرو گرام),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(مائکرو گرام),
						'other' => q({0} مائکرو گرام),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(ملی گرام),
						'other' => q({0} ملی گرام),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(ملی گرام),
						'other' => q({0} ملی گرام),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(اونس),
						'other' => q({0} اونس),
						'per' => q({0} فی اونس),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(اونس),
						'other' => q({0} اونس),
						'per' => q({0} فی اونس),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ٹرائے اونس),
						'other' => q({0} ٹرائے اونس),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ٹرائے اونس),
						'other' => q({0} ٹرائے اونس),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'other' => q({0} پاؤنڈ),
						'per' => q({0} فی پاؤنڈ),
					},
					# Core Unit Identifier
					'pound' => {
						'other' => q({0} پاؤنڈ),
						'per' => q({0} فی پاؤنڈ),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'other' => q({0} شمسی کمیت),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'other' => q({0} شمسی کمیت),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(اسٹونز),
						'other' => q({0} اسٹون),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(اسٹونز),
						'other' => q({0} اسٹون),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'other' => q({0} ٹن),
					},
					# Core Unit Identifier
					'ton' => {
						'other' => q({0} ٹن),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(میٹرک ٹن),
						'other' => q({0} میٹرک ٹن),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(میٹرک ٹن),
						'other' => q({0} میٹرک ٹن),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} فی {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} فی {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(گیگا واٹ),
						'other' => q({0} گیگا واٹ),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(گیگا واٹ),
						'other' => q({0} گیگا واٹ),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ہارس پاور),
						'other' => q({0} ہارس پاور),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ہارس پاور),
						'other' => q({0} ہارس پاور),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(کلو واٹ),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(کلو واٹ),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(میگا واٹ),
						'other' => q({0} میگا واٹ),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(میگا واٹ),
						'other' => q({0} میگا واٹ),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(ملی واٹ),
						'other' => q({0} ملی واٹ),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(ملی واٹ),
						'other' => q({0} ملی واٹ),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q(مربع {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q(مربع {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q(کیوبک {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q(کیوبک {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(ماحول),
						'other' => q({0} ماحول),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(ماحول),
						'other' => q({0} ماحول),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(بارز),
						'other' => q({0} بار),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(بارز),
						'other' => q({0} بار),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ہیکٹو پاسکل),
						'other' => q({0} ہیکٹو پاسکل),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ہیکٹو پاسکل),
						'other' => q({0} ہیکٹو پاسکل),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(انچا مرکری),
						'other' => q({0} انچا مرکری),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(انچا مرکری),
						'other' => q({0} انچا مرکری),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(کلو پاسکلز),
						'other' => q({0} کلو پاسکل),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(کلو پاسکلز),
						'other' => q({0} کلو پاسکل),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(میگا پاسکلز),
						'other' => q({0} میگا پاسکل),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(میگا پاسکلز),
						'other' => q({0} میگا پاسکل),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(ملی بار),
						'other' => q({0} ملی بار),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(ملی بار),
						'other' => q({0} ملی بار),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(ملی میٹر مرکری),
						'other' => q({0} ملی میٹر مرکری),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(ملی میٹر مرکری),
						'other' => q({0} ملی میٹر مرکری),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(پاسکل),
						'other' => q({0} پاسکل),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(پاسکل),
						'other' => q({0} پاسکل),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(پاؤنڈز فی مربع انچا),
						'other' => q({0} پاؤنڈ فی مربع انچا),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(پاؤنڈز فی مربع انچا),
						'other' => q({0} پاؤنڈ فی مربع انچا),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(کلومیٹر فی گینٹہ),
						'other' => q({0} کلومیٹر فی گینٹہ),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(کلومیٹر فی گینٹہ),
						'other' => q({0} کلومیٹر فی گینٹہ),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(ناٹس),
						'other' => q({0} ناٹ),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(ناٹس),
						'other' => q({0} ناٹ),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'other' => q({0} میٹر فی سیکنڈ),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'other' => q({0} میٹر فی سیکنڈ),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q({0} میل فی گینٹہ),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q({0} میل فی گینٹہ),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'other' => q({0} ڈگری سیلسیس),
					},
					# Core Unit Identifier
					'celsius' => {
						'other' => q({0} ڈگری سیلسیس),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'other' => q({0} ڈگری فارن ہائیٹ),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'other' => q({0} ڈگری فارن ہائیٹ),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(کیلون),
						'other' => q({0} کیلون),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(کیلون),
						'other' => q({0} کیلون),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(نیوٹن میٹر),
						'other' => q({0} نیوٹن میٹر),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(نیوٹن میٹر),
						'other' => q({0} نیوٹن میٹر),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(پاؤنڈ فٹ),
						'other' => q({0} پاؤنڈ فٹ),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(پاؤنڈ فٹ),
						'other' => q({0} پاؤنڈ فٹ),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'other' => q({0} ایکڑ فٹ),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'other' => q({0} ایکڑ فٹ),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(بیرلز),
						'other' => q({0} بیرل),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(بیرلز),
						'other' => q({0} بیرل),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'other' => q({0} بوشیل),
					},
					# Core Unit Identifier
					'bushel' => {
						'other' => q({0} بوشیل),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'other' => q({0} سینٹی لیٹر),
					},
					# Core Unit Identifier
					'centiliter' => {
						'other' => q({0} سینٹی لیٹر),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'other' => q({0} کیوبک سینٹی میٹر),
						'per' => q({0} فی کیوبک سینٹی میٹر),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'other' => q({0} کیوبک سینٹی میٹر),
						'per' => q({0} فی کیوبک سینٹی میٹر),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'other' => q({0} کیوبک فٹ),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'other' => q({0} کیوبک فٹ),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'other' => q({0} کیوبک انچا),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'other' => q({0} کیوبک انچا),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(کیوبک کلو میٹر),
						'other' => q({0} کیوبک کلو میٹر),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(کیوبک کلو میٹر),
						'other' => q({0} کیوبک کلو میٹر),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(کیوبک میٹر),
						'other' => q({0} کیوبک میٹر),
						'per' => q({0} فی کیوبک میٹر),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(کیوبک میٹر),
						'other' => q({0} کیوبک میٹر),
						'per' => q({0} فی کیوبک میٹر),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'other' => q({0} کیوبک گز),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'other' => q({0} کیوبک گز),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} کپ),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} کپ),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(میٹرک کپ),
						'other' => q({0} میٹرک کپ),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(میٹرک کپ),
						'other' => q({0} میٹرک کپ),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'other' => q({0} ڈیسی لیٹر),
					},
					# Core Unit Identifier
					'deciliter' => {
						'other' => q({0} ڈیسی لیٹر),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(فلوئڈ اونس),
						'other' => q({0} فلوئڈ اونس),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(فلوئڈ اونس),
						'other' => q({0} فلوئڈ اونس),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(امپیریل فلوئڈ اونس),
						'other' => q({0} امپیریئل فلوئڈ اونس),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(امپیریل فلوئڈ اونس),
						'other' => q({0} امپیریئل فلوئڈ اونس),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(گیلن),
						'other' => q({0} گیلن),
						'per' => q({0} فی گیلن),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(گیلن),
						'other' => q({0} گیلن),
						'per' => q({0} فی گیلن),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(امپیریل گیلن),
						'other' => q({0} امپیریل گیلن),
						'per' => q({0} فی امپیریل گیلن),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(امپیریل گیلن),
						'other' => q({0} امپیریل گیلن),
						'per' => q({0} فی امپیریل گیلن),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ہیکٹو لیٹر),
						'other' => q({0} ہیکٹو لیٹر),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ہیکٹو لیٹر),
						'other' => q({0} ہیکٹو لیٹر),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(میگا لیٹر),
						'other' => q({0} میگا لیٹر),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(میگا لیٹر),
						'other' => q({0} میگا لیٹر),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ملی لیٹر),
						'other' => q({0} ملی لیٹر),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ملی لیٹر),
						'other' => q({0} ملی لیٹر),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(پائنٹ),
						'other' => q({0} پائنٹ),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(پائنٹ),
						'other' => q({0} پائنٹ),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(میٹرک پائنٹ),
						'other' => q({0} میٹرک پائنٹ),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(میٹرک پائنٹ),
						'other' => q({0} میٹرک پائنٹ),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(کوارٹ),
						'other' => q({0} کوارٹ),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(کوارٹ),
						'other' => q({0} کوارٹ),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ٹیبل سپون),
						'other' => q({0} ٹیبل سپون),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ٹیبل سپون),
						'other' => q({0} ٹیبل سپون),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ٹی سپون),
						'other' => q({0} ٹی سپون),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ٹی سپون),
						'other' => q({0} ٹی سپون),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(کیبی{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(کیبی{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(ڈیسی {0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ڈیسی {0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(پکو{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(پکو{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(فیمٹو{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(فیمٹو{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(اٹو{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(اٹو{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(سینٹی {0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(سینٹی {0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(زپٹو{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(زپٹو{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(ملی {0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(ملی {0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(نینو {0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(نینو {0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ڈیکا{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ڈیکا{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ٹیرا{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ٹیرا{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(پیٹا{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(پیٹا{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(اکسا{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(اکسا{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ہیکٹو{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ہیکٹو{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(زیٹا{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(زیٹا{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(یوٹا{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(یوٹا{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(کلو{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(کلو{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(میگا{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(میگا{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(گیگا {0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(گیگا {0}),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'other' => q({0} م س),
					},
					# Core Unit Identifier
					'microsecond' => {
						'other' => q({0} م س),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0} ملی س),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0} ملی س),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'other' => q({0} ن س),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'other' => q({0} ن س),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'other' => q({0} شمسی ر),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'other' => q({0} شمسی ر),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} گرام),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} گرام),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/hr),
						'other' => q({0}kph),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/hr),
						'other' => q({0}kph),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ڈائریکشن),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ڈائریکشن),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(ڈی۔ {0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ڈی۔ {0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(پی۔{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(پی۔{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(فے۔{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(فے۔{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(ا۔{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ا۔{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(سی۔ {0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(سی۔ {0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(ز۔{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(ز۔{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(یوکٹو{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(یوکٹو{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(می۔ {0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(می۔ {0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(نے۔ {0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(نے۔ {0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ڈے۔{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ڈے۔{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ٹے۔{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ٹے۔{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(پے۔{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(پے۔{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(ای۔{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ای۔{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ہے۔{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ہے۔{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(زے{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(زے{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(یو{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(یو{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(کی{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(کی{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(مے۔{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(مے۔{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(گی۔{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(گی۔{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(جی-فورس),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(جی-فورس),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(آرک منٹ),
						'other' => q({0} آرک منٹ),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(آرک منٹ),
						'other' => q({0} آرک منٹ),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(آرک سیکنڈ),
						'other' => q({0} آرک سیکنڈ),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(آرک سیکنڈ),
						'other' => q({0} آرک سیکنڈ),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(ڈگری),
						'other' => q({0} ڈگری),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(ڈگری),
						'other' => q({0} ڈگری),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ایکڑ),
						'other' => q({0} ایکڑ),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ایکڑ),
						'other' => q({0} ایکڑ),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(دُنامز),
						'other' => q({0} دُنام),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(دُنامز),
						'other' => q({0} دُنام),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ہیکٹر),
						'other' => q({0} ہیکٹر),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ہیکٹر),
						'other' => q({0} ہیکٹر),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(مربع فٹ),
						'other' => q({0} مربع فٹ),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(مربع فٹ),
						'other' => q({0} مربع فٹ),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(مربع انچا),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(مربع انچا),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(مربع میٹر),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(مربع میٹر),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(مربع میل),
						'other' => q({0} sq mi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(مربع میل),
						'other' => q({0} sq mi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(مربع گز),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(مربع گز),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(قیراط),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(قیراط),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ملی مول/لیٹر),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ملی مول/لیٹر),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(مول),
						'other' => q({0} مول),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(مول),
						'other' => q({0} مول),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(فیصد),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(فیصد),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(فی ملی),
						'other' => q({0} فی ملی),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(فی ملی),
						'other' => q({0} فی ملی),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(حصے/ملین),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(حصے/ملین),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(پرمرئیڈ),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(پرمرئیڈ),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(لیٹر/100 کلو میٹر),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(لیٹر/100 کلو میٹر),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miles/gal Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miles/gal Imp.),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(بائٹ),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(بائٹ),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kByte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kByte),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MByte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(پی بائٹ),
						'other' => q({0} پی بی),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(پی بائٹ),
						'other' => q({0} پی بی),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(قرن),
						'other' => q({0} قرن),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(قرن),
						'other' => q({0} قرن),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(دی),
						'other' => q({0} دی),
						'per' => q({0} فی دی),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(دی),
						'other' => q({0} دی),
						'per' => q({0} فی دی),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(دہائی),
						'other' => q({0} دہائی),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(دہائی),
						'other' => q({0} دہائی),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(گینٹہ),
						'other' => q({0} گینٹہ),
						'per' => q({0} فی گینٹہ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(گینٹہ),
						'other' => q({0} گینٹہ),
						'per' => q({0} فی گینٹہ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(مائیکرو سیکنڈ),
						'other' => q({0} مائیکرو سیکنڈ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(مائیکرو سیکنڈ),
						'other' => q({0} مائیکرو سیکنڈ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ملی سیکنڈ),
						'other' => q({0} ملی سیکنڈ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ملی سیکنڈ),
						'other' => q({0} ملی سیکنڈ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(میلٹ),
						'other' => q({0} میلٹ),
						'per' => q({0} فی میلٹ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(میلٹ),
						'other' => q({0} میلٹ),
						'per' => q({0} فی میلٹ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ما),
						'other' => q({0} ما),
						'per' => q(فی ما {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ما),
						'other' => q({0} ما),
						'per' => q(فی ما {0}),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(نینو سیکنڈز),
						'other' => q({0} نینو سیکنڈ),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(نینو سیکنڈز),
						'other' => q({0} نینو سیکنڈ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(سیکنڈ),
						'other' => q({0} سیکنڈ),
						'per' => q({0} فی سیکنڈ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(سیکنڈ),
						'other' => q({0} سیکنڈ),
						'per' => q({0} فی سیکنڈ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ہفتہ),
						'other' => q({0} ہفتہ),
						'per' => q({0} فی ہفتہ),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ہفتہ),
						'other' => q({0} ہفتہ),
						'per' => q({0} فی ہفتہ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(کال),
						'other' => q({0} کال),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(کال),
						'other' => q({0} کال),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(اوہم),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(اوہم),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(وولٹ),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(وولٹ),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(الیکٹرون وولٹ),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(الیکٹرون وولٹ),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(امریکی تھرم),
						'other' => q({0} امریکی تھرمز),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(امریکی تھرم),
						'other' => q({0} امریکی تھرمز),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(نیوٹن),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(نیوٹن),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(پاؤنڈ قوت),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(پاؤنڈ قوت),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(ڈاٹ),
						'other' => q({0} ڈاٹ),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(ڈاٹ),
						'other' => q({0} ڈاٹ),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(میگا پکسلز),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(میگا پکسلز),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(پکسلز),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(پکسلز),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(سینٹی میٹر),
						'other' => q({0} سینٹی میٹر),
						'per' => q({0}/سینٹی میٹر),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(سینٹی میٹر),
						'other' => q({0} سینٹی میٹر),
						'per' => q({0}/سینٹی میٹر),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(فیتھامز),
						'other' => q({0} فیتھامز),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(فیتھامز),
						'other' => q({0} فیتھامز),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(فٹ),
						'other' => q({0} فٹ),
						'per' => q({0}/فٹ),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(فٹ),
						'other' => q({0} فٹ),
						'per' => q({0}/فٹ),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(فرلانگ),
						'other' => q({0} فرلانگ),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(فرلانگ),
						'other' => q({0} فرلانگ),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(انچا),
						'other' => q({0} انچا),
						'per' => q({0}/انچا),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(انچا),
						'other' => q({0} انچا),
						'per' => q({0}/انچا),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(کلو میٹر),
						'other' => q({0} کلو میٹر),
						'per' => q({0} فی کلو میٹر),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(کلو میٹر),
						'other' => q({0} کلو میٹر),
						'per' => q({0} فی کلو میٹر),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(نوری کال),
						'other' => q({0} نوری کال),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(نوری کال),
						'other' => q({0} نوری کال),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(میٹر),
						'other' => q({0} میٹر),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(میٹر),
						'other' => q({0} میٹر),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(میل),
						'other' => q({0} میل),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(میل),
						'other' => q({0} میل),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(ملی میٹر),
						'other' => q({0} ملی میٹر),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(ملی میٹر),
						'other' => q({0} ملی میٹر),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(بحری میل),
						'other' => q({0} بحری میل),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(بحری میل),
						'other' => q({0} بحری میل),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(پارسیک),
						'other' => q({0} پارسیک),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(پارسیک),
						'other' => q({0} پارسیک),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(پیکو میٹر),
						'other' => q({0} پیکو میٹر),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(پیکو میٹر),
						'other' => q({0} پیکو میٹر),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(پوائنٹس),
						'other' => q({0} پوائنٹس),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(پوائنٹس),
						'other' => q({0} پوائنٹس),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(شمسی رداس),
						'other' => q({0} شمسی رداس),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(شمسی رداس),
						'other' => q({0} شمسی رداس),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(گز),
						'other' => q({0} گز),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(گز),
						'other' => q({0} گز),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(قیراط),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(قیراط),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(ڈالٹنز),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(ڈالٹنز),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(زمینی کمیتیں),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(زمینی کمیتیں),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(گرین),
						'other' => q({0} گرین),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(گرین),
						'other' => q({0} گرین),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(گرام),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(گرام),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(پاؤنڈ),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(پاؤنڈ),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(شمسی کمیتیں),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(شمسی کمیتیں),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ٹن),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ٹن),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'other' => q({0} کلو واٹ),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'other' => q({0} کلو واٹ),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(واٹ),
						'other' => q({0} واٹ),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(واٹ),
						'other' => q({0} واٹ),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(بار),
						'other' => q({0} بارز),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(بار),
						'other' => q({0} بارز),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(کلومیٹر/گھنٹہ),
						'other' => q({0} kph),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(کلومیٹر/گھنٹہ),
						'other' => q({0} kph),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(میٹر فی سیکنڈ),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(میٹر فی سیکنڈ),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(میل فی گینٹہ),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(میل فی گینٹہ),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(ڈگری سیلسیس),
						'other' => q({0}‎°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(ڈگری سیلسیس),
						'other' => q({0}‎°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(ڈگری فارن ہائیٹ),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(ڈگری فارن ہائیٹ),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ایکڑ فٹ),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ایکڑ فٹ),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(بیرل),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(بیرل),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(بوشیل),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(بوشیل),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(سینٹی لیٹر),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(سینٹی لیٹر),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(کیوبک سینٹی میٹر),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(کیوبک سینٹی میٹر),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(کیوبک فٹ),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(کیوبک فٹ),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(کیوبک انچا),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(کیوبک انچا),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(کیوبک میل),
						'other' => q({0} کیوبک میل),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(کیوبک میل),
						'other' => q({0} کیوبک میل),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(کیوبک گز),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(کیوبک گز),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(کپ),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(کپ),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(ڈیسی لیٹر),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(ڈیسی لیٹر),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ٹیگیل),
						'other' => q({0} ٹیگیل),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ٹیگیل),
						'other' => q({0} ٹیگیل),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(لیٹر),
						'other' => q({0} لیٹر),
						'per' => q({0} فی لیٹر),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(لیٹر),
						'other' => q({0} لیٹر),
						'per' => q({0} فی لیٹر),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(پینچ),
						'other' => q({0} پینچ),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(پینچ),
						'other' => q({0} پینچ),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qts),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ہاں|ہاں|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:نأ|نأ|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}،{1}),
				middle => q({0}،{1}),
				end => q({0} ،آں {1}),
				2 => q({0} آں {1}),
		} }
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arabext',
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AED' => {
			display_name => {
				'currency' => q(متحدہ عرب اماراتی درہم),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(افغان افغانی),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(البانیا سی لیک),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(آرمینیائی ڈرم),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(نیدر لینڈز انٹیلیئن گلڈر),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(انگولا سی کوانزا),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(ارجنٹائن پیسہ),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(آسٹریلین ڈالر),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(اروبن فلورِن),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(آذربائجانی منات),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(بوسنیا ہرزیگووینا کا قابل منتقلی نشان),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(باربیڈین ڈالر),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(بنگلہ دیشی ٹکا),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(بلغارین لیو),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(بحرینی دینار),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(برونڈیئن فرانک),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(برموڈا ڈالر),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(برونئی ڈالر),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(بولیوین بولیویانو),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(برازیلی ریئل),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(بہامانی ڈالر),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(بھوٹانی گُلٹرم),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(بوتسوانا سی پولا),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(بیلاروسی روبل),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(بیلیز ڈالر),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(کنیڈین ڈالر),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(کانگولیز فرانک),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(سوئس فرانکس),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(چلّین پیسہ),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(چینی یوآن \(آف شور\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(چینی یوآن),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(کولمبین پیسہ),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(کوسٹا ریکا کا کولن),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(کیوبا کا قابل منتقلی پیسو),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(کیوبا سی پیسو),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(کیپ ورڈی سی اسکیوڈو),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(چیک کرونا),
				'other' => q(چیک کروناز),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(جبوتی فرانک),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(ڈنمارک کرون),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(ڈومنیکن پیسو),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(الجیریائی دینار),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(مصری پاؤنڈ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(اریٹیریا سی نافکا),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(ایتھوپیائی بِرّ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(یورو),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(فجی سی ڈالر),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(فاکلینڈ آئلینڈز پونڈ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(برطانوی پاؤنڈ),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(جارجیائی لاری),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(گھانا سی سیڈی),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(جبل الطارق پونڈ),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(گامبیا سی ڈلاسی),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(گنی فرانک),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(گواٹے مالا کا کوئٹزل),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(گویانیز ڈالر),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(ھانگ کانگ ڈالر),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(ہونڈوران لیمپیرا),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(کروشین کونا),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(ہیتی کا گؤرڈی),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ہنگرین فورنٹ),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(انڈونیشین روپیہ),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(اسرائیلی نم شیکل),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(بھارتی روپیہ),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(عراقی دینار),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(ایرانی ریال),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(آئس لينڈی کرونا),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(جمائیکن ڈالر),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(اردنی دینار),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(جاپانی ین),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(کینیائی شلنگ),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(کرغستانی سوم),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(کمبوڈیائی ریئل),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(کوموریئن فرانک),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(شمالی کوریائی وون),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(جنوبی کوریائی وون),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(کویتی دینار),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(کیمین آئلینڈز ڈالر),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(قزاخستانی ٹینگ),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(لاؤشیائی کِپ),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(لبنانی پونڈ),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(سری لنکائی روپیہ),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(لائبریائی ڈالر),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(لیسوتو لوٹی),
				'other' => q(لیسوتو لوٹیس),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(لیبیائی دینار),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(مراکشی درہم),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(مالدووی لیو),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ملاگاسی اریاری),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(مقدونیائی دینار),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(میانمار کیاٹ),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(منگولیائی ٹگرِ),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(میکانیز پٹاکا),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(موریطانیائی اوگوئیا),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(ماریشس کا روپیہ),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(مالدیپ سی روفیہ),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(ملاوی کواچا),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(میکسیکی پیسہ),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ملیشیائی رنگِٹ),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(موزامبیقی میٹیکل),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(نامیبیائی ڈالر),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(نائیجیریائی نائرا),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(نکارا گوا کا کورڈوبا),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(ناروے کرون),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(نیپالی روپیہ),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(نیوزی لینڈ ڈالر),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(عمانی ریال),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(پنامہ کا بالبوآ),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(پیروویئن سول),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(پاپوآ نم گنی سی کینا),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(فلپائینی پیسہ),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(پاکستانی روپیہ),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(پولش زلوٹی),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(پیراگوئے سی گوآرنی),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(قطری ریال),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(رومانیائی لیو),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(سربین دینار),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(روسی روبل),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(روانڈا سی فرانک),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(سعودی ریال),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(سولومن آئلینڈز ڈالر),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(سشلی کا روپیہ),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(سوڈانی پاؤنڈ),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(سویڈن کرونا),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(سنگا پور ڈالر),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(سینٹ ہیلینا پاؤنڈ),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(سیئرا لیون لیون),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(سیئرا لیون لیون - 1964-2022),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(صومالی شلنگ),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(سورینامی ڈالر),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(جنوبی سوڈانی پاؤنڈ),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(ساؤ ٹومے آں پرنسپے ڈوبرا),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(شامی پونڈ),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(سوازی لیلانجینی),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(تھائی باہت),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(تاجکستانی سومونی),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(ترکمانستانی منات),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(تیونیسیائی دینار),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(ٹونگن پانگا),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(ترکی لیرا),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(ترینیداد آں ٹوباگو سی ڈالر),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(نیو تائیوان ڈالر),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(تنزانیائی شلنگ),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(یوکرینیائی ہریونیا),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(یوگانڈا شلنگ),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(امریکی ڈالر),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(یوروگویان پیسو),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(ازبکستانی سوم),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(وینزویلا بولیور),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(ویتنامی ڈانگ),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(وینوواتو واتو),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(ساموآ سی ٹالا),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(وسطی افریقی [CFA] فرانک),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(مشرقی کریبیا سی ڈالر),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(مغربی افریقی [CFA] فرانک),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP فرانک),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(نامعلوم پیس),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(یمنی ریال),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(جنوبی افریقی رانڈ),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(زامبیائی کواچا),
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
					wide => {
						nonleap => [
							'جنوری',
							'فروری',
							'مارچ',
							'اپریل',
							'مئ',
							'جون',
							'جولائی',
							'اگست',
							'ستمبر',
							'اکتوبر',
							'نومبر',
							'دسمبر'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ج',
							'ف',
							'م',
							'ا',
							'م',
							'ج',
							'ج',
							'ا',
							'س',
							'ا',
							'ن',
							'د'
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
					wide => {
						mon => 'دُوشیمے',
						tue => 'گھن آنگا',
						wed => 'چارشیمے',
						thu => 'پَئ شیمے',
						fri => 'شُوگار',
						sat => 'لَو آنگا',
						sun => 'ایکشیمے'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'د',
						tue => 'گ',
						wed => 'چ',
						thu => 'پ',
						fri => 'ش',
						sat => 'ل',
						sun => 'ا'
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
					abbreviated => {0 => 'اول ڇامای',
						1 => 'دوھیم ڇامای',
						2 => 'ڇوی ڇامای',
						3 => 'چوٹھوم ڇامای'
					},
					wide => {0 => 'اول ڇامای',
						1 => 'دھویم ڇامای',
						2 => 'ڇوی ڇامای',
						3 => 'چوٹھوم ڇامای'
					},
				},
				'stand-alone' => {
					wide => {0 => 'اول ڇامای',
						1 => 'دوھیم ڇامای',
						2 => 'ڇوی ڇامای',
						3 => 'چوٹھوم ڇامای'
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
					'am' => q{a},
					'pm' => q{p},
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
				'0' => 'ع-م',
				'1' => 'ع'
			},
			wide => {
				'0' => 'عیسٰیؑ ما مُش',
				'1' => 'عیسوی'
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
			'full' => q{EEEE، d MMMM، y G},
			'long' => q{d MMMM، y G},
			'medium' => q{d MMM، y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE، d MMMM، y},
			'long' => q{d MMMM، y},
			'medium' => q{d MMM، y},
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E، d MMM، y G},
			GyMMMd => q{d MMM، y G},
			MEd => q{E، d/M},
			MMMEd => q{E، d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E، d/M/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E، d MMM، y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM، y G},
			yyyyMd => q{d/M/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E، d MMM، y G},
			GyMMMd => q{d MMM، y G},
			MEd => q{E، d/M},
			MMMEd => q{E، d MMM},
			MMMMW => q{MMMM سی ہفتہ W},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E، d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E، d MMM، y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM، y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{Yسی w ہفتہ},
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
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E، d/M – E، d/M},
				d => q{E، d/M – E، d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E، d MMM – E، d MMM},
				d => q{E، d MMM – E، d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E، d/M/y – E، d/M/y G},
				d => q{E، d/M/y – E، d/M/y G},
				y => q{E، d/M/y – E، d/M/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E، d MMM – E، d MMM، y G},
				d => q{E، d MMM – E، d MMM، y G},
				y => q{E، d MMM، y – E، d MMM، y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM، y G},
				d => q{d–d MMM، y G},
				y => q{d MMM، y – d MMM، y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
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
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E، d/M – E، d/M},
				d => q{E، d/M – E، d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E، d MMM – E، d MMM},
				d => q{E، d MMM – E، d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E، d/M/y – E، d/M/y},
				d => q{E، d/M/y – E، d/M/y},
				y => q{E، d/M/y – E، d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E، d MMM – E، d MMM، y},
				d => q{E، d MMM – E، d MMM، y},
				y => q{E، d MMM، y – E، d MMM، y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM، y},
				d => q{d–d MMM y},
				y => q{d MMM، y – d MMM، y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} وَخ),
		regionFormat => q({0} دھات),
		regionFormat => q({0} معیاری وَخ),
		'Afghanistan' => {
			long => {
				'standard' => q#افغانستان سی وَخ#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#عابدجان#,
		},
		'Africa/Accra' => {
			exemplarCity => q#اکّرا#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#عدیس ابابا#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#الجیئرس#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#اسمارا#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#بماکو#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#بنگوئی#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#بنجول#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#بِساؤ#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#بلینٹائر#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#برازاویلے#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#بجمبرا#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#قاہرہ#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#کیسا بلانکا#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#سیوٹا#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#کونکری#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#ڈکار#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#دار السلام#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#جبوتی#,
		},
		'Africa/Douala' => {
			exemplarCity => q#ڈوآلا#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#العیون#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#فری ٹاؤن#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#گبرون#,
		},
		'Africa/Harare' => {
			exemplarCity => q#ہرارے#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#جوہانسبرگ#,
		},
		'Africa/Juba' => {
			exemplarCity => q#جوبا#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#کیمپالا#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#خرطوم#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#کگالی#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#کنشاسا#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#لاگوس#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#لبرے ویلے#,
		},
		'Africa/Lome' => {
			exemplarCity => q#لوم#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#لوانڈا#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#لوبمباشی#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#لیوساکا#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#ملابو#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#مپوٹو#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#مسیرو#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#مبابین#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#موگادیشو#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#مونروویا#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#نیروبی#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#اینجامینا#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#نیامی#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#نواکشوط#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#اؤگاڈؤگوو#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#پورٹو نووو#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#ساؤ ٹوم#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#ٹریپولی#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#تیونس#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#ونڈہوک#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#وسطی افریقہ ٹائم#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#مشرقی افریقہ ٹائم#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#جنوبی افریقہ سٹینڈرڈ ٹائم#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#مغربی افریقہ سمر ٹائم#,
				'generic' => q#مغربی افریقہ ٹائم#,
				'standard' => q#مغربی افریقہ سٹینڈرڈ ٹائم#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#الاسکا ڈے لائٹ ٹائم#,
				'generic' => q#الاسکا ٹائم#,
				'standard' => q#الاسکا اسٹینڈرڈ ٹائم#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#امیزون سی موسم گرما سی وَخ#,
				'generic' => q#امیزون ٹائم#,
				'standard' => q#ایمیزون سی معیاری وَخ#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#اداک#,
		},
		'America/Anchorage' => {
			exemplarCity => q#اینکریج#,
		},
		'America/Anguilla' => {
			exemplarCity => q#انگویلا#,
		},
		'America/Antigua' => {
			exemplarCity => q#انٹیگوا#,
		},
		'America/Araguaina' => {
			exemplarCity => q#اراگویانا#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#لا ریئوجا#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#ریو گالیگوس#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#سالٹا#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#سان جوآن#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#سان لوئس#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#ٹوکومین#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#اوشوآئیا#,
		},
		'America/Aruba' => {
			exemplarCity => q#اروبا#,
		},
		'America/Asuncion' => {
			exemplarCity => q#اسنسیئن#,
		},
		'America/Bahia' => {
			exemplarCity => q#باہیا#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#بہیا بندراز#,
		},
		'America/Barbados' => {
			exemplarCity => q#بارباڈوس#,
		},
		'America/Belem' => {
			exemplarCity => q#بیلیم#,
		},
		'America/Belize' => {
			exemplarCity => q#بیلائز#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#بلانک سبلون#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#بوآ وسٹا#,
		},
		'America/Bogota' => {
			exemplarCity => q#بگوٹا#,
		},
		'America/Boise' => {
			exemplarCity => q#بوائس#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#بیونس آئرس#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#کیمبرج سی کھاڑی#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#کیمپو گرینڈ#,
		},
		'America/Cancun' => {
			exemplarCity => q#کنکیون#,
		},
		'America/Caracas' => {
			exemplarCity => q#کراسیس#,
		},
		'America/Catamarca' => {
			exemplarCity => q#کیٹامارسی#,
		},
		'America/Cayenne' => {
			exemplarCity => q#سیئین#,
		},
		'America/Cayman' => {
			exemplarCity => q#کیمین#,
		},
		'America/Chicago' => {
			exemplarCity => q#شکاگو#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#چیہوآہوآ#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#اٹیکوکن#,
		},
		'America/Cordoba' => {
			exemplarCity => q#کورڈوبا#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#کوسٹا ریکا#,
		},
		'America/Creston' => {
			exemplarCity => q#کریسٹون#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#کوئیابا#,
		},
		'America/Curacao' => {
			exemplarCity => q#کیوراکاؤ#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#ڈنمارک شاون#,
		},
		'America/Dawson' => {
			exemplarCity => q#ڈاؤسن#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#ڈاؤسن کریک#,
		},
		'America/Denver' => {
			exemplarCity => q#ڈینور#,
		},
		'America/Detroit' => {
			exemplarCity => q#ڈیٹرائٹ#,
		},
		'America/Dominica' => {
			exemplarCity => q#ڈومنیکا#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ایڈمونٹن#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#ایرونیپ#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ال سلواڈور#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#فورٹ نیلسن#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#فورٹالیزا#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#گلیس سی کھاڑی#,
		},
		'America/Godthab' => {
			exemplarCity => q#نوک#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#گوس سی کھاڑی#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#عظیم ترک#,
		},
		'America/Grenada' => {
			exemplarCity => q#غرناطہ#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#گواڈیلوپ#,
		},
		'America/Guatemala' => {
			exemplarCity => q#گواٹے مالا#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#گوآیاکوئل#,
		},
		'America/Guyana' => {
			exemplarCity => q#گیانا#,
		},
		'America/Halifax' => {
			exemplarCity => q#ہیلیفیکس#,
		},
		'America/Havana' => {
			exemplarCity => q#ہوانا#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#ہرموسیلو#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#کنوکس، انڈیانا#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#مرینگو، انڈیانا#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#پیٹرزبرگ، انڈیانا#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#ٹیل سٹی، انڈیانا#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#ویوے، انڈیانا#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#ونسینیز، انڈیانا#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#وینامیک، انڈیانا#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#انڈیاناپولس#,
		},
		'America/Inuvik' => {
			exemplarCity => q#انووِک#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ایکالوئٹ#,
		},
		'America/Jamaica' => {
			exemplarCity => q#جمائیکا#,
		},
		'America/Jujuy' => {
			exemplarCity => q#جوجوئی#,
		},
		'America/Juneau' => {
			exemplarCity => q#جونیئو#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#مونٹیسیلو، کینٹوکی#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#کرالینڈیجک#,
		},
		'America/La_Paz' => {
			exemplarCity => q#لا پاز#,
		},
		'America/Lima' => {
			exemplarCity => q#لیما#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#لاس اینجلس#,
		},
		'America/Louisville' => {
			exemplarCity => q#لوئس ویلے#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#لوور پرنسس کوارٹر#,
		},
		'America/Maceio' => {
			exemplarCity => q#میسیئو#,
		},
		'America/Managua' => {
			exemplarCity => q#مناگوآ#,
		},
		'America/Manaus' => {
			exemplarCity => q#مناؤس#,
		},
		'America/Marigot' => {
			exemplarCity => q#میریگوٹ#,
		},
		'America/Martinique' => {
			exemplarCity => q#مارٹینک#,
		},
		'America/Matamoros' => {
			exemplarCity => q#میٹاموروس#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#میزٹلان#,
		},
		'America/Mendoza' => {
			exemplarCity => q#مینڈوزا#,
		},
		'America/Menominee' => {
			exemplarCity => q#مینومینی#,
		},
		'America/Merida' => {
			exemplarCity => q#میریڈا#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#میٹلا کاٹلا#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#میکسیکو سٹی#,
		},
		'America/Miquelon' => {
			exemplarCity => q#میکلیئون#,
		},
		'America/Moncton' => {
			exemplarCity => q#مونکٹن#,
		},
		'America/Monterrey' => {
			exemplarCity => q#مونٹیری#,
		},
		'America/Montevideo' => {
			exemplarCity => q#مونٹی ویڈیو#,
		},
		'America/Montserrat' => {
			exemplarCity => q#مونٹسیراٹ#,
		},
		'America/Nassau' => {
			exemplarCity => q#نساؤ#,
		},
		'America/New_York' => {
			exemplarCity => q#نیو یارک#,
		},
		'America/Nome' => {
			exemplarCity => q#نوم#,
		},
		'America/Noronha' => {
			exemplarCity => q#نورونہا#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#بیولاہ، شمالی ڈکوٹا#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#وسط، شمالی ڈکوٹا#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#نیو سلیم، شمالی ڈکوٹا#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#اوجیناگا#,
		},
		'America/Panama' => {
			exemplarCity => q#پنامہ#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#پراماریبو#,
		},
		'America/Phoenix' => {
			exemplarCity => q#فینکس#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#پورٹ او پرنس#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#پورٹ آف اسپین#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#پورٹو ویلہو#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#پیورٹو ریکو#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#پنٹا اریناس#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#رینکن انلیٹ#,
		},
		'America/Recife' => {
			exemplarCity => q#ریسائف#,
		},
		'America/Regina' => {
			exemplarCity => q#ریجینا#,
		},
		'America/Resolute' => {
			exemplarCity => q#ریزولیوٹ#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#ریئو برینکو#,
		},
		'America/Santarem' => {
			exemplarCity => q#سنٹارین#,
		},
		'America/Santiago' => {
			exemplarCity => q#سنٹیاگو#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#سانتو ڈومنگو#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#ساؤ پالو#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#اسکورز بائی سنڈ#,
		},
		'America/Sitka' => {
			exemplarCity => q#سیٹکا#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#سینٹ برتھیلمی#,
		},
		'America/St_Johns' => {
			exemplarCity => q#سینٹ جانز#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#سینٹ کٹس#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#سینٹ لوسیا#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#سینٹ تھامس#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#سینٹ ونسنٹ#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#سوِفٹ کرنٹ#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#ٹیگوسیگالپے#,
		},
		'America/Thule' => {
			exemplarCity => q#تھولو#,
		},
		'America/Tijuana' => {
			exemplarCity => q#تیجوآنا#,
		},
		'America/Toronto' => {
			exemplarCity => q#ٹورنٹو#,
		},
		'America/Tortola' => {
			exemplarCity => q#ٹورٹولا#,
		},
		'America/Vancouver' => {
			exemplarCity => q#وینکوور#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#وہائٹ ہارس#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#ونّیپیگ#,
		},
		'America/Yakutat' => {
			exemplarCity => q#یکوٹیٹ#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#سنٹرل ڈے لائٹ ٹائم#,
				'generic' => q#سنٹرل ٹائم#,
				'standard' => q#سنٹرل اسٹینڈرڈ ٹائم#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ایسٹرن ڈے لائٹ ٹائم#,
				'generic' => q#ایسٹرن ٹائم#,
				'standard' => q#ایسٹرن اسٹینڈرڈ ٹائم#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ماؤنٹین ڈے لائٹ ٹائم#,
				'generic' => q#ماؤنٹین ٹائم#,
				'standard' => q#ماؤنٹین اسٹینڈرڈ ٹائم#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#پیسفک ڈے لائٹ ٹائم#,
				'generic' => q#پیسفک ٹائم#,
				'standard' => q#پیسفک اسٹینڈرڈ ٹائم#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#کیسی#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#ڈیوس#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#ڈومونٹ ڈی ارویلے#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#میکواری#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#ماؤسن#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#میک مرڈو#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#پلمیر#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#روتھیرا#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#سیووا#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ٹرول#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#ووستوک#,
		},
		'Apia' => {
			long => {
				'daylight' => q#ایپیا ڈے لائٹ ٹائم#,
				'generic' => q#ایپیا ٹائم#,
				'standard' => q#ایپیا سٹینڈرڈ ٹائم#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#عرب ڈے لائٹ ٹائم#,
				'generic' => q#عرب سی وَخ#,
				'standard' => q#عرب سی معیاری وَخ#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#لانگ ایئر بین#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ارجنٹینا سی موسم گرما سی وَخ#,
				'generic' => q#ارجنٹینا سی وَخ#,
				'standard' => q#ارجنٹینا سی معیاری وَخ#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#مغربی ارجنٹینا سی موسم گرما سی وَخ#,
				'generic' => q#مغربی ارجنٹینا سی وَخ#,
				'standard' => q#مغربی ارجنٹینا سی معیاری وَخ#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#آرمینیا سی موسم گرما سی وَخ#,
				'generic' => q#آرمینیا سی وَخ#,
				'standard' => q#آرمینیا سی معیاری وَخ#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#عدن#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#الماٹی#,
		},
		'Asia/Amman' => {
			exemplarCity => q#امّان#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#انیدر#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#اکتاؤ#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#اکٹوب#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#اشغبت#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#آتیراؤ#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#بغداد#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#بحرین#,
		},
		'Asia/Baku' => {
			exemplarCity => q#باکو#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#بنکاک#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#برنال#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#بیروت#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#بشکیک#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#برونئی#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#کولسیتا#,
		},
		'Asia/Chita' => {
			exemplarCity => q#چیتا#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#کولمبو#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#دمشق#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ڈھاکہ#,
		},
		'Asia/Dili' => {
			exemplarCity => q#ڈلی#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#دبئی#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#دوشانبے#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#فاماگوسٹا#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#غزہ#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#ہیبرون#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#ہانگ سینگ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#ہووارڈ#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#ارکتسک#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#جکارتہ#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#جے پورہ#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#یروشلم#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#سیبل#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#کیمچٹکا#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#کراچی#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#سیٹھمنڈو#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#خندیگا#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#کریسنویارسک#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#کوالا لمپور#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#کیوچنگ#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#کویت#,
		},
		'Asia/Macau' => {
			exemplarCity => q#مسیؤ#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#میگیدن#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#مکاسر#,
		},
		'Asia/Manila' => {
			exemplarCity => q#منیلا#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#مسقط#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#نکوسیا#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#نوووکیوزنیسک#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#نوووسِبِرسک#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#اومسک#,
		},
		'Asia/Oral' => {
			exemplarCity => q#اورال#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#پنوم پن#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#پونٹیانک#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#پیونگ یانگ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#قطر#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#کوستانے#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#کیزیلورڈا#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#رنگون#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#ریاض#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#ہو چی منہ سٹی#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#سخالین#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#سمرقند#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#سیئول#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#شنگھائی#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#سنگاپور#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#سرہدنیکولیمسک#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#تائپے#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#تاشقند#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#طبلیسی#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#تہران#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#تھمپو#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#ٹوکیو#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#ٹامسک#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#اولان باتار#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#یورومکی#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#اوست-نیرا#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#وینٹیانا#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#ولادی ووستک#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#یکوتسک#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#یکاٹیرِنبرگ#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#یریوان#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#اٹلانٹک ڈے لائٹ ٹائم#,
				'generic' => q#اٹلانٹک ٹائم#,
				'standard' => q#اٹلانٹک اسٹینڈرڈ ٹائم#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#ازوریس#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#برمودا#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#کینری#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#کیپ ورڈی#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#فارو#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#مڈیئرا#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#ریکجاوک#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#جنوبی جارجیا#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#سینٹ ہیلینا#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#اسٹینلے#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#اڈیلائڈ#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#برسبین#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#بروکن ہِل#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#ڈارون#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#ایوکلا#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#ہوبارٹ#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#لِنڈمین#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#لارڈ ہووے#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#ملبورن#,
		},
		'Australia/Perth' => {
			exemplarCity => q#پرتھ#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#سڈنی#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#آسٹریلین سنٹرل ڈے لائٹ ٹائم#,
				'generic' => q#سنٹرل آسٹریلیا ٹائم#,
				'standard' => q#آسٹریلین سنٹرل اسٹینڈرڈ ٹائم#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#آسٹریلین سنٹرل ویسٹرن ڈے لائٹ ٹائم#,
				'generic' => q#آسٹریلین سنٹرل ویسٹرن ٹائم#,
				'standard' => q#آسٹریلین سنٹرل ویسٹرن اسٹینڈرڈ ٹائم#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#آسٹریلین ایسٹرن ڈے لائٹ ٹائم#,
				'generic' => q#ایسٹرن آسٹریلیا ٹائم#,
				'standard' => q#آسٹریلین ایسٹرن اسٹینڈرڈ ٹائم#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#آسٹریلین ویسٹرن ڈے لائٹ ٹائم#,
				'generic' => q#ویسٹرن آسٹریلیا ٹائم#,
				'standard' => q#سٹریلیا ویسٹرن اسٹینڈرڈ ٹائم#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#آذربائیجان سی موسم گرما سی وَخ#,
				'generic' => q#آذربائیجان سی وَخ#,
				'standard' => q#آذربائیجان سی معیاری وَخ#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#ازوریس سی موسم گرما سی وَخ#,
				'generic' => q#ازوریس سی وَخ#,
				'standard' => q#ازوریس سی معیاری وَخ#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#بنگلہ دیش سی موسم گرما سی وَخ#,
				'generic' => q#بنگلہ دیش سی وَخ#,
				'standard' => q#بنگلہ دیش سی معیاری وَخ#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#بھوٹان سی وَخ#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#بولیویا سی وَخ#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#برازیلیا سمر ٹائم#,
				'generic' => q#برازیلیا ٹائم#,
				'standard' => q#برازیلیا اسٹینڈرڈ ٹائم#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#برونئی دارالسلام ٹائم#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#کیپ ورڈی سمر ٹائم#,
				'generic' => q#کیپ ورڈی ٹائم#,
				'standard' => q#کیپ ورڈی سٹینڈرڈ ٹائم#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#چامورو سٹینڈرڈ ٹائم#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#چیتھم ڈے لائٹ ٹائم#,
				'generic' => q#چیتھم ٹائم#,
				'standard' => q#چیتھم اسٹینڈرڈ ٹائم#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#چلی سی موسم گرما سی وَخ#,
				'generic' => q#چلی سی وَخ#,
				'standard' => q#چلی سی معیاری وَخ#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#چینی ڈے لائٹ ٹائم#,
				'generic' => q#چین سی وَخ#,
				'standard' => q#چین سٹینڈرڈ ٹائم#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#کرسمس آئلینڈ ٹائم#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#کوکوس آئلینڈز ٹائم#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#کولمبیا سی موسم گرما سی وَخ#,
				'generic' => q#کولمبیا ٹائم#,
				'standard' => q#کولمبیا سی معیاری وَخ#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#کک آئلینڈز نصف سمر ٹائم#,
				'generic' => q#کک آئلینڈز ٹائم#,
				'standard' => q#کک آئلینڈز سٹینڈرڈ ٹائم#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#کیوبا ڈے لائٹ ٹائم#,
				'generic' => q#کیوبا ٹائم#,
				'standard' => q#کیوبا اسٹینڈرڈ ٹائم#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#ڈیوس ٹائم#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ڈومونٹ-ڈی’ارویلے ٹائم#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#مشرقی تیمور ٹائم#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ایسٹر آئلینڈ سی موسم گرما سی وَخ#,
				'generic' => q#ایسٹر آئلینڈ سی وَخ#,
				'standard' => q#ایسٹر آئلینڈ سی معیاری وَخ#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ایکواڈور سی وَخ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#کوآرڈینیٹڈ یونیورسل ٹائم#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#نامعلوم خار#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#ایمسٹرڈم#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#انڈورا#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#استراخان#,
		},
		'Europe/Athens' => {
			exemplarCity => q#ایتھنز#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#بلغراد#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#برلن#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#بریٹِسلاوا#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#برسلز#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#بخارسٹ#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#بڈاپسٹ#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#بزنجن#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#چیسیناؤ#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#کوپن ہیگن#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#ڈبلن#,
			long => {
				'daylight' => q#آئرش اسٹینڈرڈ ٹائم#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#جبل الطارق#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#گرنزی#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#ہیلسنکی#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#آئل آف مین#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#استنبول#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#جرسی#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#کالينينغراد#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#کیو#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#کیروف#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#لسبن#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#لیوبلیانا#,
		},
		'Europe/London' => {
			exemplarCity => q#لندن#,
			long => {
				'daylight' => q#برٹش سمر ٹائم#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#لگژمبرگ#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#میڈرڈ#,
		},
		'Europe/Malta' => {
			exemplarCity => q#مالٹا#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#میریہام#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#مِنسک#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#موناکو#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#ماسکو#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#اوسلو#,
		},
		'Europe/Paris' => {
			exemplarCity => q#پیرس#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#پوڈگورسیا#,
		},
		'Europe/Prague' => {
			exemplarCity => q#پراگ#,
		},
		'Europe/Riga' => {
			exemplarCity => q#ریگا#,
		},
		'Europe/Rome' => {
			exemplarCity => q#روم#,
		},
		'Europe/Samara' => {
			exemplarCity => q#سمارا#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#سان ماریانو#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#سراجیوو#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#سیراٹو#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#سمفروپول#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#اسکوپجے#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#صوفیہ#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#اسٹاک ہوم#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#ٹالن#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#ٹیرانی#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#الیانوسک#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#ویڈوز#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#واٹیکن#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#ویانا#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#وِلنیئس#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#وولگوگراد#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#وارسا#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#زیگریب#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#زیورخ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#وسطی یورپ سی موسم گرما سی وَخ#,
				'generic' => q#وسط یورپ سی وَخ#,
				'standard' => q#وسطی یورپ سی معیاری وَخ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#مشرقی یورپ سی موسم گرما سی وَخ#,
				'generic' => q#مشرقی یورپ سی وَخ#,
				'standard' => q#مشرقی یورپ سی معیاری وَخ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#بعید مشرقی یورپی وَخ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#مغربی یورپ سی موسم گرما سی وَخ#,
				'generic' => q#مغربی یورپ سی وَخ#,
				'standard' => q#مغربی یورپ سی معیاری وَخ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#فاک لینڈ آئلینڈز سی موسم گرما سی وَخ#,
				'generic' => q#فاک لینڈ آئلینڈز سی وَخ#,
				'standard' => q#فاک لینڈ آئلینڈز سی معیاری وَخ#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#فجی سمر ٹائم#,
				'generic' => q#فجی ٹائم#,
				'standard' => q#فجی سٹینڈرڈ ٹائم#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#فرینچ گیانا سی وَخ#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#فرینچ جنوبی آں انٹارکٹک ٹائم#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#گرین وچ سی اصل وَخ#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#گالاپاگوز سی وَخ#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#گیمبیئر ٹائم#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#جارجیا سی موسم گرما سی وَخ#,
				'generic' => q#جارجیا سی وَخ#,
				'standard' => q#جارجیا سی معیاری وَخ#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#جلبرٹ آئلینڈز ٹائم#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#مشرقی گرین لینڈ سی موسم گرما سی وَخ#,
				'generic' => q#مشرقی گرین لینڈ ٹائم#,
				'standard' => q#مشرقی گرین لینڈ اسٹینڈرڈ ٹائم#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#مغربی گرین لینڈ سی موسم گرما سی وَخ#,
				'generic' => q#مغربی گرین لینڈ ٹائم#,
				'standard' => q#مغربی گرین لینڈ اسٹینڈرڈ ٹائم#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#خلیج سی معیاری وَخ#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#گیانا سی وَخ#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#ہوائی الیوٹیئن ڈے لائٹ ٹائم#,
				'generic' => q#ہوائی الیوٹیئن ٹائم#,
				'standard' => q#ہوائی الیوٹیئن اسٹینڈرڈ ٹائم#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#ہانگ سینگ سمر ٹائم#,
				'generic' => q#ہانگ سینگ ٹائم#,
				'standard' => q#ہانگ سینگ سٹینڈرڈ ٹائم#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#ہووڈ سمر ٹائم#,
				'generic' => q#ہووڈ ٹائم#,
				'standard' => q#ہووڈ سٹینڈرڈ ٹائم#,
			},
		},
		'India' => {
			long => {
				'standard' => q#ہندوستان سی معیاری وَخ#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#انٹاناناریوو#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#چاگوس#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#کرسمس#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#کوکوس#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#کومورو#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#کرگیولین#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#ماہی#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#مالدیپ#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#ماریشس#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#مایوٹ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#ری یونین#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#بحر ہند ٹائم#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#ہند چین ٹائم#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#وسطی انڈونیشیا ٹائم#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#مشرقی انڈونیشیا ٹائم#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#مغربی انڈونیشیا ٹائم#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ایران ڈے لائٹ ٹائم#,
				'generic' => q#ایران سی وَخ#,
				'standard' => q#ایران سی معیاری وَخ#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ارکتسک سمر ٹائم#,
				'generic' => q#ارکتسک ٹائم#,
				'standard' => q#ارکتسک سٹینڈرڈ ٹائم#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#اسرائیل ڈے لائٹ ٹائم#,
				'generic' => q#اسرائیل سی وَخ#,
				'standard' => q#اسرائیل سی معیاری وَخ#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#جاپان ڈے لائٹ ٹائم#,
				'generic' => q#جاپان ٹائم#,
				'standard' => q#جاپان سٹینڈرڈ ٹائم#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#مشرقی قزاخستان سی وَخ#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#مغربی قزاخستان سی وَخ#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#کوریا ڈے لائٹ ٹائم#,
				'generic' => q#کوریا ٹائم#,
				'standard' => q#کوریا سٹینڈرڈ ٹائم#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#کوسرے ٹائم#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#کریسنویارسک سمر ٹائم#,
				'generic' => q#کریسنویارسک ٹائم#,
				'standard' => q#کرسنویارسک سٹینڈرڈ ٹائم#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#کرغستان سی وَخ#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#لائن آئلینڈز ٹائم#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#لارڈ ہووے ڈے لائٹ ٹائم#,
				'generic' => q#لارڈ ہووے ٹائم#,
				'standard' => q#لارڈ ہووے اسٹینڈرڈ ٹائم#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#میگیدن سمر ٹائم#,
				'generic' => q#میگیدن ٹائم#,
				'standard' => q#مگادان اسٹینڈرڈ ٹائم#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#ملیشیا ٹائم#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#مالدیپ سی وَخ#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#مارکیسس ٹائم#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#مارشل آئلینڈز ٹائم#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ماریشس سمر ٹائم#,
				'generic' => q#ماریشس ٹائم#,
				'standard' => q#ماریشس سٹینڈرڈ ٹائم#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#ماؤسن ٹائم#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#میکسیکن پیسفک ڈے لائٹ ٹائم#,
				'generic' => q#میکسیکن پیسفک ٹائم#,
				'standard' => q#میکسیکن پیسفک اسٹینڈرڈ ٹائم#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#یولان بیتور سمر ٹائم#,
				'generic' => q#یولان بیتور ٹائم#,
				'standard' => q#یولان بیتور سٹینڈرڈ ٹائم#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ماسکو سمر ٹائم#,
				'generic' => q#ماسکو ٹائم#,
				'standard' => q#ماسکو اسٹینڈرڈ ٹائم#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#میانمار ٹائم#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#ناؤرو ٹائم#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#نیپال سی وَخ#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#نیو کیلیڈونیا سمر ٹائم#,
				'generic' => q#نیو کیلیڈونیا ٹائم#,
				'standard' => q#نیو کیلیڈونیا سٹینڈرڈ ٹائم#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#نیوزی لینڈ ڈے لائٹ ٹائم#,
				'generic' => q#نیوزی لینڈ سی وَخ#,
				'standard' => q#نیوزی لینڈ سی معیاری وَخ#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#نیو فاؤنڈ لینڈ ڈے لائٹ ٹائم#,
				'generic' => q#نیو فاؤنڈ لینڈ ٹائم#,
				'standard' => q#نیو فاؤنڈ لینڈ اسٹینڈرڈ ٹائم#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#نیئو ٹائم#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#نارفوک آئلینڈ سی موسم گرما سی وَخ#,
				'generic' => q#نارفوک آئلینڈ سی وَخ#,
				'standard' => q#نارفوک آئلینڈ سی معیاری وَخ#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#فرنانڈو ڈی نورونہا سمر ٹائم#,
				'generic' => q#فرنانڈو ڈی نورنہا سی وَخ#,
				'standard' => q#فرنانڈو ڈی نورنہا سی معیاری وَخ#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#نوووسیبرسک سمر ٹائم#,
				'generic' => q#نوووسیبرسک ٹائم#,
				'standard' => q#نوووسیبرسک سٹینڈرڈ ٹائم#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#اومسک سمر ٹائم#,
				'generic' => q#اومسک ٹائم#,
				'standard' => q#اومسک سٹینڈرڈ ٹائم#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#اپیا#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#آکلینڈ#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#بوگینولے#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#چیتھم#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#ایسٹر#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#ایفیٹ#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#اینڈربری#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#فکاؤفو#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#فجی#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#فیونافیوٹی#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#گیلاپیگوس#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#گامبیئر#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#گواڈل کینال#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#گوآم#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#کریتیماٹی#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#کوسرائی#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#کواجیلین#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#مجورو#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#مارکیساس#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#مڈوے#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#ناؤرو#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#نیئو#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#نورفوک#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#نؤمیا#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#پاگو پاگو#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#پلاؤ#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#پٹکائرن#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#پونپیئی#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#پورٹ موریسبی#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#راروٹونگا#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#سائپین#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#تاہیتی#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#ٹراوا#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#ٹونگاٹاپو#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#چیوک#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#ویک#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#ولّیس#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#پاکستان سی موسم گرما سی وَخ#,
				'generic' => q#پاکستان سی وَخ#,
				'standard' => q#پاکستان سی معیاری وَخ#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#پلاؤ ٹائم#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#پاپوآ نیو گنی ٹائم#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#پیراگوئے سی موسم گرما سی وَخ#,
				'generic' => q#پیراگوئے سی وَخ#,
				'standard' => q#پیراگوئے سی معیاری وَخ#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#پیرو سی موسم گرما سی وَخ#,
				'generic' => q#پیرو سی وَخ#,
				'standard' => q#پیرو سی معیاری وَخ#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#فلپائن سمر ٹائم#,
				'generic' => q#فلپائن ٹائم#,
				'standard' => q#فلپائن سٹینڈرڈ ٹائم#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#فینکس آئلینڈز ٹائم#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#سینٹ پیئر آں مکلیئون ڈے لائٹ ٹائم#,
				'generic' => q#سینٹ پیئر آں مکلیئون ٹائم#,
				'standard' => q#سینٹ پیئر آں مکلیئون اسٹینڈرڈ ٹائم#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#پٹکائرن ٹائم#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#پوناپے ٹائم#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#پیانگ یانگ وَخ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#ری یونین ٹائم#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#روتھیرا سی وَخ#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#سخالین سمر ٹائم#,
				'generic' => q#سخالین ٹائم#,
				'standard' => q#سخالین سٹینڈرڈ ٹائم#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#ساموآ ڈے لائٹ ٹائم#,
				'generic' => q#ساموآ ٹائم#,
				'standard' => q#ساموآ سٹینڈرڈ ٹائم#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#سیشلیز ٹائم#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#سنگاپور سٹینڈرڈ ٹائم#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#سولمن آئلینڈز ٹائم#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#جنوبی جارجیا ٹائم#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#سورینام سی وَخ#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#سیووا ٹائم#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#تاہیتی ٹائم#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#تئی پیئی ڈے لائٹ ٹائم#,
				'generic' => q#تائی پیئی ٹائم#,
				'standard' => q#تائی پیئی اسٹینڈرڈ ٹائم#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#تاجکستان سی وَخ#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#ٹوکیلاؤ ٹائم#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#ٹونگا سمر ٹائم#,
				'generic' => q#ٹونگا ٹائم#,
				'standard' => q#ٹونگا سٹینڈرڈ ٹائم#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#چوک ٹائم#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ترکمانستان سی موسم گرما سی وَخ#,
				'generic' => q#ترکمانستان سی وَخ#,
				'standard' => q#ترکمانستان سی معیاری وَخ#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#ٹوالو ٹائم#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#یوروگوئے سی موسم گرما سی وَخ#,
				'generic' => q#یوروگوئے سی وَخ#,
				'standard' => q#یوروگوئے سی معیاری وَخ#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ازبکستان سی موسم گرما سی وَخ#,
				'generic' => q#ازبکستان سی وَخ#,
				'standard' => q#ازبکستان سی معیاری وَخ#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#وانوآٹو سمر ٹائم#,
				'generic' => q#وانوآٹو ٹائم#,
				'standard' => q#وانوآٹو سٹینڈرڈ ٹائم#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#وینزوئیلا سی وَخ#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ولادی ووستک سمر ٹائم#,
				'generic' => q#ولادی ووستک ٹائم#,
				'standard' => q#ولادی ووستک سٹینڈرڈ ٹائم#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#وولگوگراد سمر ٹائم#,
				'generic' => q#وولگوگراد ٹائم#,
				'standard' => q#وولگوگراد اسٹینڈرڈ ٹائم#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#ووسٹاک سی وَخ#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ویک آئلینڈ ٹائم#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#والیز اور فٹونا ٹائم#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#یکوتسک سمر ٹائم#,
				'generic' => q#یکوتسک ٹائم#,
				'standard' => q#یکوتسک اسٹینڈرڈ ٹائم#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#یکاٹیرِنبرگ سمر ٹائم#,
				'generic' => q#یکاٹیرِنبرگ ٹائم#,
				'standard' => q#یکاٹیرِنبرگ اسٹینڈرڈ ٹائم#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#یوکون ٹائم#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
