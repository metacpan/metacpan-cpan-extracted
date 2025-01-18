=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bal - Package for language Baluchi

=cut

package Locale::CLDR::Locales::Bal;
# This file auto generated from Data\common\main\bal.xml
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
				'bal' => 'بلۆچی',
 				'bal_Latn' => 'Balóchi',
 				'de' => 'جرمن',
 				'de_AT' => 'آستریایی جرمن',
 				'de_CH' => 'سویزی جرمن',
 				'en' => 'انگرێزی',
 				'en_AU' => 'اُسترالیایی انگرێزی',
 				'en_CA' => 'کانادایی انگرێزی',
 				'en_GB' => 'برتانیایی انگرێزی',
 				'en_US' => 'امریکی انگرێزی',
 				'es' => 'اِسپانیایی',
 				'es_419' => 'جنوب امریکی اسپانیایی',
 				'es_ES' => 'اسپانیایی',
 				'es_MX' => 'مکسیکی اسپانیایی',
 				'fr' => 'پرانسی',
 				'fr_CA' => 'کانادایی پرانسی',
 				'fr_CH' => 'سویزی پرانسی',
 				'it' => 'ایتالیایی',
 				'ja' => 'جاپانی',
 				'pt' => 'پرتگالی',
 				'pt_BR' => 'برازیلی پرتگالی',
 				'pt_PT' => 'یورپی پرتگالی',
 				'ru' => 'روسی',
 				'und' => 'نگیشّتگێن زبان',
 				'zh' => 'چینی',
 				'zh_Hans' => 'ساده کرتگێن چینی',
 				'zh_Hant' => 'اسلیگێن چینی',

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
			'Arab' => 'اربی',
 			'Cyrl' => 'روسی',
 			'Hans' => 'هان (ساده کرتگێن)',
 			'Hant' => 'هان (اسلیگێن)',
 			'Latn' => 'لاتینی',
 			'Zxxx' => 'نبشته نبوتگێن سیاهگ',
 			'Zzzz' => 'کۆڈ نبوتگێن سیاهگ',

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
			'BR' => 'برازیل',
 			'CN' => 'چین',
 			'DE' => 'جرمنی',
 			'FR' => 'پرانس',
 			'GB' => 'برتانیا',
 			'IN' => 'هندستان',
 			'IT' => 'ایتالیا',
 			'JP' => 'جاپان',
 			'PK' => 'پاکستان',
 			'RU' => 'روس',
 			'US' => 'امریکی هئوارێن ملک',
 			'ZZ' => 'نگیشّتگێن دمگ',

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
 				'buddhist' => q{بُدّایی سالدر},
 				'chinese' => q{چینی سالدر},
 				'coptic' => q{کپتی سالدر},
 				'dangi' => q{دانگی سالدر},
 				'ethiopic' => q{ایتیوپیایی سالدر},
 				'ethiopic-amete-alem' => q{ایتیوپیایی آمیت آلم سالدر},
 				'gregorian' => q{گرێگۆری سالدر},
 				'hebrew' => q{ابرانی سالدر},
 				'indian' => q{هندی کئومی سالدر},
 				'islamic' => q{اسلامی سالدر},
 				'islamic-civil' => q{اسلامی شهری سالدر},
 				'islamic-rgsa' => q{اسلامی سئوودی اربی سالدر},
 				'islamic-tbla' => q{اسلامی نجومی سالدر},
 				'islamic-umalqura' => q{اسلامی ام الکراهی سالدر},
 				'iso8601' => q{سالدر ISO-8601},
 				'japanese' => q{جاپانی سالدر},
 				'persian' => q{پارسی سالدر},
 				'roc' => q{مینگۆ چینی سالدر},
 			},
 			'cf' => {
 				'standard' => q{زرّئے گیشّتگێن کالب},
 			},
 			'collation' => {
 				'standard' => q{گیشّتگێن ترتیب},
 			},
 			'numbers' => {
 				'arab' => q{اربی-هندی نمبر},
 				'cyrl' => q{روسی نمبر},
 				'deva' => q{دێوناگری نمبر},
 				'latn' => q{مگربی نمبر},
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
			'metric' => q{میتَری},
 			'UK' => q{برتانی},
 			'US' => q{امریکی},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'زبان: {0}',
 			'script' => 'سیاهگ: {0}',
 			'region' => 'دمگ: {0}',

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
			auxiliary => qr{[‌‍ ً ٔ ء أ ؤ إ ة ث ح خ ذ ص ض ط ظ ع غ ف ق ں ھ ہ]},
			index => ['آ', 'ا', '{ای}', '{اێ}', '{ائی}', 'ب', 'پ', 'ت', 'ٹ', 'ج', 'چ', 'د', 'ڈ', 'ر', 'ڑ', 'ز', 'ژ', 'س', 'ش', 'ف', 'ک', 'گ', 'ل', 'م', 'ن', 'و', 'ه', 'ی'],
			main => qr{[َ ُ ِ ّ ْ آ ا ئ ب پ ت ٹ ج چ د ڈ ر ڑ ز ژ س ش ک گ ل م ن و ۆ ه ی ێ ے]},
			punctuation => qr{[، ؛ \: ! ؟ . ' ‹ › " « »]},
		};
	},
EOT
: sub {
		return { index => ['آ', 'ا', '{ای}', '{اێ}', '{ائی}', 'ب', 'پ', 'ت', 'ٹ', 'ج', 'چ', 'د', 'ڈ', 'ر', 'ڑ', 'ز', 'ژ', 'س', 'ش', 'ف', 'ک', 'گ', 'ل', 'م', 'ن', 'و', 'ه', 'ی'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:هئو|ه|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:نه|ن|no|n)$' }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(برازیلی ریال),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(یورۆ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(برتانی پئوند),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(هندُستانی روپّئیی),
			},
		},
		'IRR' => {
			symbol => 'ریال',
			display_name => {
				'currency' => q(اێرانی ریال),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(جاپانی یَن),
			},
		},
		'PKR' => {
			symbol => 'Rs',
			display_name => {
				'currency' => q(پاکستانی روپی),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(روسی روبل),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(امریکی دالر),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(نگیشّتگێن زَرّ),
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
							'جن',
							'پر',
							'مار',
							'اپر',
							'مئیی',
							'جون',
							'جۆل',
							'اگست',
							'ستم',
							'اکت',
							'نئوم',
							'دسم'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جنوری',
							'پروری',
							'مارچ',
							'اپرێل',
							'مئیی',
							'جون',
							'جۆلایی',
							'اگست',
							'ستمبر',
							'اکتوبر',
							'نئومبر',
							'دسمبر'
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
						mon => 'دو',
						tue => 'سئے',
						wed => 'چار',
						thu => 'پنچ',
						fri => 'جمه',
						sat => 'شم',
						sun => 'یک'
					},
					wide => {
						mon => 'دوشمبه',
						tue => 'سئیشمبه',
						wed => 'چارشمبه',
						thu => 'پنچشمبه',
						fri => 'جمه',
						sat => 'شمبه',
						sun => 'یکشمبه'
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
					abbreviated => {0 => '1/4',
						1 => '2/4',
						2 => '3/4',
						3 => '4/4'
					},
					wide => {0 => 'ائوَلی چارِک',
						1 => 'دومی چارِک',
						2 => 'سئیمی چارِک',
						3 => 'چارُمی چارِک'
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
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{hh:mm:ss a zzzz},
			'long' => q{hh:mm:ss a zzz},
			'medium' => q{hh:mm:ss a},
			'short' => q{hh:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'gregorian' => {
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
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
		'gregorian' => {
			fallback => '{1} - {0}',
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Alaska' => {
			long => {
				'daylight' => q#اَلاسکائے گرماگی ساهت#,
				'generic' => q#اَلاسکائے ساهت#,
				'standard' => q#اَلاسکائے گیشّتگێن ساهت#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#امازۆنئے گرماگی ساهت#,
				'generic' => q#امازۆنئے ساهت#,
				'standard' => q#امازۆنئے گیشّتگێن ساهت#,
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q#نیامی امریکائے گرماگی ساهت#,
				'generic' => q#نیامی امریکائے ساهت#,
				'standard' => q#نیامی امریکائے گیشّتگێن ساهت#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#رۆدراتکی امریکائے گرماگی ساهت#,
				'generic' => q#رۆدراتکی امریکائے ساهت#,
				'standard' => q#رۆدراتکی امریکائے گیشّتگێن ساهت#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#کۆهستگێن امریکائے گرماگی ساهت#,
				'generic' => q#کۆهستگێن امریکائے ساهت#,
				'standard' => q#کۆهستگێن امریکائے گیشّتگێن ساهت#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#آرامزِری امریکائے گرماگی ساهت#,
				'generic' => q#آرامزِری امریکائے ساهت#,
				'standard' => q#آرامزِری امریکائے گیشّتگێن ساهت#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#ارجنتینائے گرماگی ساهت#,
				'generic' => q#ارجنتینائے ساهت#,
				'standard' => q#ارجنتینائے گیشّتگێن ساهت#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#رۆنندی ارجنتینائے گرماگی ساهت#,
				'generic' => q#رۆنندی ارجنتینائے ساهت#,
				'standard' => q#رۆنندی ارجنتینائے گیشّتگێن ساهت#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#نیامی اُسترالیائے گرماگی ساهت#,
				'generic' => q#نیامی اُسترالیائے ساهت#,
				'standard' => q#نیامی اُسترالیائے گیشّتگێن ساهت#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#نیام‌رۆنندی اُسترالیائے گرماگی ساهت#,
				'generic' => q#نیام‌رۆنندی اُسترالیائے ساهت#,
				'standard' => q#نیام‌رۆنندی اُسترالیائے گیشّتگێن ساهت#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#رۆدراتکی اُسترالیائے گرماگی ساهت#,
				'generic' => q#رۆدراتکی اُسترالیائے ساهت#,
				'standard' => q#رۆدراتکی اُسترالیائے گیشّتگێن ساهت#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#رۆنندی اُسترالیائے گرماگی ساهت#,
				'generic' => q#رۆنندی اُسترالیائے ساهت#,
				'standard' => q#رۆنندی اُسترالیائے گیشّتگێن ساهت#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#برازیلئے گرماگی ساهت#,
				'generic' => q#برازیلئے ساهت#,
				'standard' => q#برازیلئے گیشّتگێن ساهت#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#نیامی یورپئے گرماگی ساهت#,
				'generic' => q#نیامی یورپئے ساهت#,
				'standard' => q#نیامی یورپئے گیشّتگێن ساهت#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#رۆدراتکی یورپئے گرماگی ساهت#,
				'generic' => q#رۆدراتکی یورپئے ساهت#,
				'standard' => q#رۆدراتکی یورپئے گیشّتگێن ساهت#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#دێمتری رۆدراتکی یورپئے گیشّتگێن ساهت#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#رۆنندی یورپئے گرماگی ساهت#,
				'generic' => q#رۆنندی یورپئے ساهت#,
				'standard' => q#رۆنندی یورپئے گیشّتگێن ساهت#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#گرین‌وِچ مین ٹائم#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#هئواییئے گرماگی ساهت#,
				'generic' => q#هئواییئے ساهت#,
				'standard' => q#هئواییئے گیشّتگێن ساهت#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#نیامی اندۆنیزیائے گیشّتگێن ساهت#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#رۆدراتکی اندۆنیزیائے گیشّتگێن ساهت#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#رۆنندی اندۆنیزیائے گیشّتگێن ساهت#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ایرکوتسکئے گرماگی ساهت#,
				'generic' => q#ایرکوتسکئے ساهت#,
				'standard' => q#ایرکوتسکئے گیشّتگێن ساهت#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#رۆدراتکی کازکستانئے گیشّتگێن ساهت#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#رۆنندی کازکستانئے گیشّتگێن ساهت#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#کرانسنُیارسکئے گرماگی ساهت#,
				'generic' => q#کرانسنُیارسکئے ساهت#,
				'standard' => q#کرانسنُیارسکئے گیشّتگێن ساهت#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#لۆرڈ هئو اُسترالیائے گرماگی ساهت#,
				'generic' => q#لۆرڈ هئو اُسترالیائے ساهت#,
				'standard' => q#لۆرڈ هئو اُسترالیائے گیشّتگێن ساهت#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#مَگَدَنئے گرماگی ساهت#,
				'generic' => q#مَگَدَنئے ساهت#,
				'standard' => q#مَگَدَنئے گیشّتگێن ساهت#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#آرامزِری مِکسیکۆئے گرماگی ساهت#,
				'generic' => q#آرامزِری مِکسیکۆئے ساهت#,
				'standard' => q#آرامزِری مِکسیکۆئے گیشّتگێن ساهت#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ماسکۆئے گرماگی ساهت#,
				'generic' => q#ماسکۆئے ساهت#,
				'standard' => q#ماسکۆئے گیشّتگێن ساهت#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#نیوفاوونڈلئینڈئے گرماگی ساهت#,
				'generic' => q#نیوفاوونڈلئینڈئے ساهت#,
				'standard' => q#نیوفاوونڈلئینڈئے گیشّتگێن ساهت#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#نُرُنهائے گرماگی ساهت#,
				'generic' => q#نُرُنهائے ساهت#,
				'standard' => q#نُرُنهائے گیشّتگێن ساهت#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#نۆوۆسیبیرسکئے گرماگی ساهت#,
				'generic' => q#نۆوۆسیبیرسکئے ساهت#,
				'standard' => q#نۆوۆسیبیرسکئے گیشّتگێن ساهت#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#اۆمسکئے گرماگی ساهت#,
				'generic' => q#اۆمسکئے ساهت#,
				'standard' => q#اۆمسکئے گیشّتگێن ساهت#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ولادیوُستُکئے گرماگی ساهت#,
				'generic' => q#ولادیوُستُکئے ساهت#,
				'standard' => q#ولادیوُستُکئے گیشّتگێن ساهت#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#یاکوتسکئے گرماگی ساهت#,
				'generic' => q#یاکوتسکئے ساهت#,
				'standard' => q#یاکوتسکئے گیشّتگێن ساهت#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#یێکاترینبورگئے گرماگی ساهت#,
				'generic' => q#یێکاترینبورگئے ساهت#,
				'standard' => q#یێکاترینبورگئے گیشّتگێن ساهت#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
