=encoding utf8

=head1

Locale::CLDR::Locales::Lrc - Package for language Northern Luri

=cut

package Locale::CLDR::Locales::Lrc;
# This file auto generated from Data\common\main\lrc.xml
#	on Sun  3 Feb  2:03:23 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(منفی →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(صفر),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← مومٱیز →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(یٱک),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(دۏ),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ساٛ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(چار),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(پنج),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(شٱش),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(هفت),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(هشت),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(نۏ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(دٱ),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(یازدٱ),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(دۊۋازدٱ),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(سینزٱ),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(چاردٱ),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(پۊمزٱ),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(شۊمزٱ),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(هاٛبدٱ),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(هیژدٱ),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(نۊزدٱ),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(بیست[ و →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(سی[ و →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(چاٛهل[ و →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(پنجا[ و →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(شٱصد[ و →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(هفتاد[ و →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(هشتاد[ و →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(نٱۋد[ و →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(صد[ و →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(داٛۋیسد[ و →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(سیصد[ و →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(چارصد[ و →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(پۊمصد[ و →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(شٱشصد[ و →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(هفصد[ و →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(هشصد[ و →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(نۏصد[ و →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← هزار[ و →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← ماٛلیۊن[ و →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← میلیارد[ و →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← هزار میلیاد[ و →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
	} },
);

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
				'ab' => 'آذأربایئجانی',
 				'af' => 'آفریکانس',
 				'agq' => 'آقئم',
 				'ak' => 'آکان',
 				'am' => 'أمھأری',
 				'ar' => 'أرأڤی',
 				'ar_001' => 'عروی مدرن',
 				'arn' => 'ماپوٙچئ',
 				'as' => 'آسامی',
 				'asa' => 'آسوٙ',
 				'az' => 'آذأربایئجانی ھارگە',
 				'az@alt=short' => 'آذأری',
 				'az_Arab' => 'آذأری ھارگە',
 				'ba' => 'باشکیری',
 				'be' => 'بئلاروٙسی',
 				'bem' => 'بیما',
 				'bez' => 'بئنا',
 				'bg' => 'بولغاری',
 				'bgn' => 'بألوٙچی أقتوٙنئشین',
 				'bm' => 'بامبارا',
 				'bn' => 'بأنگالی',
 				'bo' => 'تأبأتی',
 				'br' => 'بئرئتون',
 				'brx' => 'بودو',
 				'bs' => 'بوسنیایی',
 				'ca' => 'کاتالان',
 				'ce' => 'چئچئنی',
 				'cgg' => 'چیگا',
 				'chr' => 'چوروٙکی',
 				'ckb' => 'کوردی سوٙرانی',
 				'co' => 'کوریسکان',
 				'cv' => 'چواشی',
 				'cy' => 'ڤئلزی',
 				'da' => 'دانمارکی',
 				'dav' => 'تایتا',
 				'de' => 'آلمانی',
 				'de_AT' => 'آلمانی ئوتریشی',
 				'de_CH' => 'آلمانی سوٙییسی',
 				'dje' => 'زارما',
 				'dsb' => 'سوربی ھاری',
 				'dua' => 'دوٙالا',
 				'dyo' => 'جولا فوٙنیی',
 				'dz' => 'زوٙنگخا',
 				'ebu' => 'ئمبو',
 				'ee' => 'ئڤئ',
 				'el' => 'یوٙنانی',
 				'en' => 'ئینگیلیسی',
 				'en_AU' => 'ئینگیلیسی ئوستارالیایی',
 				'en_CA' => 'ئینگیلیسی کانادایی',
 				'en_GB' => 'ئینگیلیسی بئریتانیایی',
 				'en_GB@alt=short' => 'ئینگیلیسی بئریتانیا گأپ',
 				'en_US' => 'ئینگیلیسی ئمریکایی',
 				'en_US@alt=short' => 'ئینگیلیسی ئمریکایی',
 				'eo' => 'ئسپئرانتو',
 				'es' => 'ئسپانیایی',
 				'es_419' => 'ئسپانیایی ئمریکا لاتین',
 				'es_ES' => 'ئسپانیایی ئوروٙپا',
 				'es_MX' => 'ئسپانیایی مئکزیک',
 				'et' => 'ئستونیایی',
 				'eu' => 'باسکی',
 				'fa' => 'فارسی',
 				'fi' => 'فأنلاندی',
 				'fil' => 'فیلیپینی',
 				'fj' => 'فیجی',
 				'fo' => 'فاروٙسی',
 				'fr' => 'فآرانسئ ئی',
 				'fr_CA' => 'فآرانسئ ئی کانادا',
 				'fr_CH' => 'فآرانسئ ئی سوٙییس',
 				'fy' => 'فئریسی أفتونئشین',
 				'ga' => 'ئیرلأندی',
 				'gag' => 'گاگائوز',
 				'gl' => 'گالیسی',
 				'gn' => 'گوٙآرانی',
 				'gsw' => 'آلمانی سوٙئیسی',
 				'gu' => 'گوجأراتی',
 				'guz' => 'گوٙسی',
 				'gv' => 'مانکس',
 				'ha' => 'ھائوسا',
 				'haw' => 'ھاڤایی',
 				'he' => 'عئبری',
 				'hi' => 'ھئنی',
 				'hr' => 'کوروڤاتی',
 				'hsb' => 'سوربی ڤارو',
 				'ht' => 'ھاییتی',
 				'hu' => 'مأجاری',
 				'hy' => 'أرمأنی',
 				'id' => 'أندونئزیایی',
 				'ig' => 'ئیگبو',
 				'ii' => 'سی چوان یی',
 				'is' => 'ئیسلأندی',
 				'it' => 'ئیتالیایی',
 				'iu' => 'ئینوکتیتوٙت',
 				'ja' => 'جاپوٙنی',
 				'jgo' => 'نئگوٙمبا',
 				'jmc' => 'ماچامئ',
 				'jv' => 'جاڤئ یی',
 				'ka' => 'گورجی',
 				'kab' => 'کابیلئ',
 				'kam' => 'کامبا',
 				'kde' => 'ماکوٙندئ',
 				'kea' => 'کاباردینو',
 				'khq' => 'کی یورا چینی',
 				'ki' => 'کیکیوٙ',
 				'kk' => 'قأزاق',
 				'kl' => 'کالالیسوٙت',
 				'kln' => 'کالئجین',
 				'km' => 'خئمئر',
 				'kn' => 'کاناد',
 				'ko' => 'کورئ یی',
 				'koi' => 'کومی پئرمیاک',
 				'kok' => 'کوٙنکانی',
 				'ks' => 'کأشمیری',
 				'ksb' => 'شامبالا',
 				'ksf' => 'بافیا',
 				'ku' => 'کوردی کورمانجی',
 				'kw' => 'کورنیش',
 				'ky' => 'قئرقیزی',
 				'la' => 'لاتین',
 				'lag' => 'لانگی',
 				'lb' => 'لوٙکزامبوٙرگی',
 				'lg' => 'گاندا',
 				'lkt' => 'لاکوٙتا',
 				'ln' => 'لینگالا',
 				'lo' => 'لاو',
 				'lrc' => 'لۊری شومالی',
 				'lt' => 'لیتوڤانیایی',
 				'lu' => 'لوٙبا کاتانگا',
 				'luo' => 'لوٙ',
 				'luy' => 'لوٙئیا',
 				'lv' => 'لاتوڤیایی',
 				'mas' => 'ماسایی',
 				'mer' => 'مئرو',
 				'mfe' => 'موٙریسی',
 				'mg' => 'مالاگاشی',
 				'mgh' => 'ماخوڤا میتو',
 				'mgo' => 'مئتاٛ',
 				'mi' => 'مائوری',
 				'mk' => 'مأقدوٙنی',
 				'ml' => 'مالایام',
 				'mn' => 'موغولی',
 				'moh' => 'موٙھاڤک',
 				'mr' => 'مأراتی',
 				'ms' => 'مالایی',
 				'mt' => 'مالتی',
 				'mua' => 'موٙندانگ',
 				'my' => 'بئرمئ یی',
 				'mzn' => 'مازأندأرانی',
 				'naq' => 'ناما',
 				'nb' => 'نورڤئجی بوٙکمال',
 				'nd' => 'نئدئبئلئ شومالی',
 				'nds' => 'آلمانی ھاری',
 				'nds_NL' => 'آلمانی ھارگە جا',
 				'ne' => 'نئپالی',
 				'nl' => 'ھولأندی',
 				'nl_BE' => 'فئلاماندی',
 				'nmg' => 'کئڤاسیوٙ',
 				'nn' => 'نورڤئجی نینورسک',
 				'nqo' => 'نئکوٙ',
 				'nus' => 'نیوٙئر',
 				'nyn' => 'نیان کوٙلئ',
 				'om' => 'ئوروموٙ',
 				'or' => 'ئوریا',
 				'pa' => 'پأنجابی',
 				'pl' => 'لأھئستانی',
 				'ps' => 'پأشتوٙ',
 				'pt' => 'پورتئغالی',
 				'pt_BR' => 'پورتئغالی بئرئزیل',
 				'pt_PT' => 'پورتئغالی ئوروٙپایی',
 				'qu' => 'کوچوٙا',
 				'quc' => 'کیچی',
 				'rm' => 'رومانش',
 				'rn' => 'راندی',
 				'ro' => 'رومانیایی',
 				'ro_MD' => 'رومانیایی مولداڤی',
 				'rof' => 'رومبو',
 				'ru' => 'روٙسی',
 				'rw' => 'کینیاروآندا',
 				'rwk' => 'رئڤا',
 				'sa' => 'سانسکئریت',
 				'saq' => 'سامبوٙروٙ',
 				'sbp' => 'سانگوٙ',
 				'sd' => 'سئندی',
 				'sdh' => 'کوردی ھارگە',
 				'se' => 'سامی شومالی',
 				'seh' => 'سئنا',
 				'ses' => 'کیارابورو سئنی',
 				'sg' => 'سانگو',
 				'shi' => 'تاچئلھیت',
 				'si' => 'سینھالا',
 				'sk' => 'ئسلوڤاکی',
 				'sl' => 'ئسلوڤئنیایی',
 				'sma' => 'سامی ھارگە',
 				'smj' => 'لۉلئ سامی',
 				'smn' => 'ئیناری سامی',
 				'sms' => 'ئسکولت سامی',
 				'sn' => 'شونا',
 				'so' => 'سوٙمالی',
 				'sq' => 'آلبانی',
 				'sr' => 'سئربی',
 				'su' => 'سوٙدانی',
 				'sv' => 'سوٙئدی',
 				'sw' => 'سأڤاحیلی',
 				'sw_CD' => 'سأڤاحیلی کونگو',
 				'ta' => 'تامیل',
 				'te' => 'تئلئگو',
 				'teo' => 'تئسو',
 				'tg' => 'تاجیکی',
 				'th' => 'تایلأندی',
 				'ti' => 'تیگرینیا',
 				'tk' => 'تورکأمأنی',
 				'to' => 'توٙنگان',
 				'tr' => 'تورکی',
 				'tt' => 'تاتار',
 				'twq' => 'تاساڤاق',
 				'tzm' => 'تامازیغ مینجایی',
 				'ug' => 'ئویغوٙر',
 				'uk' => 'ئوکراینی',
 				'und' => 'زوٙن نادیار',
 				'ur' => 'ئوردوٙ',
 				'uz' => 'ئوزبأکی',
 				'vai' => 'ڤای',
 				'vi' => 'ڤییئتنامی',
 				'vun' => 'ڤوٙنجوٙ',
 				'wbp' => 'ڤارلپیری',
 				'wo' => 'ڤولوف',
 				'xh' => 'خوٙسا',
 				'xog' => 'سوٙگا',
 				'yo' => 'یوروبا',
 				'zgh' => 'تامازیغ مأراکئشی',
 				'zh' => 'چینی',
 				'zh_Hans' => 'چینی سادە بیە',
 				'zh_Hant' => 'چینی سونأتی',
 				'zu' => 'زولو',
 				'zxx' => 'بی نئشوٙ',

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
			'Arab' => 'عأرأڤی',
 			'Armn' => 'أرمأنی',
 			'Beng' => 'بأنگالی',
 			'Bopo' => 'بوٙپوٙ',
 			'Brai' => 'بئرئیل',
 			'Cyrl' => 'سیریلیک',
 			'Deva' => 'دیڤانگأری',
 			'Ethi' => 'ئتوٙیوٙپیایی',
 			'Geor' => 'گورجی',
 			'Grek' => 'یوٙنانی',
 			'Gujr' => 'گوجأراتی',
 			'Guru' => 'گوٙروٙمخی',
 			'Hang' => 'ھانگوٙل',
 			'Hani' => 'ھانی',
 			'Hans' => 'سادە بیە',
 			'Hans@alt=stand-alone' => 'بیتار سادە بیە',
 			'Hant' => 'سونأتی',
 			'Hant@alt=stand-alone' => 'سونأتی بیتار',
 			'Hebr' => 'عئبری',
 			'Hira' => 'ھیراگانا',
 			'Jpan' => 'جاپوٙنی',
 			'Kana' => 'کاتانگا',
 			'Khmr' => 'خئمئر',
 			'Knda' => 'کانادا',
 			'Kore' => 'کورئ یی',
 			'Laoo' => 'لائو',
 			'Latn' => 'لاتین',
 			'Mlym' => 'مالایام',
 			'Mong' => 'موغولی',
 			'Mymr' => 'میانمار',
 			'Orya' => 'ئوریا',
 			'Sinh' => 'سیناھالا',
 			'Taml' => 'تامیل',
 			'Telu' => 'تئلئگو',
 			'Thaa' => 'تانا',
 			'Thai' => 'تایلأندی',
 			'Tibt' => 'تأبأتی',
 			'Zsym' => 'نئشوٙنە یا',
 			'Zxxx' => 'نیسئسە نأبیە',
 			'Zyyy' => 'جائوفتاأ',
 			'Zzzz' => 'نیسئسە نادیار',

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
			'001' => 'دونیا',
 			'002' => 'ئفریقا',
 			'003' => 'ئمریکا شومالی',
 			'005' => 'ئمریکا ھارگە',
 			'009' => 'ھوم پئڤأند جأھوٙن آڤ',
 			'013' => 'مینجا ئمریکا',
 			'019' => 'ئمریکا',
 			'021' => 'ئمریکا ڤارو',
 			'029' => 'کارائیب',
 			'142' => 'آسیا',
 			'150' => 'ئوروٙپا',
 			'419' => 'ئمریکا لاتین',
 			'BR' => 'بئرئزیل',
 			'CN' => 'چین',
 			'DE' => 'آلمان',
 			'FR' => 'فأرانسە',
 			'GB' => 'بیریتانیا گأپ',
 			'IN' => 'ھئن',
 			'IT' => 'ئیتالیا',
 			'JP' => 'جاپوٙن',
 			'RU' => 'روٙسیە',
 			'US' => 'ڤولاتیا یأکاگئرتە',
 			'ZZ' => 'راساگە نادیار',

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
 				'gregorian' => q{تأقڤیم گأرئگوٙری},
 			},
 			'collation' => {
 				'standard' => q{کوٙلاتی ئستاندارد},
 			},
 			'numbers' => {
 				'arab' => q{أدأدیا عأرأڤی},
 				'latn' => q{عأدأدیا لاتین},
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
			'metric' => q{مئتری},
 			'UK' => q{بئریتانیا گأپ},
 			'US' => q{ڤولاتیا یأکاگئرته},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

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
			auxiliary => qr{[​‌‍‎‏ ً ٌ ٍ َ ُ ِ ّ ْ ٔ إ ة ك ه ى ي]},
			index => ['آ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ج', 'چ', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ھ', 'و', 'ی'],
			main => qr{[ٙ ٛ آ أ ؤ ئ ا ب پ ت ث ج چ ح خ د ذ ر ز ژ س ش ص ض ط ظ ع غ ف ڤ ق ک گ ل م ن ھ ە و ۉ ۊ ی ؽ]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ، ٫ ٬ ؛ \: ! ؟ . … ‹ › « » ( ) \[ \] * / \\]},
		};
	},
EOT
: sub {
		return { index => ['آ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ج', 'چ', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ھ', 'و', 'ی'], };
},
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
					'square-kilometer' => {
						'other' => q({0} km²),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:هأری|ه|yes|y)$' }
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
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
			'minusSign' => q(-),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
		'latn' => {
			'pattern' => {
				'default' => {
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
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(رئال بئرئزیل),
				'other' => q(رئال بئرئزیل),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(یوان چین),
				'other' => q(یوان چین),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(یورو),
				'other' => q(یورو),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(پوند بئریتانیا),
				'other' => q(پوند بئریتانیا),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(روٙپیه هئن),
				'other' => q(روٙپیه هئن),
			},
		},
		'IQD' => {
			symbol => 'د.ع.‏',
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(یئن جاپوٙن),
				'other' => q(یئن جاپوٙن),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(روٙبل روٙسیه),
				'other' => q(روٙبل روٙسیه),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(USD),
				'other' => q(USD),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(پیل نادیار),
				'other' => q(پیل نادیار),
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
							'جانڤیە',
							'فئڤریە',
							'مارس',
							'آڤریل',
							'مئی',
							'جوٙأن',
							'جوٙلا',
							'آگوست',
							'سئپتامر',
							'ئوکتوڤر',
							'نوڤامر',
							'دئسامر'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جانڤیە',
							'فئڤریە',
							'مارس',
							'آڤریل',
							'مئی',
							'جوٙأن',
							'جوٙلا',
							'آگوست',
							'سئپتامر',
							'ئوکتوڤر',
							'نوڤامر',
							'دئسامر'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'جانڤیە',
							'فئڤریە',
							'مارس',
							'آڤریل',
							'مئی',
							'جوٙأن',
							'جوٙلا',
							'آگوست',
							'سئپتامر',
							'ئوکتوڤر',
							'نوڤامر',
							'دئسامر'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جانڤیە',
							'فئڤریە',
							'مارس',
							'آڤریل',
							'مئی',
							'جوٙأن',
							'جوٙلا',
							'آگوست',
							'سئپتامر',
							'ئوکتوڤر',
							'نوڤامر',
							'دئسامر'
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
						mon => 'Mon',
						tue => 'Tue',
						wed => 'Wed',
						thu => 'Thu',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Sun'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					wide => {
						mon => 'Mon',
						tue => 'Tue',
						wed => 'Wed',
						thu => 'Thu',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Sun'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mon',
						tue => 'Tue',
						wed => 'Wed',
						thu => 'Thu',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Sun'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					wide => {
						mon => 'Mon',
						tue => 'Tue',
						wed => 'Wed',
						thu => 'Thu',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Sun'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'چارأک أڤأل',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'چارأک أڤأل',
						1 => 'چارأک دویوم',
						2 => 'چارأک سئیوم',
						3 => 'چارأک چاروم'
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
					'pm' => q{PM},
					'am' => q{AM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
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
				'0' => 'BCE',
				'1' => 'CE'
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
			'full' => q{G y MMMM d, EEEE},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{y MMMM d, EEEE},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
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
			fallback => '{0} – {1}',
		},
		'gregorian' => {
			fallback => '{0} – {1}',
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0}),
		'America_Central' => {
			long => {
				'daylight' => q#روٙشنایی نئهادار روٙز#,
				'generic' => q#گاٛت مینجاٛیی#,
				'standard' => q#گاٛت مینجاٛیی ئستاٛنداٛرد#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#نادیار#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
