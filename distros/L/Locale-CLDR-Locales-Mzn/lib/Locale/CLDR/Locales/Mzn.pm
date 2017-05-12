=head1

Locale::CLDR::Locales::Mzn - Package for language Mazanderani

=cut

package Locale::CLDR::Locales::Mzn;
# This file auto generated from Data\common\main\mzn.xml
#	on Fri 29 Apr  7:18:38 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
 			'Hans@alt=stand-alone' => 'ساده‌بَیی هان',
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
 			'GB@alt=short' => 'بریتانیا',
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
 			'MK' => 'مقدونیه',
 			'MK@alt=variant' => 'مقدونیه جمهوری',
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
			auxiliary => qr{(?^u:[‌‍‎‏ َ ُ ِ ْ ٖ ٰ إ ك ى ي])},
			index => ['آ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ج', 'چ', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ه', 'و', 'ی'],
			main => qr{(?^u:[ً ٌ ٍ ّ ٔ ء آ أ ؤ ئ ا ب پ ة ت ث ج چ ح خ د ذ ر ز ژ س ش ص ض ط ظ ع غ ف ق ک گ ل م ن ه و ی])},
			punctuation => qr{(?^u:[\- ‐ ، ٫ ٬ ؛ \: ! ؟ . … ‹ › « » ( ) \[ \] * / \\])},
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
					'acre-foot' => {
						'name' => q(آکر-فوت),
						'other' => q({0} آکر-فوت),
					},
					'ampere' => {
						'name' => q(آمپر),
						'other' => q({0} آمپر),
					},
					'arc-minute' => {
						'name' => q(arcmin),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(arcsec),
						'other' => q({0}″),
					},
					'bit' => {
						'name' => q(بیت),
						'other' => q({0} بیت),
					},
					'byte' => {
						'name' => q(بایت),
						'other' => q({0} بایت),
					},
					'calorie' => {
						'name' => q(کالری),
						'other' => q({0} کالری),
					},
					'carat' => {
						'name' => q(قیراط),
						'other' => q({0} قیراط),
					},
					'celsius' => {
						'name' => q(درجه سلسیوس),
						'other' => q({0} درجه سلسیوس),
					},
					'centiliter' => {
						'name' => q(سانتی‌لیتر),
						'other' => q({0} سانتی‌لیتر),
					},
					'century' => {
						'name' => q(قرن),
						'other' => q({0} قرن),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(سانتی‌متر مکعب),
						'other' => q({0} سانتی‌متر مکعب),
						'per' => q({0} هر سانتی‌متر مکعب دله),
					},
					'cubic-foot' => {
						'name' => q(فوت مکعب),
						'other' => q({0} فوت مکعب),
					},
					'cubic-inch' => {
						'name' => q(اینچ مکعب),
						'other' => q({0} اینچ مکعب),
					},
					'cubic-kilometer' => {
						'name' => q(کیلومتر مکعب),
						'other' => q({0} کیلومتر مکعب),
					},
					'cubic-meter' => {
						'name' => q(متر مکعب),
						'other' => q({0} متر مکعب),
						'per' => q({0} هر متر مکعب دله),
					},
					'cubic-mile' => {
						'name' => q(مایل مکعب),
						'other' => q({0} مایل مکعب),
					},
					'cubic-yard' => {
						'name' => q(یارد مکعب),
						'other' => q({0} یارد مکعب),
					},
					'cup' => {
						'name' => q(دَییل),
						'other' => q({0} دَییل),
					},
					'cup-metric' => {
						'name' => q(متریک دَییل),
						'other' => q({0} متریک دَییل),
					},
					'day' => {
						'name' => q(روز),
						'other' => q({0} روز),
						'per' => q({0} روز),
					},
					'deciliter' => {
						'name' => q(دسی‌لیتر),
						'other' => q({0} دسی‌لیتر),
					},
					'degree' => {
						'name' => q(deg),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(فارنهایت),
						'other' => q({0} فارنهایت),
					},
					'fluid-ounce' => {
						'name' => q(فلوید اونس),
						'other' => q({0} فلوید اونس),
					},
					'foodcalorie' => {
						'name' => q(کالری),
						'other' => q({0} کالری),
					},
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(گالون),
						'other' => q({0} گالون),
						'per' => q({0} هر گالون دله),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(گیگابیت),
						'other' => q({0} گیگابیت),
					},
					'gigabyte' => {
						'name' => q(گیگابایت),
						'other' => q({0} گیگابایت),
					},
					'gigahertz' => {
						'name' => q(گیگاهرتز),
						'other' => q({0} گیگاهرتز),
					},
					'gigawatt' => {
						'name' => q(گیگاوات),
						'other' => q({0} گیگاوات),
					},
					'gram' => {
						'name' => q(گرم),
						'other' => q({0} گرم),
						'per' => q({0} هر گرم دله),
					},
					'hectoliter' => {
						'name' => q(هکتولیتر),
						'other' => q({0} هکتولیتر),
					},
					'hertz' => {
						'name' => q(هرتز),
						'other' => q({0} هرتز),
					},
					'horsepower' => {
						'name' => q(اسب‌بخار),
						'other' => q({0} اسب بخار),
					},
					'hour' => {
						'name' => q(ساعت),
						'other' => q({0} ساعِت),
						'per' => q({0} ساعِت),
					},
					'joule' => {
						'name' => q(ژول),
						'other' => q({0} ژول),
					},
					'karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(کلوین),
						'other' => q({0} کلوین),
					},
					'kilobit' => {
						'name' => q(کیلوبیت),
						'other' => q({0} کیلوبیت),
					},
					'kilobyte' => {
						'name' => q(کیلوبایت),
						'other' => q({0} کیلوبایت),
					},
					'kilocalorie' => {
						'name' => q(کیلوکالری),
						'other' => q({0} کیلوکالری),
					},
					'kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} کیلوگرم),
						'per' => q({0} هر کیلوگرم دله),
					},
					'kilohertz' => {
						'name' => q(کیلوهرتز),
						'other' => q({0} کیلوهرتز),
					},
					'kilojoule' => {
						'name' => q(کیلوژول),
						'other' => q({0} کیلوژول),
					},
					'kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} کیلومتر بر ساعت),
					},
					'kilowatt' => {
						'name' => q(کیلووات),
						'other' => q({0} کیلووات),
					},
					'kilowatt-hour' => {
						'name' => q(کیلووات بر ساعت),
						'other' => q({0} کیلووات-ساعت),
					},
					'knot' => {
						'name' => q(گره),
						'other' => q({0} گره),
					},
					'liter' => {
						'name' => q(لیتر),
						'other' => q({0} لیتر),
						'per' => q({0} هر لیتر دله),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(مگابیت),
						'other' => q({0} مگابیت),
					},
					'megabyte' => {
						'name' => q(مگابایت),
						'other' => q({0} مگابایت),
					},
					'megahertz' => {
						'name' => q(مگاهرتز),
						'other' => q({0} مگاهرتز),
					},
					'megaliter' => {
						'name' => q(مگالیتر),
						'other' => q({0} مگالیتر),
					},
					'megawatt' => {
						'name' => q(مگاوات),
						'other' => q({0} مگاوات),
					},
					'meter-per-second' => {
						'name' => q(متر بر ثانیه),
						'other' => q({0} متر بر ثانیه),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(متریک تُن),
						'other' => q({0} متریک تُن),
					},
					'microgram' => {
						'name' => q(میکروگرم),
						'other' => q({0} میکروگرم),
					},
					'microsecond' => {
						'name' => q(میکروثانیه),
						'other' => q({0} میکروثانیه),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'name' => q(مایل بر ساعت),
						'other' => q({0} مایل بر ساعت),
					},
					'milliampere' => {
						'name' => q(میلی‌آمپر),
						'other' => q({0} میلی‌آمپر),
					},
					'milligram' => {
						'name' => q(میلی‌گرم),
						'other' => q({0} میلی‌گرم),
					},
					'milliliter' => {
						'name' => q(میلی‌لیتر),
						'other' => q({0} میلی‌لیتر),
					},
					'millisecond' => {
						'name' => q(میلی‌ثانیه),
						'other' => q({0} میلی‌ثانیه),
					},
					'milliwatt' => {
						'name' => q(میلی‌وات),
						'other' => q({0} میلی‌وات),
					},
					'minute' => {
						'name' => q(دقیقه),
						'other' => q({0} دقیقه),
					},
					'month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
						'per' => q({0} ماه پیش),
					},
					'nanosecond' => {
						'name' => q(نانوثانیه),
						'other' => q({0} نانوثانیه),
					},
					'ohm' => {
						'name' => q(اُهم),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(اونس),
						'other' => q({0} اونس),
						'per' => q({0} هر اونس دله),
					},
					'ounce-troy' => {
						'name' => q(تروی اونس),
						'other' => q({0} تروی اونس),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'pint' => {
						'name' => q(پاینت),
						'other' => q({0} پاینت),
					},
					'pint-metric' => {
						'name' => q(متریک پاینت),
						'other' => q({0} متریک پاینت),
					},
					'pound' => {
						'name' => q(پوند),
						'other' => q({0} پوند),
						'per' => q({0} هر پوند دله),
					},
					'quart' => {
						'name' => q(ربع),
						'other' => q({0} ربع),
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
						'name' => q(ثانیه),
						'other' => q({0} ثانیه),
						'per' => q({0} ثانیه),
					},
					'tablespoon' => {
						'name' => q(کال),
						'other' => q({0}تا کال),
					},
					'teaspoon' => {
						'name' => q(چایی‌خاری کچه),
						'other' => q({0} چایی‌خاری کچه),
					},
					'terabit' => {
						'name' => q(ترابیت),
						'other' => q({0} ترابیت),
					},
					'terabyte' => {
						'name' => q(ترابایت),
						'other' => q({0} ترابایت),
					},
					'ton' => {
						'name' => q(تُن),
						'other' => q({0} تُن),
					},
					'volt' => {
						'name' => q(وُلت),
						'other' => q({0} ولت),
					},
					'watt' => {
						'name' => q(وات),
						'other' => q({0} وات),
					},
					'week' => {
						'name' => q(هفته),
						'other' => q({0} هفته),
						'per' => q({0} هفته پیش),
					},
					'year' => {
						'name' => q(سال),
						'other' => q({0} سال),
						'per' => q({0} سال پیش),
					},
				},
				'narrow' => {
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'day' => {
						'name' => q(روز),
						'other' => q({0} روز),
					},
					'gram' => {
						'name' => q(گرم),
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(ساعت),
						'other' => q({0} ساعِت),
					},
					'kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} kg),
					},
					'kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} km/h),
					},
					'liter' => {
						'name' => q(لیتر),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					'millisecond' => {
						'name' => q(میلی‌ثانیه),
						'other' => q({0} میلی‌ثانیه),
					},
					'minute' => {
						'name' => q(دَقه),
						'other' => q({0} دَقه),
					},
					'month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'second' => {
						'name' => q(ثانیه),
						'other' => q({0} ثانیه),
					},
					'week' => {
						'name' => q(هفته),
						'other' => q({0} هفته),
					},
					'year' => {
						'name' => q(سال),
						'other' => q({0} سال),
					},
				},
				'short' => {
					'acre-foot' => {
						'name' => q(آکرفوت),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(آمپر),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(arcmin),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(arcsec),
						'other' => q({0}″),
					},
					'bit' => {
						'name' => q(بیت),
						'other' => q({0} بیت),
					},
					'byte' => {
						'name' => q(بایت),
						'other' => q({0} بایت),
					},
					'calorie' => {
						'name' => q(کالری),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(قیراط),
						'other' => q({0} قیراط),
					},
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(سانتی‌لیتر),
						'other' => q({0} cL),
					},
					'century' => {
						'name' => q(قرن),
						'other' => q({0} قرن),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'other' => q({0} in³),
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
						'name' => q(mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(دَییل),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(روز),
						'other' => q({0} روز),
						'per' => q({0} روز),
					},
					'deciliter' => {
						'name' => q(دسی‌لیتر),
						'other' => q({0} dL),
					},
					'degree' => {
						'name' => q(deg),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(فلوید اونس),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(کالری),
						'other' => q({0} Cal),
					},
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(گالون),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(گیگابیت),
						'other' => q({0} گیگابیت),
					},
					'gigabyte' => {
						'name' => q(گیگابایت),
						'other' => q({0} گیگابایت),
					},
					'gigahertz' => {
						'name' => q(گیگاهرتز),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(گیگاوات),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(گرم),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectoliter' => {
						'name' => q(هکتولیتر),
						'other' => q({0} hL),
					},
					'hertz' => {
						'name' => q(هرتز),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(اسب‌بخار),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(ساعت),
						'per' => q({0} ساعِت),
					},
					'joule' => {
						'name' => q(ژول),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(کیلوبیت),
						'other' => q({0} کیلوبیت),
					},
					'kilobyte' => {
						'name' => q(کیلوبایت),
						'other' => q({0} کیلوبایت),
					},
					'kilocalorie' => {
						'name' => q(کیلوکالری),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(کیلوگرم),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(کیلوهرتز),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(کیلوژول),
						'other' => q({0} kJ),
					},
					'kilometer-per-hour' => {
						'name' => q(کیلومتر بر ساعت),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(کیلووات),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(کیلووات-ساعت),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(گره),
						'other' => q({0} kn),
					},
					'liter' => {
						'name' => q(لیتر),
						'other' => q({0} لیتر),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(مگابیت),
						'other' => q({0} مگابیت),
					},
					'megabyte' => {
						'name' => q(مگابایت),
						'other' => q({0} مگابایت),
					},
					'megahertz' => {
						'name' => q(مگاهرتز),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(مگالیتر),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(مگاوات),
						'other' => q({0} MW),
					},
					'meter-per-second' => {
						'name' => q(متر بر ثانیه),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(میکروگرم),
						'other' => q({0} µg),
					},
					'microsecond' => {
						'name' => q(میکروثانیه),
						'other' => q({0} میکروثانیه),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'name' => q(مایل بر ساعت),
						'other' => q({0} mi/h),
					},
					'milliampere' => {
						'name' => q(میلی‌آمپر),
						'other' => q({0} mA),
					},
					'milligram' => {
						'name' => q(میلی‌گرم),
						'other' => q({0} mg),
					},
					'milliliter' => {
						'name' => q(میلی‌لیتر),
						'other' => q({0} mL),
					},
					'millisecond' => {
						'name' => q(میلی‌ثانیه),
						'other' => q({0} میلی‌ثانیه),
					},
					'milliwatt' => {
						'name' => q(میلی‌وات),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(دَقه),
						'other' => q({0} دَقه),
						'per' => q({0} دَقه),
					},
					'month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
						'per' => q({0} ماه),
					},
					'nanosecond' => {
						'name' => q(نانوثانیه),
						'other' => q({0} نانوثانیه),
					},
					'ohm' => {
						'name' => q(اهم),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(اونس),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(تروی اونس),
						'other' => q({0} oz t),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'pint' => {
						'name' => q(پاینت),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(متریک پاینت),
						'other' => q({0} mpt),
					},
					'pound' => {
						'name' => q(پوند),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'quart' => {
						'name' => q(ربع),
						'other' => q({0} qt),
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
						'name' => q(ثانیه),
						'other' => q({0} ثانیه),
						'per' => q({0} ثانیه),
					},
					'tablespoon' => {
						'name' => q(کال),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(چایی‌خاری کچه),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'name' => q(ترابیت),
						'other' => q({0} ترابیت),
					},
					'terabyte' => {
						'name' => q(ترابایت),
						'other' => q({0} ترابایت),
					},
					'ton' => {
						'name' => q(تُن),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(ولت),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(وات),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(هفته),
						'other' => q({0} هفته),
						'per' => q({0} هفته),
					},
					'year' => {
						'name' => q(سال),
						'other' => q({0} سال),
						'per' => q({0} سال),
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
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(بلاروس ِروبل),
				'other' => q(بلاروس ِروبل),
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
				'currency' => q(پروی ِنوئوو سول),
				'other' => q(پروی ِنوئوو سول),
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
			symbol => 'CFA',
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
