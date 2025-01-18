=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bgn - Package for language Western Balochi

=cut

package Locale::CLDR::Locales::Bgn;
# This file auto generated from Data\common\main\bgn.xml
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
				'aa' => 'افار',
 				'ab' => 'آبخازی',
 				'ace' => 'آچه‌ای',
 				'ada' => 'ادانگمی',
 				'ady' => 'ادیغی',
 				'af' => 'افریکانس',
 				'agq' => 'اغیمی',
 				'ain' => 'آینو',
 				'ak' => 'اکانی',
 				'ale' => 'الیوتی',
 				'alt' => 'جهلسرین آلتایی',
 				'am' => 'امهاری',
 				'an' => 'آراگونی',
 				'anp' => 'انگیکای',
 				'ar' => 'عربی',
 				'ar_001' => 'پیشرفته‌این عربی',
 				'arn' => 'ماپوچه‌ای',
 				'arp' => 'اراپاهو',
 				'as' => 'آسامی',
 				'asa' => 'آسو',
 				'ast' => 'آستوری',
 				'av' => 'آواری',
 				'awa' => 'آوادی',
 				'ay' => 'ایمارای',
 				'az' => 'آذربایجانی',
 				'az@alt=short' => 'آذری',
 				'ba' => 'باشقیری',
 				'ban' => 'بالینسی',
 				'bas' => 'باسا',
 				'be' => 'بیلاروسی',
 				'bem' => 'بیمبا',
 				'bez' => 'بینای',
 				'bg' => 'بلغاری',
 				'bgn' => 'بلوچی (رخشانی)',
 				'bho' => 'بهوجپوری',
 				'bi' => 'بیسلامه',
 				'bin' => 'بینی',
 				'bla' => 'سیکسیکا',
 				'bm' => 'بمبارای',
 				'bn' => 'بنگالی',
 				'bo' => 'تبتی',
 				'br' => 'بریتون',
 				'brx' => 'بۆدو',
 				'bs' => 'بوسنی',
 				'bug' => 'بوگینسی',
 				'byn' => 'بلین',
 				'ca' => 'کاتالانی',
 				'ce' => 'چیچینی',
 				'ceb' => 'سینوگبانونی',
 				'cgg' => 'شیگی',
 				'ch' => 'چه‌مروری',
 				'chk' => 'تروسکی',
 				'chm' => 'ماری',
 				'cho' => 'چاکتاوی',
 				'chr' => 'چیروکی',
 				'chy' => 'شاینی زبان',
 				'ckb' => 'مرکزین کوردی',
 				'co' => 'کرسی',
 				'crs' => 'سیشلی کریولین فرانسوی',
 				'cs' => 'چیکی',
 				'cu' => 'سلاواکی کلیسایی',
 				'cv' => 'چواشی',
 				'cy' => 'ولزی',
 				'da' => 'ڈینمارکی',
 				'dak' => 'داکوتی',
 				'dar' => 'دارگوایی',
 				'dav' => 'تایتایی',
 				'de' => 'جرمنی',
 				'de_AT' => 'استرالیاین جرمنی',
 				'de_CH' => 'سویسین جرمنی',
 				'dgr' => 'داگریبی',
 				'dje' => 'زرمی',
 				'dsb' => 'صُربی سفلی',
 				'dua' => 'دوالی',
 				'dv' => 'دیوهی',
 				'dyo' => 'جولا فونی',
 				'dz' => 'دزونگخا',
 				'dzg' => 'دزازا',
 				'ebu' => 'ایمبو',
 				'ee' => 'اوه‌ای',
 				'efi' => 'ایفیکی',
 				'eka' => 'ایکاجوکی',
 				'el' => 'یونانی',
 				'en' => 'انگریزی',
 				'en_AU' => 'استرالیاین انگریزی',
 				'en_CA' => 'کاناڈاین انگریزی',
 				'en_GB' => 'بریتانیاین انگریزی',
 				'en_GB@alt=short' => 'بریتن انگریزی',
 				'en_US' => 'امریکاین انگریزی',
 				'en_US@alt=short' => 'یو اس انگریزی',
 				'eo' => 'اسپرانتوی',
 				'es' => 'هسپانوی',
 				'es_419' => 'لاتین امریکایی هسپانوی',
 				'es_ES' => 'اوروپایین هسپانوی',
 				'es_MX' => 'مکسیکوین هسپانوی',
 				'et' => 'استونیایی',
 				'eu' => 'باسکی',
 				'ewo' => 'اواندویی',
 				'fa' => 'پارسی',
 				'ff' => 'فولایی',
 				'fi' => 'فنلاندی',
 				'fil' => 'فلیپینی',
 				'fj' => 'فیجی',
 				'fo' => 'فاروئی',
 				'fon' => 'فون',
 				'fr' => 'فرانسوی',
 				'fr_CA' => 'کاناڈاین فرانسوی',
 				'fr_CH' => 'اشاره‌این فرانسوی',
 				'fur' => 'فریولی',
 				'fy' => 'روچ‌کپتین فریزی',
 				'ga' => 'ایرلندی',
 				'gaa' => 'گا',
 				'gd' => 'اسکاتلندی گیلی',
 				'gez' => 'گعزی',
 				'gil' => 'گیلبیرتی',
 				'gl' => 'گالیسی',
 				'gn' => 'گوارانی',
 				'gor' => 'گورونتالو',
 				'gsw' => 'جرمنین سوئیسی',
 				'gu' => 'گوجراتی',
 				'guz' => 'گوسی',
 				'gv' => 'مانی',
 				'gwi' => 'گویچنی',
 				'ha' => 'هوسه‌ای',
 				'haw' => 'هاوایی',
 				'he' => 'عبرانی',
 				'hi' => 'هندی',
 				'hil' => 'هیلیگایونی',
 				'hmn' => 'همونگی',
 				'hr' => 'کراوتی',
 				'hsb' => 'علیای سیربی',
 				'ht' => 'کریول آییسینی',
 				'hu' => 'مجارستانی',
 				'hup' => 'هوپی',
 				'hy' => 'ارمنی',
 				'hz' => 'هرویی',
 				'ia' => 'اینترلینگوایی',
 				'iba' => 'ایبانگه',
 				'ibb' => 'ایبیبیو',
 				'id' => 'ایندونیزیایی',
 				'ig' => 'ایگبویی',
 				'ii' => 'یی سیچوان',
 				'ilo' => 'ایلوکانوی',
 				'inh' => 'اینگوشی',
 				'io' => 'ایدوی',
 				'is' => 'ایسلندی',
 				'it' => 'ایتالیایی',
 				'iu' => 'اینوکتیتوتی',
 				'ja' => 'جاپانی',
 				'jbo' => 'لوجبانی',
 				'jgo' => 'نگومبی',
 				'jmc' => 'ماچامه‌ای',
 				'jv' => 'جاوه‌ای',
 				'ka' => 'گرجی',
 				'kab' => 'قبایلی',
 				'kac' => 'کاچینی',
 				'kaj' => 'جیجو',
 				'kam' => 'کامبایی',
 				'kbd' => 'کاباردینی',
 				'kcg' => 'تیاپی',
 				'kde' => 'ماکوندی',
 				'kea' => 'کابووردیانو',
 				'kfo' => 'کورو',
 				'kha' => 'خاسی',
 				'khq' => 'کوجراچینی',
 				'ki' => 'کیکویویی',
 				'kj' => 'کوانیامایی',
 				'kk' => 'قزاقی',
 				'kkj' => 'کاکویی',
 				'kl' => 'گرینلندی',
 				'kln' => 'کالنجین',
 				'km' => 'خمری',
 				'kmb' => 'کیمبوندویی',
 				'kn' => 'کانارا',
 				'ko' => 'کوریایی',
 				'kok' => 'کونکانی',
 				'kpe' => 'کپله‌ای',
 				'kr' => 'کانوری',
 				'krc' => 'قره‌چایی‐بالکاری',
 				'krl' => 'کاریلینی',
 				'kru' => 'کوروخی',
 				'ks' => 'کشمیری',
 				'ksb' => 'شامبالای',
 				'ksf' => 'بافیا',
 				'ksh' => 'کولوگنی',
 				'ku' => 'کوردی',
 				'kum' => 'کومیکی',
 				'kv' => 'کومی',
 				'kw' => 'کورنی',
 				'ky' => 'قیرغیزی',
 				'la' => 'لاتین',
 				'lad' => 'لادینو',
 				'lag' => 'لانگی',
 				'lb' => 'لوگزامبورگی',
 				'lez' => 'لزگی',
 				'lg' => 'گاندایی',
 				'li' => 'لیمبورگی',
 				'lkt' => 'لاکوتا',
 				'ln' => 'لینگالایی',
 				'lo' => 'لائوسی',
 				'loz' => 'لوزی',
 				'lrc' => 'بُرزسرین لوری',
 				'lt' => 'لیتوانی',
 				'lu' => 'لوبایی‐کاتانگا',
 				'lua' => 'لوبایی‐لولوا',
 				'lun' => 'لوندایی',
 				'luo' => 'لوئویی',
 				'lus' => 'لوشه‌ای',
 				'luy' => 'لویایی',
 				'lv' => 'لاتوینی',
 				'mad' => 'مادورایی',
 				'mag' => 'ماگاهی',
 				'mai' => 'مایدیلی',
 				'mak' => 'ماکاساری',
 				'mas' => 'ماسایی',
 				'mdf' => 'موکشی',
 				'men' => 'منده‌ای',
 				'mer' => 'مرویی',
 				'mfe' => 'موریسینی',
 				'mg' => 'مالاگاسی',
 				'mgh' => 'ماکوا متوی',
 				'mgo' => 'میٹایی',
 				'mh' => 'مارشالی',
 				'mi' => 'مائوری',
 				'mic' => 'میکماکی',
 				'min' => 'مینانگ‌کابویی',
 				'mk' => 'مقدونی',
 				'ml' => 'مالایالامی',
 				'mn' => 'منگولی',
 				'mni' => 'مانیپوری',
 				'moh' => 'موهاکی',
 				'mos' => 'موسیی',
 				'mr' => 'مراٹی',
 				'ms' => 'مالایی',
 				'mt' => 'مالته‌ای',
 				'mua' => 'ماندانگی',
 				'mul' => 'چینکه زبان',
 				'mus' => 'کریکی',
 				'mwl' => 'میراندیسی',
 				'my' => 'بورمي',
 				'myv' => 'ارزیای',
 				'mzn' => 'مازندرانی',
 				'na' => 'نائورویی',
 				'nap' => 'ناپلی',
 				'naq' => 'نامایی',
 				'nb' => 'نارویی بوک‌مولی',
 				'nd' => 'بُرزسرین انده‌بله‌ای',
 				'nds_NL' => 'ساکسونی سفلی',
 				'ne' => 'نیپالی',
 				'new' => 'نیواری',
 				'ng' => 'اندونگی',
 				'nia' => 'نیاسی',
 				'niu' => 'نیویی',
 				'nl' => 'هالنڈی',
 				'nl_BE' => 'فلامانی',
 				'nmg' => 'کوازیو',
 				'nn' => 'نارویی نی‌نوشکی',
 				'nnh' => 'انگی‌ایمبونی',
 				'nog' => 'نغایی',
 				'nqo' => 'نکوی',
 				'nr' => 'جهلسرین انده‌بله‌ای',
 				'nso' => 'بُرزسرین سوتویی',
 				'nus' => 'نویری',
 				'nv' => 'ناواهویی',
 				'ny' => 'نیانجی',
 				'nyn' => 'نیانکوله‌ای',
 				'oc' => 'اوکیتایی',
 				'om' => 'اورومویی',
 				'or' => 'اودیه‌ای',
 				'os' => 'آسیتینی',
 				'pa' => 'پنجاپی',
 				'pag' => 'پانگاسینانی',
 				'pam' => 'پامپانگی',
 				'pap' => 'پاپیامنتوی',
 				'pau' => 'پالائویی',
 				'pcm' => 'نایجیریای پیڈگین',
 				'pl' => 'پولنڈی',
 				'prg' => 'پروسی',
 				'ps' => 'پشتو',
 				'pt' => 'پورتگالی',
 				'pt_BR' => 'برازیلین پورتگالی',
 				'pt_PT' => 'اوروپایین پورتگالی',
 				'qu' => 'کچوایی',
 				'quc' => 'کیچه‌',
 				'rap' => 'راپانویی',
 				'rar' => 'راروتونگی',
 				'rm' => 'رومانش',
 				'rn' => 'رونڈی',
 				'ro' => 'رومانی',
 				'ro_MD' => 'مالداوی',
 				'rof' => 'رومبویی',
 				'ru' => 'اوروسی',
 				'rup' => 'آرومانی',
 				'rw' => 'کینیارواندی',
 				'rwk' => 'روایی',
 				'sa' => 'سانسکریٹ',
 				'sad' => 'سانڈاوه‌ای',
 				'sah' => 'یاقوتی',
 				'saq' => 'سامبوروی',
 				'sat' => 'سانٹالی',
 				'sba' => 'انگامبی',
 				'sbp' => 'سانگویی',
 				'sc' => 'ساردینی',
 				'scn' => 'سیسیلی',
 				'sco' => 'اسکاتلندی',
 				'sd' => 'سیندی',
 				'se' => 'بُرزسرین سامی',
 				'seh' => 'سینایی',
 				'ses' => 'کویرابورا سنی',
 				'sg' => 'سانگۆیی',
 				'shi' => 'تاچل‌هیتی',
 				'shn' => 'شانی',
 				'si' => 'سینهالی',
 				'sk' => 'اسلواکی',
 				'sl' => 'اسلوانی',
 				'sm' => 'ساموآیی',
 				'sma' => 'جهلسرین سامی',
 				'smj' => 'لوله سامی',
 				'smn' => 'اناری سمی',
 				'sms' => 'اسکولت سامی',
 				'sn' => 'شونی',
 				'snk' => 'سونینکه‌ای',
 				'so' => 'سومالی',
 				'sq' => 'البانی',
 				'sr' => 'سیربی',
 				'srn' => 'تاکی‌تاکی',
 				'ss' => 'سواتی',
 				'ssy' => 'ساهویی',
 				'st' => 'جهلسرین سوتویی',
 				'su' => 'سونڈی',
 				'suk' => 'سوکومایی',
 				'sv' => 'سویڈنی',
 				'sw' => 'سواحلی',
 				'sw_CD' => 'کانگویی سواحلی',
 				'swb' => 'قمرین',
 				'syr' => 'سریانی',
 				'ta' => 'تامیلی',
 				'te' => 'تلوگویی',
 				'tem' => 'تیمنه‌ای',
 				'teo' => 'تیسویی',
 				'tet' => 'ٹیٹومی',
 				'tg' => 'تاجیکی',
 				'th' => 'تایلندی',
 				'ti' => 'ٹیگرینیایی',
 				'tig' => 'ٹایگری',
 				'tk' => 'تورکمنی',
 				'tlh' => 'کلینگونی',
 				'tn' => 'تسوانی',
 				'to' => 'تونگی',
 				'tpi' => 'توک‌پیسینی',
 				'tr' => 'تورکی',
 				'trv' => 'تاروکویی',
 				'ts' => 'تسونگی',
 				'tt' => 'تاتاری',
 				'tum' => 'تومبوکی',
 				'tvl' => 'ٹووالی',
 				'twq' => 'تسواکی',
 				'ty' => 'تاهیتی',
 				'tyv' => 'ٹووینی',
 				'tzm' => 'مرکزین اتلسین تامازیگتی',
 				'udm' => 'اوڈمورتی',
 				'ug' => 'اویغوری',
 				'uk' => 'اوکراینی',
 				'umb' => 'امبونڈویی',
 				'und' => 'نازانتین زبان',
 				'ur' => 'اوردو',
 				'uz' => 'اوزبکی',
 				'vai' => 'وایی',
 				've' => 'وینڈایی',
 				'vi' => 'ویتنامی',
 				'vo' => 'ولاپوکی',
 				'vun' => 'ونجو',
 				'wa' => 'والونی',
 				'wae' => 'والسیری',
 				'wal' => 'وولایٹی',
 				'war' => 'واری',
 				'wo' => 'ولوفی',
 				'xal' => 'کالمیکی',
 				'xh' => 'خوسی',
 				'xog' => 'سوگایی',
 				'yav' => 'یانگبینی',
 				'ybb' => 'یمبی',
 				'yi' => 'یدی',
 				'yo' => 'یوروبایی',
 				'yue' => 'کانتونیونی',
 				'zgh' => 'آمازیغی مراکشی معیار',
 				'zh' => 'چینایی',
 				'zh_Hans' => 'ساده‌گین چینایی',
 				'zh_Hant' => 'غدیمین چینایی',
 				'zu' => 'زولویی',
 				'zun' => 'زونی',
 				'zxx' => 'بغیر شه زبانین لڑا',
 				'zza' => 'زازایی',

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
 			'Deva' => 'دیوانگری',
 			'Ethi' => 'گعزی',
 			'Geor' => 'گورجی',
 			'Grek' => 'یونانی',
 			'Gujr' => 'گوجراتی',
 			'Guru' => 'گرمکهی',
 			'Hanb' => 'هانب',
 			'Hang' => 'هانگول',
 			'Hani' => 'هانی',
 			'Hebr' => 'عبرانی',
 			'Jpan' => 'جاپانی',
 			'Kore' => 'کوریایی',
 			'Latn' => 'لاتین',
 			'Taml' => 'تامیلی',
 			'Thai' => 'تایی',
 			'Zsym' => 'سمولان',
 			'Zzzz' => 'نامالومین خط',

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
			'001' => 'دونیا/جهان',
 			'002' => 'افریقا',
 			'009' => 'اوقیانوسیه',
 			'019' => 'امریکای براعظم',
 			'053' => 'استرالیا',
 			'142' => 'اسیا',
 			'150' => 'اورورپا',
 			'AE' => 'متحدین عربین امارات',
 			'AI' => 'انگویلا',
 			'AO' => 'انگولا',
 			'AR' => 'ارجنٹاین',
 			'AU' => 'اسٹرالیا',
 			'AZ' => 'آزربایجان',
 			'BE' => 'بیلجیم',
 			'BG' => 'بولغاریه',
 			'BH' => 'بحرین',
 			'BI' => 'بروندی',
 			'BM' => 'بیرمودا',
 			'BN' => 'برونی',
 			'BO' => 'بولیویه',
 			'BR' => 'برازیل',
 			'BS' => 'بهاماس',
 			'BT' => 'بوتان',
 			'CA' => 'کاناڈا',
 			'CL' => 'چیلی',
 			'CM' => 'کامیرون',
 			'CN' => 'چین',
 			'CO' => 'کولومبیا',
 			'CU' => 'کوبا',
 			'CY' => 'قبرس',
 			'DE' => 'جرمنی',
 			'DJ' => 'جیبوتی',
 			'DZ' => 'الجزایر',
 			'EC' => 'اکوادور',
 			'EG' => 'مصر',
 			'EH' => 'روچ‌کپتین سحرا',
 			'ER' => 'اریتره',
 			'ES' => 'هسپانیه',
 			'ET' => 'ایتوپیه',
 			'EU' => 'اورورپایی یکویی',
 			'FJ' => 'فیجی',
 			'FR' => 'فرانسه',
 			'GA' => 'گابون',
 			'GE' => 'گرجستان',
 			'GH' => 'گانا',
 			'GL' => 'گرینلاند',
 			'GM' => 'گامبیا',
 			'GN' => 'گوینیا',
 			'GR' => 'یونان',
 			'GY' => 'گویانا',
 			'HK' => 'هانگ کانگ',
 			'HU' => 'هنگری',
 			'ID' => 'ایندونیزیا',
 			'IL' => 'اسرائیل',
 			'IQ' => 'عراق',
 			'IT' => 'ایتالیه',
 			'JO' => 'اردن',
 			'KE' => 'کینیا',
 			'KG' => 'قیرغیزستان',
 			'KH' => 'کمبودیا',
 			'KM' => 'کومورس',
 			'KW' => 'کویٹ',
 			'KZ' => 'قزاقستان',
 			'LA' => 'لاوس',
 			'LB' => 'لیبنان',
 			'LY' => 'لیبیا',
 			'MA' => 'مراکو',
 			'MD' => 'مالداویا',
 			'MG' => 'ماداگاسکار',
 			'ML' => 'مالی',
 			'MT' => 'مالته',
 			'MU' => 'موریتانیا',
 			'MX' => 'مکسیکو',
 			'MY' => 'مالیزیا',
 			'NE' => 'نیجیر',
 			'NG' => 'نایجیریا',
 			'NZ' => 'نیوزلنڈ',
 			'OM' => 'ئومان',
 			'PA' => 'پانامه',
 			'PE' => 'پیرو',
 			'PH' => 'فلیپین',
 			'PT' => 'پورتگال',
 			'PY' => 'پاراگوی',
 			'QA' => 'قطر',
 			'RO' => 'رومانیه',
 			'RS' => 'سیربستان',
 			'RW' => 'روندا',
 			'SC' => 'سیشیل',
 			'SD' => 'سوڈان',
 			'SG' => 'سینگاپور',
 			'SN' => 'سینیگال',
 			'SO' => 'سومالیا',
 			'SR' => 'سورینامی',
 			'SY' => 'سوریه',
 			'TD' => 'چاد',
 			'TH' => 'ٹایلنڈ',
 			'TJ' => 'تاجیکستان',
 			'TM' => 'تورکمنستان',
 			'TN' => 'ٹونیس',
 			'TZ' => 'تانزانیا',
 			'UG' => 'اوگاندا',
 			'US' => 'متحدین ایالات',
 			'UY' => 'اوراگوی',
 			'UZ' => 'اوزبکیستان',
 			'VE' => 'وینزوویلا',
 			'VN' => 'ویتنام',
 			'YE' => 'یمن',
 			'ZM' => 'زامبیا',
 			'ZW' => 'زیمبابوی',
 			'ZZ' => 'نازانتین سیمسر',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{میٹریک},
 			'UK' => q{بریتانوی},
 			'US' => q{امریکایی},

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
			auxiliary => qr{[‌ ؤ]},
			index => ['آ', 'ئ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ٹ', 'ج', 'چ', 'ح', 'خ', 'د', 'ڈ', 'ر', 'ز', 'ڑ', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ھ', 'و', 'ۆ', 'ی', 'ێ'],
			main => qr{[آ ئ ا ب پ ت ث ٹ ج چ ح خ د ڈ ر ز ڑ ژ س ش ص ض ط ظ غ ف ق ک گ ل م ن ھ و ۆ ی ێ]},
			punctuation => qr{[‐ – — ، ؛ \: ! ؟ . … ‘’ "“” « » ( ) \[ \] § @ * \\ \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['آ', 'ئ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ٹ', 'ج', 'چ', 'ح', 'خ', 'د', 'ڈ', 'ر', 'ز', 'ڑ', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ھ', 'و', 'ۆ', 'ی', 'ێ'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} روچئ تا),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} روچئ تا),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} ساعتئ تا),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} ساعتئ تا),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'per' => q({0} دقیقه‌ای تا),
					},
					# Core Unit Identifier
					'minute' => {
						'per' => q({0} دقیقه‌ای تا),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} به ماه‌ای تا),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} به ماه‌ای تا),
					},
					# Long Unit Identifier
					'duration-second' => {
						'per' => q({0} ثانیه‌ای تا),
					},
					# Core Unit Identifier
					'second' => {
						'per' => q({0} ثانیه‌ای تا),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0} هفته‌گئ تا),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0} هفته‌گئ تا),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} سالئ تا),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} سالئ تا),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'per' => q({0} کیلومیترئ تا),
					},
					# Core Unit Identifier
					'kilometer' => {
						'per' => q({0} کیلومیترئ تا),
					},
					# Long Unit Identifier
					'length-meter' => {
						'per' => q({0} میترئ تا),
					},
					# Core Unit Identifier
					'meter' => {
						'per' => q({0} میترئ تا),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0}روچ),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0}روچ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0}ساعت),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0}ساعت),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0}میلی‌ثانیه),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0}میلی‌ثانیه),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0}دقیقه),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0}دقیقه),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0}ماه),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0}ماه),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0}ث),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0}ث),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0}هفته‌گ),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0}هفته‌گ),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'other' => q({0}کیلومیتر),
					},
					# Core Unit Identifier
					'kilometer' => {
						'other' => q({0}کیلومیتر),
					},
					# Long Unit Identifier
					'length-meter' => {
						'other' => q({0}میتر),
					},
					# Core Unit Identifier
					'meter' => {
						'other' => q({0}میتر),
					},
				},
				'short' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(روچ‌دراتین {0}),
						'north' => q(بُرزسرین {0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(روچ‌دراتین {0}),
						'north' => q(بُرزسرین {0}),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(سده‌گ),
						'other' => q({0} سده‌گ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(سده‌گ),
						'other' => q({0} سده‌گ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(روچ),
						'other' => q({0} روچ),
						'per' => q({0}/روچ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(روچ),
						'other' => q({0} روچ),
						'per' => q({0}/روچ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ساعت),
						'other' => q({0} ساعت),
						'per' => q({0}/ساعت),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ساعت),
						'other' => q({0} ساعت),
						'per' => q({0}/ساعت),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(مایکروثانیه),
						'other' => q({0} مایکروثانیه),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(مایکروثانیه),
						'other' => q({0} مایکروثانیه),
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
						'per' => q({0}/دقیقه),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(دقیقه),
						'other' => q({0} دقیقه),
						'per' => q({0}/دقیقه),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
						'per' => q({0}/ماه),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ماه),
						'other' => q({0} ماه),
						'per' => q({0}/ماه),
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
						'per' => q({0}/ث),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ثانیه),
						'other' => q({0} ثانیه),
						'per' => q({0}/ث),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(هفته‌گ),
						'other' => q({0} هفته‌گ),
						'per' => q({0}/هفته‌گ),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(هفته‌گ),
						'other' => q({0} هفته‌گ),
						'per' => q({0}/هفته‌گ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(سال),
						'other' => q({0} سال),
						'per' => q({0}/سال),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(سال),
						'other' => q({0} سال),
						'per' => q({0}/سال),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(کیلومیتر),
						'other' => q({0} کیلومیتر),
						'per' => q({0}/کیلومیتر),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(کیلومیتر),
						'other' => q({0} کیلومیتر),
						'per' => q({0}/کیلومیتر),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(میتر),
						'other' => q({0} میتر),
						'per' => q({0}/میتر),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(میتر),
						'other' => q({0} میتر),
						'per' => q({0}/میتر),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:هان|هاو|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:نه|ن|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}، {1}),
				middle => q({0}، {1}),
				end => q({0}، و {1}),
				2 => q({0} و {1}),
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
		'latn' => {
			'decimal' => q(٫),
			'group' => q(،),
			'nan' => q(ناعدد),
			'percentSign' => q(٪),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AFN' => {
			symbol => '؋',
			display_name => {
				'currency' => q(اوگانستانئ اوگانی),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(بنگلادیشئ ٹاکه),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(بوتانئ انگولٹروم),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(هندوستانئ روپی),
			},
		},
		'IRR' => {
			symbol => 'ریال',
			display_name => {
				'currency' => q(ایرانئ ریال),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(سریلانکایی روپی),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(مالدیوی روپی),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(نیپالین روپی),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(پاکستانئ روپی),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(روسین روبل),
			},
		},
	} },
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Afghanistan' => {
			long => {
				'standard' => q#اوگانستانی وخت#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#عدن#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#الماته#,
		},
		'Asia/Amman' => {
			exemplarCity => q#امان#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#اقتاو#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#اقتوبه#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#عشق آبات#,
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
		'Asia/Bishkek' => {
			exemplarCity => q#بیشکیک#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#کلکته#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#کولومبو#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#دمشق#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ڈاکا#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#دوبی#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#دوشنبه#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#غزه#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#یورشلیم#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#کابل#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#کراچی#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#کٹمنڈو#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#کویٹ#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#مسقط#,
		},
		'Asia/Oral' => {
			exemplarCity => q#اورال#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#قطر#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#قیزیلوردا#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#ریاض#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#سمرقند#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#سیول#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#تاشکینت#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#تیبلیسی#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#تهران#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#ٹیمپو#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#توکیو#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#تومسک#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#اولان‌باتور#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#اورمچی#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#نازانتین شاران#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#استانبول#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#کیروف#,
		},
		'Europe/Samara' => {
			exemplarCity => q#سامارا#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#مالدیف#,
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#روچ‌دراتین قزاقستانی وخت#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#روچ‌کپتین قزاقستانی وخت#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#قیرغیزستانی وخت#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#تاجیکستانی وخت#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
