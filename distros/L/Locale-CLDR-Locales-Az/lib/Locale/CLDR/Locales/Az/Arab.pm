=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Az::Arab - Package for language Azerbaijani

=cut

package Locale::CLDR::Locales::Az::Arab;
# This file auto generated from Data\common\main\az_Arab.xml
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
				'ab' => 'آبخازجا',
 				'af' => 'آفریکانس',
 				'agq' => 'آقمجه',
 				'ak' => 'آکانجا',
 				'am' => 'آمهارجا',
 				'ar' => 'عربجه',
 				'ar_001' => 'استاندارد عربجه',
 				'as' => 'آسامجا',
 				'asa' => 'آسوجا',
 				'az' => 'آذربایجان تۆرکجه‌سی',
 				'az@alt=short' => 'آذریجه',
 				'az_Arab' => 'تۆرکجه',
 				'ba' => 'باشقیرجا',
 				'be' => 'بئلاروسجا',
 				'bem' => 'بئمباجا',
 				'bez' => 'بئناجا',
 				'bg' => 'بۇلقارجا',
 				'bgn' => 'دوْغو بلوچجا',
 				'bm' => 'بامباراجا',
 				'bn' => 'بنگالجا',
 				'br' => 'برئتونجا',
 				'brx' => 'بوْدوجا',
 				'bs' => 'بوْسنیاجا',
 				'ca' => 'کاتالانجا',
 				'ce' => 'چئچئنجه',
 				'cgg' => 'چیقاجا',
 				'chr' => 'چئروکیجه',
 				'ckb' => 'اوْرتا کۆردجه',
 				'co' => 'کوْرسیکاجا',
 				'cs' => 'چئکجه',
 				'cv' => 'چۇواشجا',
 				'da' => 'دانجا',
 				'de' => 'آلمانجا',
 				'dua' => 'دۇالاجا',
 				'dz' => 'دزونگخا',
 				'ebu' => 'ائمبوجا',
 				'ee' => 'اِوه‌جه',
 				'el' => 'یونانجا',
 				'en' => 'اینگیلیزجه',
 				'eo' => 'اِسپرانتو',
 				'es' => 'اسپانیاجا',
 				'es_419' => 'لاتین آمریکا اسپانیاجاسی',
 				'es_ES' => 'اۇروپا اسپانیاجاسی',
 				'es_MX' => 'مکزیک اسپانیاجاسی',
 				'et' => 'اِستونجا',
 				'eu' => 'باسکجا',
 				'fa' => 'فارسجا',
 				'fi' => 'فینجه',
 				'fil' => 'فیلیپینجه',
 				'fj' => 'فیجیجه',
 				'fo' => 'فاروئه‌جه',
 				'fr' => 'فرانساجا',
 				'gag' => 'قاقائوزجا',
 				'gl' => 'قالیسیاجا',
 				'gsw' => 'سویس آلمانجاسی',
 				'he' => 'عبریجه',
 				'hi' => 'هیندجه',
 				'hr' => 'کروواسجا',
 				'hy' => 'ائرمنیجه',
 				'it' => 'ایتالیاجا',
 				'ja' => 'ژاپونجا',
 				'ka' => 'گۆرجوجه',
 				'kk' => 'قازاقجا',
 				'km' => 'خمئرجه',
 				'ko' => 'کوْره‌جه',
 				'ks' => 'کشمیرجه',
 				'ksf' => 'بافیاجا',
 				'ku' => 'کۆردجه',
 				'kw' => 'کوْرنجا',
 				'ky' => 'قیرقیزجا',
 				'la' => 'لاتینجه',
 				'lg' => 'قانداجا',
 				'lrc' => 'قۇزئی لوْرجه',
 				'mk' => 'مقدونیجه',
 				'mn' => 'موْغولجا',
 				'my' => 'بۇرماجا',
 				'mzn' => 'مازنیجه',
 				'nl' => 'هوْلندجه',
 				'pa' => 'پنجابجا',
 				'ps' => 'پشتوجه',
 				'pt' => 'پوْرتغالجه',
 				'ro' => 'رومانیاجا',
 				'ru' => 'روسجا',
 				'sd' => 'سیندیجه',
 				'sdh' => 'گۆنئی کۆردجه',
 				'sk' => 'اسلواکجا',
 				'sq' => 'آلبانیاجا',
 				'sr' => 'صربجه',
 				'sv' => 'سوئدجه',
 				'sw' => 'سواحیلیجه',
 				'sw_CD' => 'کوْنقو سواحیلیسی',
 				'ta' => 'تامیلجه',
 				'tg' => 'تاجیکجه',
 				'tk' => 'تۆرکمنجه',
 				'tr' => 'آنادولو تۆرکجه‌سی',
 				'tt' => 'تاتارجا',
 				'ug' => 'اۇیغورجا',
 				'uk' => 'اۇکراینجا',
 				'und' => 'تانینمایان دیل',
 				'ur' => 'اوْردوجا',
 				'uz' => 'اؤزبکجه',
 				'vi' => 'ویتنامجا',
 				'zh' => 'چینجه',
 				'zh_Hans' => 'ساده‌لنمیش چینجه',
 				'zh_Hant' => 'سنتی چینجه',
 				'zu' => 'زۇلوجا',

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
			'Arab' => 'عربجه',
 			'Armn' => 'ائرمنیجه',
 			'Beng' => 'بنگالجا',
 			'Brai' => 'بریل',
 			'Cyrl' => 'سریلیکجه',
 			'Geor' => 'گۆرجوجه',
 			'Grek' => 'یونانجا',
 			'Hans' => 'ساده‌لنمیش',
 			'Hans@alt=stand-alone' => 'ساده‌لنمیش هانجا',
 			'Hant' => 'سنتی',
 			'Hant@alt=stand-alone' => 'سنتی هانجا',
 			'Hebr' => 'عبریجه',
 			'Hira' => 'هیراگانا',
 			'Jpan' => 'ژاپونجا',
 			'Kana' => 'کاتاکانا',
 			'Khmr' => 'خمئرجه',
 			'Kore' => 'کوْره‌جه',
 			'Latn' => 'لاتینجه',
 			'Mong' => 'موْغولجا',
 			'Taml' => 'تامیلجه',
 			'Tibt' => 'تبتجه',
 			'Zsym' => 'سمبول‌لار',
 			'Zxxx' => 'یازیلمایان',
 			'Zyyy' => 'اوْرتاق',
 			'Zzzz' => 'تانینمایان خط',

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
			'001' => 'دۆنیا',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'دیل: {0}',
 			'script' => 'یازی: {0}',
 			'region' => 'بؤلگه: {0}',

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
			auxiliary => qr{[‌‍‎‏ َ ُ ِ ْ إ ك ڭ ى ي]},
			index => ['آ', 'ا', 'ب', 'پ', 'ت', 'ث', 'ج', 'چ', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'ژ', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'ه', 'و', 'ی'],
			main => qr{[آ ؤ ا ب پ ت ث ج چ ح خ د ذ ر ز ژ س ش ص ض ط ظ ع غ ف ق ک گ ل م ن ه و ۆ ۇ ی ؽ]},
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

no Moo;

1;

# vim: tabstop=4
