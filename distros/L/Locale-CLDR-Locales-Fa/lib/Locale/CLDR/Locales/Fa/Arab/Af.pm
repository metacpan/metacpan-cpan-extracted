=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fa::Arab::Af - Package for language Persian

=cut

package Locale::CLDR::Locales::Fa::Arab::Af;
# This file auto generated from Data\common\main\fa_AF.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Fa::Arab');
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
        use bigfloat;
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
					rule => q(←← عشاریه →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(یک),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(دو),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(سه),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(چهار),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(پنج),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(شش),
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
					rule => q(نه),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ده),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(یازده),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(دوازده),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(سیزده),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(چهارده),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(پانزده),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(شانزده),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(هفده),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(هجده),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(نزده),
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
					rule => q(چهل[ و →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(پنجاه[ و →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(شصت[ و →→]),
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
					rule => q(نود[ و →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(صد[ و →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←صد[ و →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←←‌صد[ و →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←صد[ و →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← هزار[ و →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← میلیون[ و →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← میلیارد[ و →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← بیلیون[ و →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← بیلیارد[ و →→]),
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

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ab' => 'افریکانس',
 				'ar_001' => 'عربی فصیح',
 				'as' => 'اسامی',
 				'ast' => 'اتریشی',
 				'az' => 'آذربایجانی',
 				'ckb' => 'کردی سورانی',
 				'dv' => 'مالدیوی',
 				'es' => 'هسپانوی',
 				'fi' => 'فنلندی',
 				'ga' => 'آیرلندی',
 				'hr' => 'کروشیایی',
 				'id' => 'اندونیزیایی',
 				'is' => 'آیسلندی',
 				'it' => 'ایتالوی',
 				'ja' => 'جاپانی',
 				'ko' => 'کوریایی',
 				'ksh' => 'کلنی',
 				'ky' => 'قرغزی',
 				'lus' => 'میزویی',
 				'mai' => 'مایتیلی',
 				'mn' => 'مغلی',
 				'nb' => 'نروژی کتابی',
 				'ne' => 'نیپالی',
 				'nl' => 'هالندی',
 				'nl_BE' => 'فلمیش',
 				'nn' => 'نروژی نو',
 				'no' => 'نارویژی',
 				'pl' => 'پولندی',
 				'ps@alt=variant' => 'پشتو',
 				'pt' => 'پرتگالی',
 				'sq' => 'البانیایی',
 				'srn' => 'زبان سرانان',
 				'sv' => 'سویدنی',
 				'sw' => 'سواحلی',
 				'tg' => 'تاجکی',
 				'zh_Hans' => 'چینی ساده شده',
 				'zza' => 'زازاکی',

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
			'Mong' => 'مغلی',

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
			'AD' => 'اندورا',
 			'AG' => 'انتیگوا و باربودا',
 			'AL' => 'البانیا',
 			'AO' => 'انگولا',
 			'AQ' => 'انترکتیکا',
 			'AR' => 'ارجنتاین',
 			'BA' => 'بوسنیا و هرزه‌گوینا',
 			'BD' => 'بنگله‌دیش',
 			'BE' => 'بلجیم',
 			'BG' => 'بلغاریا',
 			'BN' => 'برونی',
 			'BO' => 'بولیویا',
 			'BR' => 'برازیل',
 			'BS' => 'بهاماس',
 			'CD' => 'کانگو - کینشاسا',
 			'CG' => 'کانگو - برازویل',
 			'CH' => 'سویس',
 			'CL' => 'چلی',
 			'CO' => 'کولمبیا',
 			'CR' => 'کاستریکا',
 			'CU' => 'کیوبا',
 			'DK' => 'دنمارک',
 			'EA' => 'سئوتا و ملیلا',
 			'EE' => 'استونیا',
 			'ER' => 'اریتریا',
 			'ES' => 'هسپانیه',
 			'ET' => 'ایتوپیا',
 			'FI' => 'فنلند',
 			'FM' => 'میکرونزیا',
 			'GD' => 'گرینادا',
 			'GH' => 'گانا',
 			'GN' => 'گینیا',
 			'GQ' => 'گینیا استوایی',
 			'GT' => 'گواتیمالا',
 			'GW' => 'گینیا بیسائو',
 			'GY' => 'گیانا',
 			'HK' => 'هانگ کانگ، ناحیهٔ ویژهٔ حکومتی چین',
 			'HK@alt=short' => 'هانگ کانگ',
 			'HN' => 'هاندوراس',
 			'HR' => 'کروشیا',
 			'HT' => 'هایتی',
 			'ID' => 'اندونیزیا',
 			'IE' => 'آیرلند',
 			'IS' => 'آیسلند',
 			'JP' => 'جاپان',
 			'KE' => 'کینیا',
 			'KH' => 'کمپوچیا',
 			'KP' => 'کوریای شمالی',
 			'KR' => 'کوریای جنوبی',
 			'LK' => 'سریلانکا',
 			'LS' => 'لیسوتو',
 			'LT' => 'لتوانیا',
 			'LV' => 'لاتویا',
 			'LY' => 'لیبیا',
 			'MG' => 'مادغاسکر',
 			'MN' => 'منگولیا',
 			'MR' => 'موریتانیا',
 			'MT' => 'مالتا',
 			'MX' => 'مکسیکو',
 			'MY' => 'مالیزیا',
 			'MZ' => 'موزمبیق',
 			'NG' => 'نیجریا',
 			'NI' => 'نیکاراگوا',
 			'NL' => 'هالند',
 			'NO' => 'ناروی',
 			'NP' => 'نیپال',
 			'NZ' => 'زیلاند جدید',
 			'PA' => 'پانامه',
 			'PE' => 'پیرو',
 			'PG' => 'پاپوا نیو گینیا',
 			'PL' => 'پولند',
 			'PT' => 'پرتگال',
 			'PY' => 'پاراگوای',
 			'RO' => 'رومانیا',
 			'SE' => 'سویدن',
 			'SG' => 'سینگاپور',
 			'SI' => 'سلونیا',
 			'SJ' => 'اسوالبارد و جان ماین',
 			'SK' => 'سلواکیا',
 			'SL' => 'سیرالیون',
 			'SN' => 'سینیگال',
 			'SO' => 'سومالیه',
 			'SV' => 'السلوادور',
 			'TJ' => 'تاجکستان',
 			'UG' => 'یوگاندا',
 			'UY' => 'یوروگوای',
 			'VC' => 'سنت وینسنت و گرنادین‌ها',
 			'VE' => 'ونزویلا',
 			'XK' => 'کوسوا',
 			'ZW' => 'زیمبابوی',

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
			auxiliary => qr{[‎‏ َ ِ ُ ْ ٖ ٰ ‌‍ إ ټ ځ څ ډ ړ ږ ښ ك ګ ڼ ىي]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arabext' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '‎(¤ #,##0.00)',
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
		'AUD' => {
			display_name => {
				'currency' => q(دالر آسترالیا),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(دالر برونی),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(روبل روسیهٔ سفید),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(روبل روسیهٔ سفید \(۲۰۰۰–۲۰۱۶\)),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(دالر کانادا),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(فرانک سویس),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(کرون دنمارک),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ین جاپان),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(پزوی مکسیکو),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(گیلدر هالند),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(کرون ناروی),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(کرون سویدن),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(دالر سینگاپور),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(سامانی تاجکستان),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(دالر امریکا),
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
							'جنو',
							'فبروری',
							'مارچ',
							'اپریل',
							'می',
							'جون',
							'جول',
							'اگست',
							'سپتمبر',
							'اکتوبر',
							'نومبر',
							'دسم'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جنوری',
							'فبروری',
							'مارچ',
							'اپریل',
							'می',
							'جون',
							'جولای',
							'اگست',
							'سپتمبر',
							'اکتوبر',
							'نومبر',
							'دسمبر'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'جنوری',
							'فبروری',
							'مارچ',
							'اپریل',
							'می',
							'جون',
							'جولای',
							'اگست',
							'سپتمبر',
							'اکتوبر',
							'نومبر',
							'دسمبر'
						],
						leap => [
							
						],
					},
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
					wide => {
						nonleap => [
							'جنوری',
							'فبروری',
							'مارچ',
							'اپریل',
							'می',
							'جون',
							'جولای',
							'اگست',
							'سپتمبر',
							'اکتوبر',
							'نومبر',
							'دسمبر'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					wide => {
						nonleap => [
							'حمل',
							'ثور',
							'جوزا',
							'سرطان',
							'اسد',
							'سنبلهٔ',
							'میزان',
							'عقرب',
							'قوس',
							'جدی',
							'دلو',
							'حوت'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ح',
							'ث',
							'ج',
							'س',
							'ا',
							'س',
							'م',
							'ع',
							'ق',
							'ج',
							'د',
							'ح'
						],
						leap => [
							
						],
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
					abbreviated => {0 => 'ر۱',
						1 => 'ر۲',
						2 => 'ر۳',
						3 => 'ر۴'
					},
					wide => {0 => 'ربع اول',
						1 => 'ربع دوم',
						2 => 'ربع سوم',
						3 => 'ربع چهارم'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 100
						&& $time < 400;
					return 'morning2' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 100;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 100
						&& $time < 400;
					return 'morning2' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 100;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 100
						&& $time < 400;
					return 'morning2' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 100;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 100
						&& $time < 400;
					return 'morning2' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 100;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'afternoon1' => q{ظهر},
					'afternoon2' => q{بعدازچاشت},
					'morning1' => q{بامداد},
					'morning2' => q{صبح},
					'night1' => q{شب},
					'night2' => q{نیمه‌شب},
				},
				'wide' => {
					'afternoon1' => q{ظهر},
					'afternoon2' => q{بعدازچاشت},
					'morning1' => q{بامداد},
					'morning2' => q{صبح},
					'night1' => q{شب},
					'night2' => q{نیمه‌شب},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'afternoon1' => q{بعد از چاشت},
					'morning1' => q{ب},
					'night1' => q{ش},
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
		'gregorian' => {
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
		'gregorian' => {
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
		'gregorian' => {
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
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
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
	} },
);

no Moo;

1;

# vim: tabstop=4
