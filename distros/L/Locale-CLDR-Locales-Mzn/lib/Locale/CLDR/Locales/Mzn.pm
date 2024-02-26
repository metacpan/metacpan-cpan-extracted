=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mzn - Package for language Mazanderani

=cut

package Locale::CLDR::Locales::Mzn;
# This file auto generated from Data\common\main\mzn.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
				'ab' => 'آبخازی',
 				'af' => 'آفریکانس',
 				'agq' => 'آقم',
 				'ak' => 'آکان',
 				'am' => 'امهری',
 				'ar' => 'عربی',
 				'ar_001' => 'مدرن استاندارد عربی',
 				'arn' => 'ماپوچه',
 				'as' => 'آسامی',
 				'asa' => 'آسو',
 				'az' => 'آذری ِترکی',
 				'az@alt=short' => 'آذری',
 				'az_Arab' => 'جنوبی آذری ترکی',
 				'ba' => 'باشقیری',
 				'be' => 'بلاروسی',
 				'bem' => 'بمبایی',
 				'bez' => 'بنایی',
 				'bg' => 'بلغاری',
 				'bgn' => 'غربی بلوچی',
 				'bm' => 'بامبارایی',
 				'bn' => 'بنگالی',
 				'bo' => 'تبتی',
 				'br' => 'برِتونی',
 				'brx' => 'بدویی',
 				'bs' => 'بوسنیایی',
 				'ca' => 'کاتالونی',
 				'ce' => 'چچنی',
 				'cgg' => 'چیگا',
 				'chr' => 'چروکیایی',
 				'ckb' => 'میونی کوردی',
 				'co' => 'کورسیکان',
 				'cs' => 'چکی',
 				'cv' => 'چوواشی',
 				'cy' => 'ولزی',
 				'da' => 'دانمارکی',
 				'dav' => 'تایتا',
 				'de' => 'آلمانی',
 				'de_AT' => 'اتریش ِآلمانی',
 				'de_CH' => 'سوییس ِآلمانی',
 				'dje' => 'زارمایی',
 				'dsb' => 'پایین صربی',
 				'dua' => 'دوئالایی',
 				'dyo' => 'جولا-فونی',
 				'dz' => 'دزونگخا',
 				'ebu' => 'امبو',
 				'ee' => 'اوه‌یی',
 				'el' => 'یونانی',
 				'en' => 'انگلیسی',
 				'en_AU' => 'استرالیای ِانگلیسی',
 				'en_CA' => 'کانادای ِانگلیسی',
 				'en_GB' => 'بریتیش انگلیسی',
 				'en_GB@alt=short' => 'بریتانیای ِانگلیسی',
 				'en_US' => 'امریکن انگلیسی',
 				'en_US@alt=short' => 'آمریکای ِانگلیسی',
 				'eo' => 'اسپرانتو',
 				'es' => 'ایسپانیولی',
 				'es_419' => 'جنوبی آمریکای ِایسپانیولی',
 				'es_ES' => 'اروپای ِایسپانیولی',
 				'es_MX' => 'مکزیک ِایسپانیولی',
 				'et' => 'استونیایی',
 				'eu' => 'باسکی',
 				'fa' => 'فارسی',
 				'fi' => 'فینیش',
 				'fil' => 'فیلیپینو',
 				'fj' => 'فیجیایی',
 				'fo' => 'فارویی',
 				'fr' => 'فرانسوی',
 				'fr_CA' => 'کانادای ِفرانسوی',
 				'fr_CH' => 'سوییس ِفرانسوی',
 				'fy' => 'غربی فیریزی',
 				'ga' => 'ایریش',
 				'gag' => 'گاگائوزی',
 				'gl' => 'گالیک',
 				'gn' => 'گورانی',
 				'gsw' => 'سوییس آلمانی',
 				'gu' => 'گجراتی',
 				'guz' => 'گوسی',
 				'gv' => 'مانکس',
 				'ha' => 'هوسا',
 				'haw' => 'هاواییایی',
 				'he' => 'عبری',
 				'hi' => 'هندی',
 				'hr' => 'کرواتی',
 				'hsb' => 'بالایی صربی',
 				'ht' => 'هائتیایی',
 				'hu' => 'مجاری',
 				'hy' => 'ارمنی',
 				'id' => 'اندونزیایی',
 				'ig' => 'ایگبو',
 				'ii' => 'سیچوئان یی',
 				'is' => 'ایسلندی',
 				'it' => 'ایتالیایی',
 				'iu' => 'انوکتیتوت',
 				'ja' => 'جاپونی',
 				'jgo' => 'نگومبا',
 				'jmc' => 'ماچامه',
 				'jv' => 'جاوایی',
 				'ka' => 'گرجی',
 				'kab' => 'قبایلی',
 				'kam' => 'کامبایی',
 				'kde' => 'ماکونده',
 				'kea' => 'کیپ وُردی',
 				'khq' => 'کویرا چیینی',
 				'ki' => 'کیکویو',
 				'kk' => 'قزاقی',
 				'kl' => 'کالائلیسوت',
 				'kln' => 'کالنجین',
 				'km' => 'خمری',
 				'kn' => 'کانّادا',
 				'ko' => 'کُره‌یی',
 				'koi' => 'کومی-پرمیاک',
 				'kok' => 'کونکانی',
 				'ks' => 'کشمیری',
 				'ksb' => 'شامبالا',
 				'ksf' => 'بافیایی',
 				'ku' => 'کوردی',
 				'kw' => 'کورنیش',
 				'ky' => 'قرقیزی',
 				'la' => 'لاتین',
 				'lag' => 'لانگی',
 				'lb' => 'لوکزامبورگی',
 				'lg' => 'گاندا',
 				'lkt' => 'لاکوتا',
 				'ln' => 'لینگالا',
 				'lo' => 'لائویی',
 				'lrc' => 'شمالی لُری',
 				'lt' => 'لتونیایی',
 				'lu' => 'لوبا-کاتانگا',
 				'luo' => 'لوئو',
 				'luy' => 'لوییا',
 				'lv' => 'لاتویایی',
 				'mas' => 'ماسایی',
 				'mer' => 'مِرویی',
 				'mfe' => 'موریسین',
 				'mg' => 'مالاگاسی',
 				'mgh' => 'ماخوئا-میتو',
 				'mgo' => 'مِتاء',
 				'mi' => 'مائوری',
 				'mk' => 'مقدونی',
 				'ml' => 'مالایالام',
 				'mn' => 'مغولی',
 				'moh' => 'موهاک',
 				'mr' => 'ماراتی',
 				'ms' => 'مالایی',
 				'mt' => 'مالتی',
 				'mua' => 'موندانگ',
 				'my' => 'برمه‌یی',
 				'mzn' => 'مازرونی',
 				'naq' => 'ناما',
 				'nb' => 'نروژی بوکمال',
 				'nd' => 'شمالی ندبله',
 				'nds' => 'پایین آلمانی',
 				'nds_NL' => 'پایین ساکسونی',
 				'ne' => 'نپالی',
 				'nl' => 'هلندی',
 				'nl_BE' => 'فلمیش',
 				'nmg' => 'کوئاسیو',
 				'nn' => 'نروژی نینورسک',
 				'nqo' => 'نئکو',
 				'nus' => 'نوئر',
 				'nyn' => 'نیانکوله',
 				'om' => 'اورومو',
 				'or' => 'اوریا',
 				'pa' => 'پنجابی',
 				'pl' => 'لهستونی',
 				'ps' => 'پشتو',
 				'pt' => 'پرتغالی',
 				'pt_BR' => 'برزیل ِپرتغالی',
 				'pt_PT' => 'اروپای ِپرتغالی',
 				'qu' => 'قوئچوئا',
 				'quc' => 'کئیچه‌ئی',
 				'rm' => 'رومانش',
 				'rn' => 'روندی',
 				'ro' => 'رومانیایی',
 				'ro_MD' => 'مولداوی',
 				'rof' => 'رومبو',
 				'ru' => 'روسی',
 				'rw' => 'کنیاروآندایی',
 				'rwk' => 'روآیی',
 				'sa' => 'سانسکریت',
 				'saq' => 'سامبورو',
 				'sbp' => 'سانگوو',
 				'sd' => 'سندی',
 				'sdh' => 'جنوبی کردی',
 				'se' => 'شمالی سامی',
 				'seh' => 'سِنایی',
 				'ses' => 'کویرابورا سنی',
 				'sg' => 'سانگو',
 				'shi' => 'تاچلهیت',
 				'si' => 'سینهالا',
 				'sk' => 'اسلواکی',
 				'sl' => 'اسلوونیایی',
 				'sma' => 'جنوبی سامی',
 				'smj' => 'لوله سامی',
 				'smn' => 'ایناری سامی',
 				'sms' => 'سکولت سامی',
 				'sn' => 'شونا',
 				'so' => 'سومالیایی',
 				'sq' => 'آلبانیایی',
 				'sr' => 'صربی',
 				'su' => 'سوندانسی',
 				'sv' => 'سوئدی',
 				'sw' => 'سواحیلی',
 				'sw_CD' => 'کنگو سواحیلی',
 				'ta' => 'تامیلی',
 				'te' => 'تلوگویی',
 				'teo' => 'تسویی',
 				'tg' => 'تاجیکی',
 				'th' => 'تایی',
 				'ti' => 'تیگرینیایی',
 				'tk' => 'ترکمونی',
 				'to' => 'تونگانی',
 				'tr' => 'ترکی',
 				'tt' => 'تاتاری',
 				'twq' => 'تاساواقی',
 				'tzm' => 'میونی اطلس تامزیقی',
 				'ug' => 'ئوغوری',
 				'uk' => 'اوکراینی',
 				'und' => 'نشناسی‌یه زوون',
 				'ur' => 'اردو',
 				'uz' => 'ازبکی',
 				'vai' => 'وایی',
 				'vi' => 'ویتنامی',
 				'vun' => 'وونجویی',
 				'wbp' => 'والرپیری',
 				'wo' => 'وولفی',
 				'xh' => 'خوسا',
 				'xog' => 'سوگا',
 				'yo' => 'یوروبا',
 				'zgh' => 'مراکش ِاستاندارد ِتامازیقتی',
 				'zh' => 'چینی',
 				'zh_Hans' => 'ساده چینی',
 				'zh_Hant' => 'سنتی چینی',
 				'zu' => 'زولو',
 				'zxx' => 'این زوون بشناسی‌یه نیّه',

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
 			'Armn' => 'ارمنی',
 			'Beng' => 'بنگالی',
 			'Bopo' => 'بوپوموفو',
 			'Cyrl' => 'سیریلیک',
 			'Deva' => 'دیوانانگری',
 			'Ethi' => 'اتیوپیایی',
 			'Geor' => 'گرجی',
 			'Grek' => 'یونانی',
 			'Gujr' => 'گجراتی',
 			'Guru' => 'گورموخی',
 			'Hang' => 'هانگول',
 			'Hani' => 'هان',
 			'Hans' => 'ساده‌بَیی هان',
 			'Hant' => 'سنتی هانت',
 			'Hant@alt=stand-alone' => 'استاندارد ِسنتی هانت',
 			'Hebr' => 'عبری',
 			'Hira' => 'هیراگانا',
 			'Jpan' => 'جاپونی',
 			'Kana' => 'کاتاکانا',

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
			'001' => 'جهون',
 			'002' => 'آفریقا',
 			'003' => 'شمالی آمریکا',
 			'005' => 'جنوبی آمریکا',
 			'009' => 'اوقیانوسیه',
 			'011' => 'غربی آفریقا',
 			'013' => 'میونی آمریکا',
 			'014' => 'شرقی آفریقا',
 			'015' => 'شمالی ۀفریقا',
 			'017' => 'میونی آفریقا',
 			'018' => 'جنوبی آفریقا',
 			'019' => 'آمریکا',
 			'021' => 'شمالی امریکا',
 			'029' => 'کاراییب',
 			'030' => 'شرقی آسیا',
 			'034' => 'جنوبی آسیا',
 			'035' => 'آسیای ِجنوب‌شرقی‌وَر',
 			'039' => 'جنوبی اروپا',
 			'053' => 'اوسترالزی',
 			'054' => 'ملانزی',
 			'057' => 'میکرونزی منقطه',
 			'061' => 'پولی‌نزی',
 			'142' => 'آسیا',
 			'143' => 'میونی آسیا',
 			'145' => 'غربی آسیا',
 			'150' => 'اروپا',
 			'151' => 'شرقی اروپا',
 			'154' => 'شمالی اروپا',
 			'155' => 'غربی اروپا',
 			'419' => 'لاتین آمریکا',
 			'AC' => 'آسنسیون جزیره',
 			'AD' => 'آندورا',
 			'AE' => 'متحده عربی امارات',
 			'AF' => 'افغانستون',
 			'AG' => 'آنتیگوا و باربودا',
 			'AI' => 'آنگویلا',
 			'AL' => 'آلبانی',
 			'AM' => 'ارمنستون',
 			'AO' => 'آنگولا',
 			'AQ' => 'جنوبی یخ‌بزه قطب',
 			'AR' => 'آرژانتین',
 			'AS' => 'آمریکای ِساموآ',
 			'AT' => 'اتریش',
 			'AU' => 'استرالیا',
 			'AW' => 'آروبا',
 			'AX' => 'آلند جزیره',
 			'AZ' => 'آذربایجون',
 			'BA' => 'بوسنی و هرزگوین',
 			'BB' => 'باربادوس',
 			'BD' => 'بنگلادش',
 			'BE' => 'بلژیک',
 			'BF' => 'بورکینا فاسو',
 			'BG' => 'بلغارستون',
 			'BH' => 'بحرین',
 			'BI' => 'بوروندی',
 			'BJ' => 'بنین',
 			'BL' => 'سنت بارتلمی',
 			'BM' => 'برمودا',
 			'BN' => 'برونئی',
 			'BO' => 'بولیوی',
 			'BQ' => 'هلند ِکاراییبی جزایر',
 			'BR' => 'برزیل',
 			'BS' => 'باهاما',
 			'BT' => 'بوتان',
 			'BV' => 'بووت جزیره',
 			'BW' => 'بوتساوانا',
 			'BY' => 'بلاروس',
 			'BZ' => 'بلیز',
 			'CA' => 'کانادا',
 			'CC' => 'کوک (کیلینگ) جزایر',
 			'CD' => 'کنگو کینشاسا',
 			'CD@alt=variant' => 'کنگو (دموکراتیک جمهوری)',
 			'CF' => 'مرکزی آفریقای جمهوری',
 			'CG' => 'کنگو برازاویل',
 			'CG@alt=variant' => 'کنگو (جمهوری)',
 			'CH' => 'سوییس',
 			'CI' => 'عاج ِساحل',
 			'CI@alt=variant' => 'عاج ساحل',
 			'CK' => 'کوک جزایر',
 			'CL' => 'شیلی',
 			'CM' => 'کامرون',
 			'CN' => 'چین',
 			'CO' => 'کلمبیا',
 			'CP' => 'کلیپرتون جزیره',
 			'CR' => 'کاستاریکا',
 			'CU' => 'کوبا',
 			'CV' => 'کیپ ورد',
 			'CW' => 'کوراسائو',
 			'CX' => 'کریسمس جزیره',
 			'CY' => 'قبرس',
 			'CZ' => 'چک جمهوری',
 			'DE' => 'آلمان',
 			'DG' => 'دیگو گارسیا',
 			'DJ' => 'جیبوتی',
 			'DK' => 'دانمارک',
 			'DM' => 'دومنیکا',
 			'DO' => 'دومنیکن جمهوری',
 			'DZ' => 'الجزیره',
 			'EA' => 'سوتا و ملیله',
 			'EC' => 'اکوادر',
 			'EE' => 'استونی',
 			'EG' => 'مصر',
 			'EH' => 'غربی صحرا',
 			'ER' => 'اریتره',
 			'ES' => 'ایسپانیا',
 			'ET' => 'اتیوپی',
 			'EU' => 'اروپا اتحادیه',
 			'FI' => 'فنلاند',
 			'FJ' => 'فیجی',
 			'FK' => 'فالکلند جزیره‌ئون',
 			'FK@alt=variant' => 'فالکلند (مالویناس)',
 			'FM' => 'میکرونزی',
 			'FO' => 'فارو جزایر',
 			'FR' => 'فرانسه',
 			'GA' => 'گابون',
 			'GB' => 'بریتانیا',
 			'GD' => 'گرانادا',
 			'GE' => 'گرجستون',
 			'GF' => 'فرانسه‌ی ِگویان',
 			'GG' => 'گرنزی',
 			'GH' => 'غنا',
 			'GI' => 'جبل طارق',
 			'GL' => 'گرینلند',
 			'GM' => 'گامبیا',
 			'GN' => 'گینه',
 			'GP' => 'گوادلوپ',
 			'GQ' => 'استوایی گینه',
 			'GR' => 'یونان',
 			'GS' => 'جنوبی جورجیا و جنوبی ساندویچ جزایر',
 			'GT' => 'گواتمالا',
 			'GU' => 'گوئام',
 			'GW' => 'گینه بیسائو',
 			'GY' => 'گویان',
 			'HK' => 'هنگ کنگ',
 			'HK@alt=short' => 'هونگ کونگ',
 			'HM' => 'هارد و مک‌دونالد جزایر',
 			'HN' => 'هندوراس',
 			'HR' => 'کرواسی',
 			'HT' => 'هاییتی',
 			'HU' => 'مجارستون',
 			'IC' => 'قناری جزایر',
 			'ID' => 'اندونزی',
 			'IE' => 'ایرلند',
 			'IL' => 'ایسراییل',
 			'IM' => 'من ِجزیره',
 			'IN' => 'هند',
 			'IO' => 'بریتانیای هند ِاوقیانوس ِمناطق',
 			'IQ' => 'عراق',
 			'IR' => 'ایران',
 			'IS' => 'ایسلند',
 			'IT' => 'ایتالیا',
 			'JE' => 'جرسی',
 			'JM' => 'جاماییکا',
 			'JO' => 'اردن',
 			'JP' => 'جاپون',
 			'KE' => 'کنیا',
 			'KG' => 'قرقیزستون',
 			'KH' => 'کامبوج',
 			'KI' => 'کیریباتی',
 			'KM' => 'کومور',
 			'KN' => 'سنت کیتس و نویس',
 			'KP' => 'شمالی کُره',
 			'KR' => 'جنوبی کُره',
 			'KW' => 'کویت',
 			'KY' => 'کیمن جزیره‌ئون',
 			'KZ' => 'قزاقستون',
 			'LA' => 'لائوس',
 			'LB' => 'لبنان',
 			'LC' => 'سنت لوسیا',
 			'LI' => 'لیختن اشتاین',
 			'LK' => 'سریلانکا',
 			'LR' => 'لیبریا',
 			'LS' => 'لسوتو',
 			'LT' => 'لتونی',
 			'LU' => 'لوکزامبورگ',
 			'LV' => 'لاتویا',
 			'LY' => 'لیبی',
 			'MA' => 'مراکش',
 			'MC' => 'موناکو',
 			'MD' => 'مولداوی',
 			'ME' => 'مونته‌نگرو',
 			'MF' => 'سنت مارتین',
 			'MG' => 'ماداگاسکار',
 			'MH' => 'مارشال جزایر',
 			'ML' => 'مالی',
 			'MM' => 'میانمار',
 			'MN' => 'مغولستون',
 			'MO' => 'ماکائو (چین دله)',
 			'MO@alt=short' => 'ماکائو',
 			'MP' => 'شمالی ماریانا جزایر',
 			'MQ' => 'مارتینیک جزیره‌ئون',
 			'MR' => 'موریتانی',
 			'MS' => 'مونتسرات',
 			'MT' => 'مالت',
 			'MU' => 'مورى تيوس',
 			'MV' => 'مالدیو',
 			'MW' => 'مالاوی',
 			'MX' => 'مکزیک',
 			'MY' => 'مالزی',
 			'MZ' => 'موزامبیک',
 			'NA' => 'نامبیا',
 			'NC' => 'نیو کالیدونیا',
 			'NE' => 'نیجر',
 			'NF' => 'نورفولک جزیره',
 			'NG' => 'نیجریه',
 			'NI' => 'نیکاراگوئه',
 			'NL' => 'هلند',
 			'NO' => 'نروژ',
 			'NP' => 'نپال',
 			'NR' => 'نائورو',
 			'NU' => 'نیئو',
 			'NZ' => 'نیوزلند',
 			'OM' => 'عمان',
 			'PA' => 'پاناما',
 			'PE' => 'پرو',
 			'PF' => 'فرانسه‌ی پولی‌نزی',
 			'PG' => 'پاپوا نو گینه',
 			'PH' => 'فیلیپین',
 			'PK' => 'پاکستون',
 			'PL' => 'لهستون',
 			'PM' => 'سن پییر و میکلن',
 			'PN' => 'پیتکارین جزایر',
 			'PR' => 'پورتوریکو',
 			'PS' => 'فلسطین ِسرزمین',
 			'PS@alt=short' => 'فلسطین',
 			'PT' => 'پرتغال',
 			'PW' => 'پالائو',
 			'PY' => 'پاراگوئه',
 			'QA' => 'قطر',
 			'QO' => 'اوقیانوسیه‌ی ِپرت ِجائون',
 			'RE' => 'رئونیون',
 			'RO' => 'رومانی',
 			'RS' => 'صربستون',
 			'RU' => 'روسیه',
 			'RW' => 'روآندا',
 			'SA' => 'عربستون',
 			'SB' => 'سلیمون جزیره',
 			'SC' => 'سیشل',
 			'SD' => 'سودان',
 			'SE' => 'سوئد',
 			'SG' => 'سنگاپور',
 			'SH' => 'سنت هلنا',
 			'SI' => 'اسلوونی',
 			'SJ' => 'سوالبارد و يان ماين',
 			'SK' => 'اسلواکی',
 			'SL' => 'سیرالئون',
 			'SM' => 'سن مارینو',
 			'SN' => 'سنگال',
 			'SO' => 'سومالی',
 			'SR' => 'سورینام',
 			'SS' => 'جنوبی سودان',
 			'ST' => 'سائوتومه و پرینسیپ',
 			'SV' => 'السالوادور',
 			'SX' => 'سنت مارتن',
 			'SY' => 'سوریه',
 			'SZ' => 'سوازیلند',
 			'TA' => 'تریستان دا جونها',
 			'TC' => 'تورکس و کایکوس جزایر',
 			'TD' => 'چاد',
 			'TF' => 'فرانسه‌ی جنوبی مناطق',
 			'TG' => 'توگو',
 			'TH' => 'تایلند',
 			'TJ' => 'تاجیکستون',
 			'TK' => 'توکلائو',
 			'TL' => 'تیمور شرقی',
 			'TL@alt=variant' => 'شرقی تیمور',
 			'TM' => 'ترکمونستون',
 			'TN' => 'تونس',
 			'TO' => 'تونگا',
 			'TR' => 'ترکیه',
 			'TT' => 'ترینیداد و توباگو',
 			'TV' => 'تووالو',
 			'TW' => 'تایوان',
 			'TZ' => 'تانزانیا',
 			'UA' => 'اوکراین',
 			'UG' => 'اوگاندا',
 			'UM' => 'آمریکای پَرتِ‌پِلا جزیره‌ئون',
 			'US' => 'متحده ایالات',
 			'US@alt=short' => 'آمریکا متحده ایالات',
 			'UY' => 'اروگوئه',
 			'UZ' => 'ازبکستون',
 			'VA' => 'واتیکان',
 			'VC' => 'سنت وینسنت و گرنادین',
 			'VE' => 'ونزوئلا',
 			'VG' => 'بریتانیای ویرجین',
 			'VI' => 'آمریکای ویرجین',
 			'VN' => 'ویتنام',
 			'VU' => 'وانواتو',
 			'WF' => 'والیس و فوتونا',
 			'WS' => 'ساموآ',
 			'XK' => 'کوزوو',
 			'YE' => 'یمن',
 			'YT' => 'مایوت',
 			'ZA' => 'جنوبی افریقا',
 			'ZM' => 'زامبیا',
 			'ZW' => 'زیمبابوه',
 			'ZZ' => 'نامَیِّن منطقه',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{متریک},
 			'UK' => q{بریتانیایی},
 			'US' => q{آمریکایی},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'زوون: {0}',
 			'script' => 'اسکریپت: {0}',
 			'region' => 'منطقه: {0}',

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
			auxiliary => qr{[‌‍‎‏ َ ُ ِ ْ ٖ ٰ إ ك ى ي]},
			index => ['آ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ج', 'چ', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ه', 'و', 'ی'],
			main => qr{[ً ٌ ٍ ّ ٔ ء آ أ ؤ ئ ا ب پ ة ت ث ج چ ح خ د ذ ر ز ژ س ش ص ض ط ظ ع غ ف ق ک گ ل م ن ه و ی]},
			punctuation => qr{[\- ‐‑ ، ٫ ٬ ؛ \: ! ؟ . … ‹ › « » ( ) \[ \] * / \\]},
		};
	},
EOT
: sub {
		return { index => ['آ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ج', 'چ', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ه', 'و', 'ی'], };
},
);


has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{؟},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‹},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{›},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} ساعِت),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} ساعِت),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(دقیقه),
						'other' => q({0} دقیقه),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(دقیقه),
						'other' => q({0} دقیقه),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} ماه پیش),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} ماه پیش),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0} هفته پیش),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0} هفته پیش),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} سال پیش),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} سال پیش),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'other' => q({0} آمپر),
					},
					# Core Unit Identifier
					'ampere' => {
						'other' => q({0} آمپر),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'other' => q({0} میلی‌آمپر),
					},
					# Core Unit Identifier
					'milliampere' => {
						'other' => q({0} میلی‌آمپر),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(اُهم),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(اُهم),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(وُلت),
						'other' => q({0} ولت),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(وُلت),
						'other' => q({0} ولت),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'other' => q({0} کالری),
					},
					# Core Unit Identifier
					'calorie' => {
						'other' => q({0} کالری),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'other' => q({0} کالری),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'other' => q({0} کالری),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'other' => q({0} ژول),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0} ژول),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'other' => q({0} کیلوکالری),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'other' => q({0} کیلوکالری),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0} کیلوژول),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0} کیلوژول),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(کیلووات بر ساعت),
						'other' => q({0} کیلووات-ساعت),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(کیلووات بر ساعت),
						'other' => q({0} کیلووات-ساعت),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'other' => q({0} گیگاهرتز),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'other' => q({0} گیگاهرتز),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'other' => q({0} هرتز),
					},
					# Core Unit Identifier
					'hertz' => {
						'other' => q({0} هرتز),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'other' => q({0} کیلوهرتز),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'other' => q({0} کیلوهرتز),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'other' => q({0} مگاهرتز),
					},
					# Core Unit Identifier
					'megahertz' => {
						'other' => q({0} مگاهرتز),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} گرم),
						'per' => q({0} هر گرم دله),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} گرم),
						'per' => q({0} هر گرم دله),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'other' => q({0} کیلوگرم),
						'per' => q({0} هر کیلوگرم دله),
					},
					# Core Unit Identifier
					'kilogram' => {
						'other' => q({0} کیلوگرم),
						'per' => q({0} هر کیلوگرم دله),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'other' => q({0} میکروگرم),
					},
					# Core Unit Identifier
					'microgram' => {
						'other' => q({0} میکروگرم),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'other' => q({0} میلی‌گرم),
					},
					# Core Unit Identifier
					'milligram' => {
						'other' => q({0} میلی‌گرم),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'other' => q({0} اونس),
						'per' => q({0} هر اونس دله),
					},
					# Core Unit Identifier
					'ounce' => {
						'other' => q({0} اونس),
						'per' => q({0} هر اونس دله),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'other' => q({0} تروی اونس),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'other' => q({0} تروی اونس),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'other' => q({0} پوند),
						'per' => q({0} هر پوند دله),
					},
					# Core Unit Identifier
					'pound' => {
						'other' => q({0} پوند),
						'per' => q({0} هر پوند دله),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'other' => q({0} تُن),
					},
					# Core Unit Identifier
					'ton' => {
						'other' => q({0} تُن),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(متریک تُن),
						'other' => q({0} متریک تُن),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(متریک تُن),
						'other' => q({0} متریک تُن),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'other' => q({0} گیگاوات),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'other' => q({0} گیگاوات),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'other' => q({0} اسب بخار),
					},
					# Core Unit Identifier
					'horsepower' => {
						'other' => q({0} اسب بخار),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'other' => q({0} کیلووات),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'other' => q({0} کیلووات),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'other' => q({0} مگاوات),
					},
					# Core Unit Identifier
					'megawatt' => {
						'other' => q({0} مگاوات),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'other' => q({0} میلی‌وات),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'other' => q({0} میلی‌وات),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0} وات),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0} وات),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'other' => q({0} کیلومتر بر ساعت),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'other' => q({0} کیلومتر بر ساعت),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'other' => q({0} گره),
					},
					# Core Unit Identifier
					'knot' => {
						'other' => q({0} گره),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'other' => q({0} متر بر ثانیه),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'other' => q({0} متر بر ثانیه),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q({0} مایل بر ساعت),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q({0} مایل بر ساعت),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(درجه سلسیوس),
						'other' => q({0} درجه سلسیوس),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(درجه سلسیوس),
						'other' => q({0} درجه سلسیوس),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(فارنهایت),
						'other' => q({0} فارنهایت),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(فارنهایت),
						'other' => q({0} فارنهایت),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(کلوین),
						'other' => q({0} کلوین),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(کلوین),
						'other' => q({0} کلوین),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(آکر-فوت),
						'other' => q({0} آکر-فوت),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(آکر-فوت),
						'other' => q({0} آکر-فوت),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'other' => q({0} سانتی‌لیتر),
					},
					# Core Unit Identifier
					'centiliter' => {
						'other' => q({0} سانتی‌لیتر),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(سانتی‌متر مکعب),
						'other' => q({0} سانتی‌متر مکعب),
						'per' => q({0} هر سانتی‌متر مکعب دله),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(سانتی‌متر مکعب),
						'other' => q({0} سانتی‌متر مکعب),
						'per' => q({0} هر سانتی‌متر مکعب دله),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(فوت مکعب),
						'other' => q({0} فوت مکعب),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(فوت مکعب),
						'other' => q({0} فوت مکعب),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(اینچ مکعب),
						'other' => q({0} اینچ مکعب),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(اینچ مکعب),
						'other' => q({0} اینچ مکعب),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(کیلومتر مکعب),
						'other' => q({0} کیلومتر مکعب),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(کیلومتر مکعب),
						'other' => q({0} کیلومتر مکعب),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(متر مکعب),
						'other' => q({0} متر مکعب),
						'per' => q({0} هر متر مکعب دله),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(متر مکعب),
						'other' => q({0} متر مکعب),
						'per' => q({0} هر متر مکعب دله),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(مایل مکعب),
						'other' => q({0} مایل مکعب),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(مایل مکعب),
						'other' => q({0} مایل مکعب),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(یارد مکعب),
						'other' => q({0} یارد مکعب),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(یارد مکعب),
						'other' => q({0} یارد مکعب),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} دَییل),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} دَییل),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(متریک دَییل),
						'other' => q({0} متریک دَییل),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(متریک دَییل),
						'other' => q({0} متریک دَییل),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'other' => q({0} دسی‌لیتر),
					},
					# Core Unit Identifier
					'deciliter' => {
						'other' => q({0} دسی‌لیتر),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'other' => q({0} فلوید اونس),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'other' => q({0} فلوید اونس),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'other' => q({0} گالون),
						'per' => q({0} هر گالون دله),
					},
					# Core Unit Identifier
					'gallon' => {
						'other' => q({0} گالون),
						'per' => q({0} هر گالون دله),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'other' => q({0} هکتولیتر),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'other' => q({0} هکتولیتر),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'per' => q({0} هر لیتر دله),
					},
					# Core Unit Identifier
					'liter' => {
						'per' => q({0} هر لیتر دله),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'other' => q({0} مگالیتر),
					},
					# Core Unit Identifier
					'megaliter' => {
						'other' => q({0} مگالیتر),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'other' => q({0} میلی‌لیتر),
					},
					# Core Unit Identifier
					'milliliter' => {
						'other' => q({0} میلی‌لیتر),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'other' => q({0} پاینت),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q({0} پاینت),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'other' => q({0} متریک پاینت),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'other' => q({0} متریک پاینت),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'other' => q({0} ربع),
					},
					# Core Unit Identifier
					'quart' => {
						'other' => q({0} ربع),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'other' => q({0}تا کال),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'other' => q({0}تا کال),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'other' => q({0} چایی‌خاری کچه),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'other' => q({0} چایی‌خاری کچه),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} ساعِت),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} ساعِت),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} l),
					},
				},
				'short' => {
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
					'digital-bit' => {
						'name' => q(بیت),
						'other' => q({0} بیت),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(بیت),
						'other' => q({0} بیت),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(بایت),
						'other' => q({0} بایت),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(بایت),
						'other' => q({0} بایت),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(گیگابیت),
						'other' => q({0} گیگابیت),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(گیگابیت),
						'other' => q({0} گیگابیت),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(گیگابایت),
						'other' => q({0} گیگابایت),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(گیگابایت),
						'other' => q({0} گیگابایت),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(کیلوبیت),
						'other' => q({0} کیلوبیت),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(کیلوبیت),
						'other' => q({0} کیلوبیت),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(کیلوبایت),
						'other' => q({0} کیلوبایت),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(کیلوبایت),
						'other' => q({0} کیلوبایت),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(مگابیت),
						'other' => q({0} مگابیت),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(مگابیت),
						'other' => q({0} مگابیت),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(مگابایت),
						'other' => q({0} مگابایت),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(مگابایت),
						'other' => q({0} مگابایت),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(ترابیت),
						'other' => q({0} ترابیت),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(ترابیت),
						'other' => q({0} ترابیت),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ترابایت),
						'other' => q({0} ترابایت),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ترابایت),
						'other' => q({0} ترابایت),
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
						'name' => q(روز),
						'other' => q({0} روز),
						'per' => q({0} روز),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(روز),
						'other' => q({0} روز),
						'per' => q({0} روز),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ساعت),
						'per' => q({0} ساعِت),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ساعت),
						'per' => q({0} ساعِت),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(میکروثانیه),
						'other' => q({0} میکروثانیه),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(میکروثانیه),
						'other' => q({0} میکروثانیه),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(میلی‌ثانیه),
						'other' => q({0} میلی‌ثانیه),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(میلی‌ثانیه),
						'other' => q({0} میلی‌ثانیه),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(دَقه),
						'other' => q({0} دَقه),
						'per' => q({0} دَقه),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(دَقه),
						'other' => q({0} دَقه),
						'per' => q({0} دَقه),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
						'per' => q({0} ماه),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
						'per' => q({0} ماه),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(نانوثانیه),
						'other' => q({0} نانوثانیه),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(نانوثانیه),
						'other' => q({0} نانوثانیه),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ثانیه),
						'other' => q({0} ثانیه),
						'per' => q({0} ثانیه),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ثانیه),
						'other' => q({0} ثانیه),
						'per' => q({0} ثانیه),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(هفته),
						'other' => q({0} هفته),
						'per' => q({0} هفته),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(هفته),
						'other' => q({0} هفته),
						'per' => q({0} هفته),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(سال),
						'other' => q({0} سال),
						'per' => q({0} سال),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(سال),
						'other' => q({0} سال),
						'per' => q({0} سال),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(آمپر),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(آمپر),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(میلی‌آمپر),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(میلی‌آمپر),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(اهم),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(اهم),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(ولت),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(ولت),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(کالری),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(کالری),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(کالری),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(کالری),
						'other' => q({0} Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ژول),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ژول),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(کیلوکالری),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(کیلوکالری),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(کیلوژول),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(کیلوژول),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(کیلووات-ساعت),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(کیلووات-ساعت),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(گیگاهرتز),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(گیگاهرتز),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(هرتز),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(هرتز),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(کیلوهرتز),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(کیلوهرتز),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(مگاهرتز),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(مگاهرتز),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(قیراط),
						'other' => q({0} قیراط),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(قیراط),
						'other' => q({0} قیراط),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(گرم),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(گرم),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(کیلوگرم),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(کیلوگرم),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(میکروگرم),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(میکروگرم),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(میلی‌گرم),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(میلی‌گرم),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(اونس),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(اونس),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(تروی اونس),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(تروی اونس),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(پوند),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(پوند),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(تُن),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(تُن),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(گیگاوات),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(گیگاوات),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(اسب‌بخار),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(اسب‌بخار),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(کیلووات),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(کیلووات),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(مگاوات),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(مگاوات),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(میلی‌وات),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(میلی‌وات),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(وات),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(وات),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(گره),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(گره),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(متر بر ثانیه),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(متر بر ثانیه),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(مایل بر ساعت),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(مایل بر ساعت),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(آکرفوت),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(آکرفوت),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(سانتی‌لیتر),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(سانتی‌لیتر),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(دَییل),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(دَییل),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(دسی‌لیتر),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(دسی‌لیتر),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(فلوید اونس),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(فلوید اونس),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(گالون),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(گالون),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(هکتولیتر),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(هکتولیتر),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(لیتر),
						'other' => q({0} لیتر),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(لیتر),
						'other' => q({0} لیتر),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(مگالیتر),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(مگالیتر),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(میلی‌لیتر),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(میلی‌لیتر),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(پاینت),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(پاینت),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(متریک پاینت),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(متریک پاینت),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ربع),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ربع),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(کال),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(کال),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(چایی‌خاری کچه),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(چایی‌خاری کچه),
					},
				},
			} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arabext',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arabext',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arabext' => {
			'timeSeparator' => q(:),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AED' => {
			display_name => {
				'currency' => q(متحده عربی امارات ِدرهم),
				'other' => q(امارات ِدرهم),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(افغانستون ِافغانی),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(آلبانی ِلک),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(ارمنستون درهم),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(هلند ِآنتیل ِجزایر ِگویلدر),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(آنگولای ِکوانزا),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(آرژانتین ِپزو),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(آروبای ِفلورن),
				'other' => q(آروبای فلورن),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(آذربایجون ِمنات),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(بوسنی و هرزگوین ِتبدیل‌بَیی مارک),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(باربادوس ِدولار),
				'other' => q(باربادوس دلار),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(بنگلادش ِتاکا),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(بلغارستون ِلیوا),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(بحرین ِدینار),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(بوروندی ِفرانک),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(برمودای ِدولار),
				'other' => q(برمودای ِدلار),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(برونئی ِدولار),
				'other' => q(برونئی دلار),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(بولیوی ِبولیویانو),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(برزیل ِرئال),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(باهامای ِدولار),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(بوتان ِنگولتروم),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(بوتساوانای ِپولا),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(بلاروس ِروبل),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(بلاروس ِروبل \(۲۰۰۰–۲۰۱۶\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(بلیز ِدولار),
				'other' => q(بلیز دلار),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(کانادای ِدولار),
				'other' => q(کانادای ِدلار),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(کنگوی ِفرانک),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(سوییس ِفرانک),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(شیلی ِپزو),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(چین ِیوآن),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(کلمبیای ِپزو),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(کاستاریکای ِکولون),
				'other' => q(کاستاریکا کولون),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(کوبای ِتبدیل‌بَیی پزو),
				'other' => q(کوبای تبدیل‌بَیی پزو),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(کوبای ِپزو),
				'other' => q(کوبای پزو),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(عاج ِساحل ِایسکودو),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(چک ِکرون),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(جیبوتی ِفرانک),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(دانمارک ِکورن),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(دومینیکن ِپزو),
				'other' => q(دومینیکن پزو),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(الجزیره‌ی ِدینار),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(مصر ِپوند),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(اریتره‌ی ِناکفا),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(اتیوپی ِبیر),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(یورو),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(فالکلند ِجزایر ِپوند),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(بریتانیای ِپوند),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(گرجستون ِلاری),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(غنای ِسدی),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(جبل‌طارق ِپوند),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(گامبیای ِدالاسی),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(گینه‌ی ِفرانک),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(گواتمالا کتزال),
				'other' => q(گواتمالای ِکتزال),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(گویان ِدولار),
				'other' => q(گویان دلار),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(هونگ کونگ ِدولار),
				'other' => q(هنگ کنگ ِدلار),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(هندوراس ِلمپیرا),
				'other' => q(هندوراس لمپیرا),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(کرواسی ِکونا),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(هائیتی ِگورد),
				'other' => q(هاییتی گورد),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(مجارستون ِفروینت),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(اندونزی ِروپیه),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(اسراییل ِنو شِکِل),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(هند ِروپیه),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(عراق ِدینار),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(ایران ریال),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(ایسلند کرونا),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(جاماییکای ِدولار),
				'other' => q(جاماییکا دلار),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(اردن ِدینار),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(جاپون ِین),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(کنیای ِشیلینگ),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(قرقیزستون ِسام),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(کامبوج ِریل),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(کامرون ِفرانک),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(شمالی کره‌ی ِوون),
				'other' => q(شمالی کره وون),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(جنوبی کُره‌ی ِوون),
				'other' => q(جنوبی کره وون),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(کویت ِدینار),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(کایمن جزیره‌ی ِدولار),
				'other' => q(کایمن جزیره‌ی دلار),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(قراقستون ِتنگ),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(لائوس ِکیپ),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(لبنان ِپوند),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(سریلانکا روپیه),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(لیبریای ِدولار),
				'other' => q(لیبریا دلار),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(لیبی ِدینار),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(مراکش ِدرهم),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(مولداوی ِلئو),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ماداگاسکار ِآریاری),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(مقدونیه‌ی ِدینار),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(میانمار ِکیات),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(مغلستون ِتوگریک),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(ماکائو ِپاتاجا),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(موریتانی ِاوگوئیا \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(موریتانی ِاوگوئیا),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(موریتیان ِروپیه),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(مالدیو ِروفیا),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(مالاوی ِکواچا),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(مکزیک ِپزو),
				'other' => q(مکزیک پزو),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(مالزی ِرینگیت),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(موزامبیک متیکال),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(نامبیای ِدولار),
				'other' => q(نامبیای ِدلار),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(نیجریه‌ی ِنیارا),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(نیکاراگوئه‌ی ِکوردوبا),
				'other' => q(نیکاراگوئه کوردوبا),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(نروژ ِکرون),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(نپال ِروپیه),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(عمان ِریال),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(پانامای ِبالبوا),
				'other' => q(پانامای بالبوا),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(پروی ِسول),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(فیلیپین ِپزو),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(پاکستون روپیه),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(لهستون ِزلوتی),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(پاراگوئه‌ی ِگوارانی),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(قطر ِریال),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(رومانی ِلئو),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(صربستون ِدینار),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(روسیه‌ی ِروبل),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(روآندای ِفرانک),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(عربستون ِریال),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(سیشل ِروپیه),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(سودان ِپوند),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(سوئد ِکرون),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(سنگاپور ِدلار),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(سنت هلنای ِپوند),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(سیرالئون ِلئون),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(سیرالئون ِلئون - 1964-2022),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(سومالی ِشیلینگ),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(سورینام ِدولار),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(جنوبی سودان ِپوند),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(سائوتومه و پرینسیپ ِدوبرا \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(سائوتومه و پرینسیپ ِدوبرا),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(سوریه‌ی ِپوند),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(سوازیلند ِلیلانجنی),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(تایلند ِبات),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(تاجیکستون ِسامانی),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(ترکمنستون ِمنات),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(تونس ِدینار),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(ترکیه‌ی ِلیره),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(ترینیداد و توباگوی ِدولار),
				'other' => q(ترینیداد و توباگوی ِدلار),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(جدید ِتایوان ِدولار),
				'other' => q(تایوان دلار),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(تانزانیای ِشیلینگ),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(اکراین ِگریونا),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(اوگاندای ِشیلینگ),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(آمریکای ِدولار),
				'other' => q(آمریکای ِدلار),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(اروگوئه‌ی ِپزو),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(ازبکستون ِسام),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(ونزوئلایِ بولیوار \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(ونزوئلایِ بولیوار),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(ویتنام ِدنگ),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(میونی آفریقای ِسی‌اف‌ای فرانک),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(شرقی کاراییب ِدولار),
				'other' => q(شرقی کارائیب دلار),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(غربی آفریقای ِسی‌اف‌ای فرانک),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(یمن ِریال),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(جنوبی آفریقای ِراند),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(زامبیای ِکواچا),
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
							'ژانویه',
							'فوریه',
							'مارس',
							'آوریل',
							'مه',
							'ژوئن',
							'ژوئیه',
							'اوت',
							'سپتامبر',
							'اکتبر',
							'نوامبر',
							'دسامبر'
						],
						leap => [
							
						],
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
				'0' => 'پ.م',
				'1' => 'م.'
			},
			wide => {
				'0' => 'قبل میلاد',
				'1' => 'بعد میلاد'
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
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
	} },
);

no Moo;

1;

# vim: tabstop=4
