=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mzn - Package for language Mazanderani

=cut

package Locale::CLDR::Locales::Mzn;
# This file auto generated from Data\common\main\mzn.xml
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
			lines => 'top-to-bottom',
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
			punctuation => qr{[\- ‐ ‑ ، ٫ ٬ ؛ \: ! ؟ . … ‹ › « » ( ) \[ \] * / \\]},
		};
	},
EOT
: sub {
		return { index => ['آ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ج', 'چ', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ه', 'و', 'ی'], };
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
						'name' => q(g-force),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsec),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsec),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(deg),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(deg),
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
					'concentr-karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0} L/km),
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
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
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
						'other' => q({0} ساعِت),
						'per' => q({0} ساعِت),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ساعت),
						'other' => q({0} ساعِت),
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
						'name' => q(ماه),
						'other' => q({0} ماه),
						'per' => q({0} ماه پیش),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
						'per' => q({0} ماه پیش),
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
						'per' => q({0} هفته پیش),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(هفته),
						'other' => q({0} هفته),
						'per' => q({0} هفته پیش),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(سال),
						'other' => q({0} سال),
						'per' => q({0} سال پیش),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(سال),
						'other' => q({0} سال),
						'per' => q({0} سال پیش),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(آمپر),
						'other' => q({0} آمپر),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(آمپر),
						'other' => q({0} آمپر),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(میلی‌آمپر),
						'other' => q({0} میلی‌آمپر),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(میلی‌آمپر),
						'other' => q({0} میلی‌آمپر),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(اُهم),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(اُهم),
						'other' => q({0} Ω),
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
						'name' => q(کالری),
						'other' => q({0} کالری),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(کالری),
						'other' => q({0} کالری),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(کالری),
						'other' => q({0} کالری),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(کالری),
						'other' => q({0} کالری),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ژول),
						'other' => q({0} ژول),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ژول),
						'other' => q({0} ژول),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(کیلوکالری),
						'other' => q({0} کیلوکالری),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(کیلوکالری),
						'other' => q({0} کیلوکالری),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(کیلوژول),
						'other' => q({0} کیلوژول),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(کیلوژول),
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
						'name' => q(گیگاهرتز),
						'other' => q({0} گیگاهرتز),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(گیگاهرتز),
						'other' => q({0} گیگاهرتز),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(هرتز),
						'other' => q({0} هرتز),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(هرتز),
						'other' => q({0} هرتز),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(کیلوهرتز),
						'other' => q({0} کیلوهرتز),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(کیلوهرتز),
						'other' => q({0} کیلوهرتز),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(مگاهرتز),
						'other' => q({0} مگاهرتز),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(مگاهرتز),
						'other' => q({0} مگاهرتز),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lx),
						'other' => q({0} lx),
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
						'other' => q({0} گرم),
						'per' => q({0} هر گرم دله),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(گرم),
						'other' => q({0} گرم),
						'per' => q({0} هر گرم دله),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} کیلوگرم),
						'per' => q({0} هر کیلوگرم دله),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} کیلوگرم),
						'per' => q({0} هر کیلوگرم دله),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(متریک تُن),
						'other' => q({0} متریک تُن),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(متریک تُن),
						'other' => q({0} متریک تُن),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(میکروگرم),
						'other' => q({0} میکروگرم),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(میکروگرم),
						'other' => q({0} میکروگرم),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(میلی‌گرم),
						'other' => q({0} میلی‌گرم),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(میلی‌گرم),
						'other' => q({0} میلی‌گرم),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(اونس),
						'other' => q({0} اونس),
						'per' => q({0} هر اونس دله),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(اونس),
						'other' => q({0} اونس),
						'per' => q({0} هر اونس دله),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(تروی اونس),
						'other' => q({0} تروی اونس),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(تروی اونس),
						'other' => q({0} تروی اونس),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(پوند),
						'other' => q({0} پوند),
						'per' => q({0} هر پوند دله),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(پوند),
						'other' => q({0} پوند),
						'per' => q({0} هر پوند دله),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(تُن),
						'other' => q({0} تُن),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(تُن),
						'other' => q({0} تُن),
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
						'name' => q(گیگاوات),
						'other' => q({0} گیگاوات),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(گیگاوات),
						'other' => q({0} گیگاوات),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(اسب‌بخار),
						'other' => q({0} اسب بخار),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(اسب‌بخار),
						'other' => q({0} اسب بخار),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(کیلووات),
						'other' => q({0} کیلووات),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(کیلووات),
						'other' => q({0} کیلووات),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(مگاوات),
						'other' => q({0} مگاوات),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(مگاوات),
						'other' => q({0} مگاوات),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(میلی‌وات),
						'other' => q({0} میلی‌وات),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(میلی‌وات),
						'other' => q({0} میلی‌وات),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(وات),
						'other' => q({0} وات),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(وات),
						'other' => q({0} وات),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} کیلومتر بر ساعت),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} کیلومتر بر ساعت),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(گره),
						'other' => q({0} گره),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(گره),
						'other' => q({0} گره),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(متر بر ثانیه),
						'other' => q({0} متر بر ثانیه),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(متر بر ثانیه),
						'other' => q({0} متر بر ثانیه),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(مایل بر ساعت),
						'other' => q({0} مایل بر ساعت),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(مایل بر ساعت),
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
						'name' => q(سانتی‌لیتر),
						'other' => q({0} سانتی‌لیتر),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(سانتی‌لیتر),
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
						'name' => q(دَییل),
						'other' => q({0} دَییل),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(دَییل),
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
						'name' => q(دسی‌لیتر),
						'other' => q({0} دسی‌لیتر),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(دسی‌لیتر),
						'other' => q({0} دسی‌لیتر),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(فلوید اونس),
						'other' => q({0} فلوید اونس),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(فلوید اونس),
						'other' => q({0} فلوید اونس),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(گالون),
						'other' => q({0} گالون),
						'per' => q({0} هر گالون دله),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(گالون),
						'other' => q({0} گالون),
						'per' => q({0} هر گالون دله),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(هکتولیتر),
						'other' => q({0} هکتولیتر),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(هکتولیتر),
						'other' => q({0} هکتولیتر),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(لیتر),
						'other' => q({0} لیتر),
						'per' => q({0} هر لیتر دله),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(لیتر),
						'other' => q({0} لیتر),
						'per' => q({0} هر لیتر دله),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(مگالیتر),
						'other' => q({0} مگالیتر),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(مگالیتر),
						'other' => q({0} مگالیتر),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(میلی‌لیتر),
						'other' => q({0} میلی‌لیتر),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(میلی‌لیتر),
						'other' => q({0} میلی‌لیتر),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(پاینت),
						'other' => q({0} پاینت),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(پاینت),
						'other' => q({0} پاینت),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(متریک پاینت),
						'other' => q({0} متریک پاینت),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(متریک پاینت),
						'other' => q({0} متریک پاینت),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ربع),
						'other' => q({0} ربع),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ربع),
						'other' => q({0} ربع),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(کال),
						'other' => q({0}تا کال),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(کال),
						'other' => q({0}تا کال),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(چایی‌خاری کچه),
						'other' => q({0} چایی‌خاری کچه),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(چایی‌خاری کچه),
						'other' => q({0} چایی‌خاری کچه),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(روز),
						'other' => q({0} روز),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(روز),
						'other' => q({0} روز),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ساعت),
						'other' => q({0} ساعِت),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ساعت),
						'other' => q({0} ساعِت),
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
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(دَقه),
						'other' => q({0} دَقه),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ثانیه),
						'other' => q({0} ثانیه),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ثانیه),
						'other' => q({0} ثانیه),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(هفته),
						'other' => q({0} هفته),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(هفته),
						'other' => q({0} هفته),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(سال),
						'other' => q({0} سال),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(سال),
						'other' => q({0} سال),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(گرم),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(گرم),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} kg),
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
					'speed-kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} km/h),
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
					'volume-liter' => {
						'name' => q(لیتر),
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(لیتر),
						'other' => q({0} l),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-force),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsec),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsec),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(deg),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(deg),
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
					'concentr-karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0} L/km),
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
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
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
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(آمپر),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(میلی‌آمپر),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(میلی‌آمپر),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(اهم),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(اهم),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(ولت),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(ولت),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(کالری),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(کالری),
						'other' => q({0} cal),
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
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ژول),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(کیلوکالری),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(کیلوکالری),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(کیلوژول),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(کیلوژول),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(کیلووات-ساعت),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(کیلووات-ساعت),
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(گیگاهرتز),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(گیگاهرتز),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(هرتز),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(هرتز),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(کیلوهرتز),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(کیلوهرتز),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(مگاهرتز),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(مگاهرتز),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lx),
						'other' => q({0} lx),
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
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(گرم),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(میکروگرم),
						'other' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(میکروگرم),
						'other' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(میلی‌گرم),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(میلی‌گرم),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(اونس),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(اونس),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(تروی اونس),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(تروی اونس),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(پوند),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(پوند),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(تُن),
						'other' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(تُن),
						'other' => q({0} tn),
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
						'name' => q(گیگاوات),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(گیگاوات),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(اسب‌بخار),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(اسب‌بخار),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(کیلووات),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(کیلووات),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(مگاوات),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(مگاوات),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(میلی‌وات),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(میلی‌وات),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(وات),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(وات),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(گره),
						'other' => q({0} kn),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(گره),
						'other' => q({0} kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(متر بر ثانیه),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(متر بر ثانیه),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(مایل بر ساعت),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(مایل بر ساعت),
						'other' => q({0} mi/h),
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
					'volume-acre-foot' => {
						'name' => q(آکرفوت),
						'other' => q({0} ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(آکرفوت),
						'other' => q({0} ac ft),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(سانتی‌لیتر),
						'other' => q({0} cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(سانتی‌لیتر),
						'other' => q({0} cL),
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
						'name' => q(ft³),
						'other' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
						'other' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'other' => q({0} in³),
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
						'name' => q(mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(دَییل),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(دَییل),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mcup),
						'other' => q({0} mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mcup),
						'other' => q({0} mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(دسی‌لیتر),
						'other' => q({0} dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(دسی‌لیتر),
						'other' => q({0} dL),
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
						'other' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(هکتولیتر),
						'other' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(لیتر),
						'other' => q({0} لیتر),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(لیتر),
						'other' => q({0} لیتر),
						'per' => q({0}/l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(مگالیتر),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(مگالیتر),
						'other' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(میلی‌لیتر),
						'other' => q({0} mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(میلی‌لیتر),
						'other' => q({0} mL),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(پاینت),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(پاینت),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(متریک پاینت),
						'other' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(متریک پاینت),
						'other' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ربع),
						'other' => q({0} qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ربع),
						'other' => q({0} qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(کال),
						'other' => q({0} tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(کال),
						'other' => q({0} tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(چایی‌خاری کچه),
						'other' => q({0} tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(چایی‌خاری کچه),
						'other' => q({0} tsp),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:no|n)$' }
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
			symbol => 'AED',
			display_name => {
				'currency' => q(متحده عربی امارات ِدرهم),
				'other' => q(امارات ِدرهم),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(افغانستون ِافغانی),
				'other' => q(افغانستون ِافغانی),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(آلبانی ِلک),
				'other' => q(آلبانی ِلک),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(ارمنستون درهم),
				'other' => q(ارمنستون درهم),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(هلند ِآنتیل ِجزایر ِگویلدر),
				'other' => q(هلند ِآنتیل ِجزایر ِگویلدر),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(آنگولای ِکوانزا),
				'other' => q(آنگولای ِکوانزا),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(آرژانتین ِپزو),
				'other' => q(آرژانتین ِپزو),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(آروبای ِفلورن),
				'other' => q(آروبای فلورن),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(آذربایجون ِمنات),
				'other' => q(آذربایجون ِمنات),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(بوسنی و هرزگوین ِتبدیل‌بَیی مارک),
				'other' => q(بوسنی و هرزگوین ِتبدیل‌بَیی مارک),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(باربادوس ِدولار),
				'other' => q(باربادوس دلار),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(بنگلادش ِتاکا),
				'other' => q(بنگلادش ِتاکا),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(بلغارستون ِلیوا),
				'other' => q(بلغارستون ِلیوا),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(بحرین ِدینار),
				'other' => q(بحرین ِدینار),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(بوروندی ِفرانک),
				'other' => q(بوروندی ِفرانک),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(برمودای ِدولار),
				'other' => q(برمودای ِدلار),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(برونئی ِدولار),
				'other' => q(برونئی دلار),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(بولیوی ِبولیویانو),
				'other' => q(بولیوی ِبولیویانو),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(برزیل ِرئال),
				'other' => q(برزیل ِرئال),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(باهامای ِدولار),
				'other' => q(باهامای ِدولار),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(بوتان ِنگولتروم),
				'other' => q(بوتان ِنگولتروم),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(بوتساوانای ِپولا),
				'other' => q(بوتساوانای ِپولا),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(بلاروس ِروبل),
				'other' => q(بلاروس ِروبل),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(بلاروس ِروبل \(۲۰۰۰–۲۰۱۶\)),
				'other' => q(بلاروس ِروبل \(۲۰۰۰–۲۰۱۶\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(بلیز ِدولار),
				'other' => q(بلیز دلار),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(کانادای ِدولار),
				'other' => q(کانادای ِدلار),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(کنگوی ِفرانک),
				'other' => q(کنگوی ِفرانک),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(سوییس ِفرانک),
				'other' => q(سوییس ِفرانک),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(شیلی ِپزو),
				'other' => q(شیلی ِپزو),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(چین ِیوآن),
				'other' => q(چین ِیوآن),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(کلمبیای ِپزو),
				'other' => q(کلمبیای ِپزو),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(کاستاریکای ِکولون),
				'other' => q(کاستاریکا کولون),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(کوبای ِتبدیل‌بَیی پزو),
				'other' => q(کوبای تبدیل‌بَیی پزو),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(کوبای ِپزو),
				'other' => q(کوبای پزو),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(عاج ِساحل ِایسکودو),
				'other' => q(عاج ِساحل ِایسکودو),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(چک ِکرون),
				'other' => q(چک ِکرون),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(جیبوتی ِفرانک),
				'other' => q(جیبوتی ِفرانک),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(دانمارک ِکورن),
				'other' => q(دانمارک ِکورن),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(دومینیکن ِپزو),
				'other' => q(دومینیکن پزو),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(الجزیره‌ی ِدینار),
				'other' => q(الجزیره‌ی ِدینار),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(مصر ِپوند),
				'other' => q(مصر ِپوند),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(اریتره‌ی ِناکفا),
				'other' => q(اریتره‌ی ِناکفا),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(اتیوپی ِبیر),
				'other' => q(اتیوپی ِبیر),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(یورو),
				'other' => q(یورو),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(فالکلند ِجزایر ِپوند),
				'other' => q(فالکلند ِجزایر ِپوند),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(بریتانیای ِپوند),
				'other' => q(بریتانیای ِپوند),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(گرجستون ِلاری),
				'other' => q(گرجستون ِلاری),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(غنای ِسدی),
				'other' => q(غنای ِسدی),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(جبل‌طارق ِپوند),
				'other' => q(جبل‌طارق ِپوند),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(گامبیای ِدالاسی),
				'other' => q(گامبیای ِدالاسی),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(گینه‌ی ِفرانک),
				'other' => q(گینه‌ی ِفرانک),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(گواتمالا کتزال),
				'other' => q(گواتمالای ِکتزال),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(گویان ِدولار),
				'other' => q(گویان دلار),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(هونگ کونگ ِدولار),
				'other' => q(هنگ کنگ ِدلار),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(هندوراس ِلمپیرا),
				'other' => q(هندوراس لمپیرا),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(کرواسی ِکونا),
				'other' => q(کرواسی ِکونا),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(هائیتی ِگورد),
				'other' => q(هاییتی گورد),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(مجارستون ِفروینت),
				'other' => q(مجارستون ِفروینت),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(اندونزی ِروپیه),
				'other' => q(اندونزی ِروپیه),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(اسراییل ِنو شِکِل),
				'other' => q(اسراییل ِنو شِکِل),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(هند ِروپیه),
				'other' => q(هند ِروپیه),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(عراق ِدینار),
				'other' => q(عراق ِدینار),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(ایران ریال),
				'other' => q(ایران ریال),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(ایسلند کرونا),
				'other' => q(ایسلند کرونا),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(جاماییکای ِدولار),
				'other' => q(جاماییکا دلار),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(اردن ِدینار),
				'other' => q(اردن ِدینار),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(جاپون ِین),
				'other' => q(جاپون ِین),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(کنیای ِشیلینگ),
				'other' => q(کنیای ِشیلینگ),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(قرقیزستون ِسام),
				'other' => q(قرقیزستون ِسام),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(کامبوج ِریل),
				'other' => q(کامبوج ِریل),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(کامرون ِفرانک),
				'other' => q(کامرون ِفرانک),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(شمالی کره‌ی ِوون),
				'other' => q(شمالی کره وون),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(جنوبی کُره‌ی ِوون),
				'other' => q(جنوبی کره وون),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(کویت ِدینار),
				'other' => q(کویت ِدینار),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(کایمن جزیره‌ی ِدولار),
				'other' => q(کایمن جزیره‌ی دلار),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(قراقستون ِتنگ),
				'other' => q(قراقستون ِتنگ),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(لائوس ِکیپ),
				'other' => q(لائوس ِکیپ),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(لبنان ِپوند),
				'other' => q(لبنان ِپوند),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(سریلانکا روپیه),
				'other' => q(سریلانکا روپیه),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(لیبریای ِدولار),
				'other' => q(لیبریا دلار),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(لیبی ِدینار),
				'other' => q(لیبی ِدینار),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(مراکش ِدرهم),
				'other' => q(مراکش ِدرهم),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(مولداوی ِلئو),
				'other' => q(مولداوی ِلئو),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(ماداگاسکار ِآریاری),
				'other' => q(ماداگاسکار ِآریاری),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(مقدونیه‌ی ِدینار),
				'other' => q(مقدونیه‌ی ِدینار),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(میانمار ِکیات),
				'other' => q(میانمار ِکیات),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(مغلستون ِتوگریک),
				'other' => q(مغلستون ِتوگریک),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(ماکائو ِپاتاجا),
				'other' => q(ماکائو ِپاتاجا),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(موریتانی ِاوگوئیا \(1973–2017\)),
				'other' => q(موریتانی ِاوگوئیا \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(موریتانی ِاوگوئیا),
				'other' => q(موریتانی ِاوگوئیا),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(موریتیان ِروپیه),
				'other' => q(موریتیان ِروپیه),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(مالدیو ِروفیا),
				'other' => q(مالدیو ِروفیا),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(مالاوی ِکواچا),
				'other' => q(مالاوی ِکواچا),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(مکزیک ِپزو),
				'other' => q(مکزیک پزو),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(مالزی ِرینگیت),
				'other' => q(مالزی ِرینگیت),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(موزامبیک متیکال),
				'other' => q(موزامبیک متیکال),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(نامبیای ِدولار),
				'other' => q(نامبیای ِدلار),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(نیجریه‌ی ِنیارا),
				'other' => q(نیجریه‌ی ِنیارا),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(نیکاراگوئه‌ی ِکوردوبا),
				'other' => q(نیکاراگوئه کوردوبا),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(نروژ ِکرون),
				'other' => q(نروژ ِکرون),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(نپال ِروپیه),
				'other' => q(نپال ِروپیه),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(عمان ِریال),
				'other' => q(عمان ِریال),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(پانامای ِبالبوا),
				'other' => q(پانامای بالبوا),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(پروی ِسول),
				'other' => q(پروی ِسول),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(فیلیپین ِپزو),
				'other' => q(فیلیپین ِپزو),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(پاکستون روپیه),
				'other' => q(پاکستون روپیه),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(لهستون ِزلوتی),
				'other' => q(لهستون ِزلوتی),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(پاراگوئه‌ی ِگوارانی),
				'other' => q(پاراگوئه‌ی ِگوارانی),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(قطر ِریال),
				'other' => q(قطر ِریال),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(رومانی ِلئو),
				'other' => q(رومانی ِلئو),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(صربستون ِدینار),
				'other' => q(صربستون ِدینار),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(روسیه‌ی ِروبل),
				'other' => q(روسیه‌ی ِروبل),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(روآندای ِفرانک),
				'other' => q(روآندای ِفرانک),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(عربستون ِریال),
				'other' => q(عربستون ِریال),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(سیشل ِروپیه),
				'other' => q(سیشل ِروپیه),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(سودان ِپوند),
				'other' => q(سودان ِپوند),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(سوئد ِکرون),
				'other' => q(سوئد ِکرون),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(سنگاپور ِدلار),
				'other' => q(سنگاپور ِدلار),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(سنت هلنای ِپوند),
				'other' => q(سنت هلنای ِپوند),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(سیرالئون ِلئون),
				'other' => q(سیرالئون ِلئون),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(سومالی ِشیلینگ),
				'other' => q(سومالی ِشیلینگ),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(سورینام ِدولار),
				'other' => q(سورینام ِدولار),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(جنوبی سودان ِپوند),
				'other' => q(جنوبی سودان ِپوند),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(سائوتومه و پرینسیپ ِدوبرا \(1977–2017\)),
				'other' => q(سائوتومه و پرینسیپ ِدوبرا \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
			display_name => {
				'currency' => q(سائوتومه و پرینسیپ ِدوبرا),
				'other' => q(سائوتومه و پرینسیپ ِدوبرا),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(سوریه‌ی ِپوند),
				'other' => q(سوریه‌ی ِپوند),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(سوازیلند ِلیلانجنی),
				'other' => q(سوازیلند ِلیلانجنی),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(تایلند ِبات),
				'other' => q(تایلند ِبات),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(تاجیکستون ِسامانی),
				'other' => q(تاجیکستون ِسامانی),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(ترکمنستون ِمنات),
				'other' => q(ترکمنستون ِمنات),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(تونس ِدینار),
				'other' => q(تونس ِدینار),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(ترکیه‌ی ِلیره),
				'other' => q(ترکیه‌ی ِلیره),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(ترینیداد و توباگوی ِدولار),
				'other' => q(ترینیداد و توباگوی ِدلار),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(جدید ِتایوان ِدولار),
				'other' => q(تایوان دلار),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(تانزانیای ِشیلینگ),
				'other' => q(تانزانیای ِشیلینگ),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(اکراین ِگریونا),
				'other' => q(اکراین ِگریونا),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(اوگاندای ِشیلینگ),
				'other' => q(اوگاندای ِشیلینگ),
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
			symbol => 'UYU',
			display_name => {
				'currency' => q(اروگوئه‌ی ِپزو),
				'other' => q(اروگوئه‌ی ِپزو),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(ازبکستون ِسام),
				'other' => q(ازبکستون ِسام),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(ونزوئلایِ بولیوار \(2008–2018\)),
				'other' => q(ونزوئلایِ بولیوار \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(ونزوئلایِ بولیوار),
				'other' => q(ونزوئلایِ بولیوار),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(ویتنام ِدنگ),
				'other' => q(ویتنام ِدنگ),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(میونی آفریقای ِسی‌اف‌ای فرانک),
				'other' => q(میونی آفریقای ِسی‌اف‌ای فرانک),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(شرقی کاراییب ِدولار),
				'other' => q(شرقی کارائیب دلار),
			},
		},
		'XOF' => {
			symbol => 'F CFA',
			display_name => {
				'currency' => q(غربی آفریقای ِسی‌اف‌ای فرانک),
				'other' => q(غربی آفریقای ِسی‌اف‌ای فرانک),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(یمن ِریال),
				'other' => q(یمن ِریال),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(جنوبی آفریقای ِراند),
				'other' => q(جنوبی آفریقای ِراند),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(زامبیای ِکواچا),
				'other' => q(زامبیای ِکواچا),
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
				'stand-alone' => {
					abbreviated => {
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
	 } }
);
no Moo;

1;

# vim: tabstop=4
