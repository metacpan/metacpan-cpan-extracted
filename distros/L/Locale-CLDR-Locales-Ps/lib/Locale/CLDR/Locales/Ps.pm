=head1

Locale::CLDR::Locales::Ps - Package for language Pashto

=cut

package Locale::CLDR::Locales::Ps;
# This file auto generated from Data\common\main\ps.xml
#	on Fri 29 Apr  7:21:26 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
				'af' => 'افريکاني',
 				'am' => 'امهاري',
 				'ar' => 'عربي',
 				'as' => 'آسامي',
 				'az' => 'أذربائجاني',
 				'bal' => 'بلوڅي',
 				'be' => 'بېلاروسي',
 				'bg' => 'بلغاري',
 				'bn' => 'بنګالي',
 				'br' => 'برېتون',
 				'bs' => 'بوسني',
 				'ca' => 'کټلاني',
 				'cs' => 'چېک',
 				'cy' => 'ويلشي',
 				'da' => 'ډېنش',
 				'de' => 'الماني',
 				'el' => 'یوناني',
 				'en' => 'انګلیسي',
 				'eo' => 'اسپرانتو',
 				'es' => 'هسپانوي',
 				'et' => 'حبشي',
 				'eu' => 'باسکي',
 				'fa' => 'فارسي',
 				'fi' => 'فینلنډي',
 				'fil' => 'تګالوګ',
 				'fo' => 'فاروئې',
 				'fr' => 'فرانسوي',
 				'fy' => 'فريزي',
 				'ga' => 'ائيرلېنډي',
 				'gd' => 'سکاټلېنډي ګېلک',
 				'gl' => 'ګلېشيايي',
 				'gn' => 'ګوراني',
 				'gu' => 'ګجراتي',
 				'he' => 'عبري',
 				'hi' => 'هندي',
 				'hr' => 'کروواتي',
 				'hu' => 'هنګري',
 				'hy' => 'ارمني',
 				'ia' => 'انټرلنګوا',
 				'id' => 'انډونېشيايي',
 				'ie' => 'آسا نا جبة',
 				'is' => 'أيسلېنډي',
 				'it' => 'ایټالوي',
 				'ja' => 'جاپانی',
 				'jv' => 'جاوايې',
 				'ka' => 'جورجيائي',
 				'km' => 'کمبوډيايې يا د کمبوډيا',
 				'kn' => 'کنأډه',
 				'ko' => 'کوريائي',
 				'ku' => 'کردي',
 				'ky' => 'کرګيز',
 				'la' => 'لاتیني',
 				'lo' => 'لويتين',
 				'lt' => 'ليتواني',
 				'lv' => 'لېټواني',
 				'mg' => 'ملغاسي',
 				'mk' => 'مقدوني',
 				'ml' => 'مالايالم',
 				'mn' => 'مغولي',
 				'mr' => 'مراټهي',
 				'ms' => 'ملایا',
 				'mt' => 'مالټايي',
 				'ne' => 'نېپالي',
 				'nl' => 'هالېنډي',
 				'nn' => 'ناروېئي (نائنورسک)',
 				'no' => 'ناروېئې',
 				'oc' => 'اوکسيټاني',
 				'or' => 'اوريا',
 				'pa' => 'پنجابي',
 				'pl' => 'پولنډي',
 				'ps' => 'پښتو',
 				'pt' => 'پورتګالي',
 				'pt_BR' => 'پرتگال (برازيل)',
 				'pt_PT' => 'پرتګالي (پرتګال)',
 				'ro' => 'روماني',
 				'ru' => 'روسي',
 				'sa' => 'سنسکریټ',
 				'sd' => 'سندهي',
 				'sh' => 'سرب-کروشيايي',
 				'si' => 'سينهالي',
 				'sk' => 'سلوواکي',
 				'sl' => 'سلوواني',
 				'so' => 'سومالي',
 				'sq' => 'الباني',
 				'sr' => 'سربيائي',
 				'st' => 'سيسوتو',
 				'su' => 'سوډاني',
 				'sv' => 'سویډنی',
 				'sw' => 'سواهېلي',
 				'ta' => 'تامل',
 				'te' => 'تېليګو',
 				'tg' => 'تاجک',
 				'th' => 'تايلېنډي',
 				'ti' => 'تيګريني',
 				'tk' => 'ترکمني',
 				'tlh' => 'کلينګاني',
 				'tr' => 'ترکي',
 				'tt' => 'تاتار',
 				'tw' => 'توی',
 				'ug' => 'اويگور',
 				'uk' => 'اوکرانايي',
 				'ur' => 'اردو',
 				'uz' => 'ازبکي',
 				'vi' => 'وېتنامي',
 				'xh' => 'خوسا',
 				'yi' => 'يديش',
 				'zh' => 'چیني',
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
			'Arab' => 'عربي',

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
			'AF' => 'افغانستان',
 			'AL' => 'البانیه',
 			'AO' => 'انګولا',
 			'AQ' => 'انتارکتیکا',
 			'AT' => 'اتریش',
 			'BD' => 'بنګله‌دیش',
 			'BG' => 'بلغاریه',
 			'CA' => 'کاناډا',
 			'CH' => 'سویس',
 			'CN' => 'چین',
 			'CO' => 'کولمبیا',
 			'CU' => 'کیوبا',
 			'DE' => 'المان',
 			'DK' => 'ډنمارک',
 			'DZ' => 'الجزایر',
 			'EG' => 'مصر',
 			'ES' => 'هسپانیه',
 			'ET' => 'حبشه',
 			'FI' => 'فنلینډ',
 			'FR' => 'فرانسه',
 			'GB' => 'برتانیه',
 			'GH' => 'ګانا',
 			'GN' => 'ګیانا',
 			'GR' => 'یونان',
 			'GT' => 'ګواتیمالا',
 			'HN' => 'هانډوراس',
 			'HU' => 'مجارستان',
 			'ID' => 'اندونیزیا',
 			'IN' => 'هند',
 			'IQ' => 'عراق',
 			'IS' => 'آیسلینډ',
 			'IT' => 'ایټالیه',
 			'JM' => 'جمیکا',
 			'JP' => 'جاپان',
 			'KH' => 'کمبودیا',
 			'KW' => 'کویټ',
 			'LA' => 'لاوس',
 			'LB' => 'لبنان',
 			'LR' => 'لایبریا',
 			'LY' => 'لیبیا',
 			'MA' => 'مراکش',
 			'MN' => 'مغولستان',
 			'MY' => 'مالیزیا',
 			'NG' => 'نایجیریا',
 			'NI' => 'نکاراګوا',
 			'NL' => 'هالېنډ',
 			'NO' => 'ناروې',
 			'NP' => 'نیپال',
 			'NZ' => 'نیوزیلنډ',
 			'PK' => 'پاکستان',
 			'PL' => 'پولنډ',
 			'PS' => 'فلسطین',
 			'PT' => 'پورتګال',
 			'RU' => 'روسیه',
 			'RW' => 'روندا',
 			'SA' => 'سعودی عربستان',
 			'SE' => 'سویډن',
 			'SV' => 'سالوېډور',
 			'SY' => 'سوریه',
 			'TJ' => 'تاجکستان',
 			'TZ' => 'تنزانیا',
 			'UY' => 'یوروګوای',
 			'YE' => 'یمن',

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
			auxiliary => qr{(?^u:[‌ ‍ ‎‏])},
			index => ['آ', 'ا', 'ء', 'ب', 'پ', 'ت', 'ټ', 'ث', 'ج', 'ځ', 'چ', 'څ', 'ح', 'خ', 'د', 'ډ', 'ذ', 'ر', 'ړ', 'ز', 'ژ', 'ږ', 'س', 'ش', 'ښ', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'ګ', 'ل', 'م', 'ن', 'ڼ', 'ه', 'و', 'ی'],
			main => qr{(?^u:[َ ِ ُ ً ٍ ٌ ّ ْ ٔ ٰ آ ا أ ء ب پ ت ټ ث ج ځ چ څ ح خ د ډ ذ ر ړ ز ژ ږ س ش ښ ص ض ط ظ ع غ ف ق ک ګ گ ل م ن ڼ ه ة و ؤ ی ي ې ۍ ئ])},
		};
	},
EOT
: sub {
		return { index => ['آ', 'ا', 'ء', 'ب', 'پ', 'ت', 'ټ', 'ث', 'ج', 'ځ', 'چ', 'څ', 'ح', 'خ', 'د', 'ډ', 'ذ', 'ر', 'ړ', 'ز', 'ژ', 'ږ', 'س', 'ش', 'ښ', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'ګ', 'ل', 'م', 'ن', 'ڼ', 'ه', 'و', 'ی'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(ورځ),
					},
					'year' => {
						'name' => q(کالونه),
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
			'decimal' => q(٫),
			'exponential' => q(×۱۰^),
			'group' => q(٬),
			'percentSign' => q(٪),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
			'minusSign' => q(‎−),
			'percentSign' => q(%),
			'plusSign' => q(‎+),
		},
	} }
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
						'positive' => '#,##0.00 ¤',
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
			symbol => '؋',
			display_name => {
				'currency' => q(افغانۍ),
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
							'جنوري',
							'فبروري',
							'مارچ',
							'اپریل',
							'می',
							'جون',
							'جولای',
							'اګست',
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
							'وری',
							'غویی',
							'غبرگولی',
							'چنگاښ',
							'زمری',
							'وږی',
							'تله',
							'لړم',
							'لیندۍ',
							'مرغومی',
							'سلواغه',
							'کب'
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
						mon => 'دوشنبه',
						tue => 'سه‌شنبه',
						wed => 'چهارشنبه',
						thu => 'پنجشنبه',
						fri => 'جمعه',
						sat => 'شنبه',
						sun => 'یکشنبه'
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
				'wide' => {
					'pm' => q{غ.و.},
					'am' => q{غ.م.},
				},
				'abbreviated' => {
					'pm' => q{غ.و.},
					'am' => q{غ.م.},
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
				'0' => 'ق.م.',
				'1' => 'م.'
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
			'full' => q{EEEE د G y د MMMM d},
			'long' => q{د G y د MMMM d},
			'medium' => q{d MMM y G},
			'short' => q{GGGGG y/M/d},
		},
		'gregorian' => {
			'full' => q{EEEE د y د MMMM d},
			'long' => q{د y د MMMM d},
			'medium' => q{d MMM y},
			'short' => q{y/M/d},
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
			'full' => q{H:mm:ss (zzzz)},
			'long' => q{H:mm:ss (z)},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
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
		},
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
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MMMMd => q{d MMMM},
			Md => q{M/d},
			yM => q{y/M},
			yMMMM => q{د y د MMMM},
		},
		'generic' => {
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MMMMd => q{d MMMM},
			Md => q{M/d},
			yM => q{G y/M},
			yMMMM => q{د G y د MMMM},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} ({1})',
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(د {0} په وخت),
		'Almaty' => {
			long => {
				'daylight' => q(∅∅∅),
				'generic' => q(الماتا په وخت),
				'standard' => q(∅∅∅),
			},
		},
		'Asia/Kabul' => {
			exemplarCity => q#کابل#,
		},
		'Europe_Western' => {
			long => {
				'daylight' => q(∅∅∅),
				'generic' => q(لوېديزې اروپا وخت),
				'standard' => q(∅∅∅),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(گرينويچ وخت),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
