=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ps::Arab::Pk - Package for language Pashto

=cut

package Locale::CLDR::Locales::Ps::Arab::Pk;
# This file auto generated from Data\common\main\ps_PK.xml
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

extends('Locale::CLDR::Locales::Ps::Arab');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar_001' => 'نوے معياري عربي',
 				'dsb' => 'لوړے سربي',
 				'fo' => 'فاروئے',
 				'kha' => 'خاسے',
 				'nb' => 'ناروے بوکمال',
 				'no' => 'ناروېئے',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'019' => 'امريکے',
 			'PS' => 'فلسطين سيمے',
 			'TC' => 'د ترکیے او کیکاسو ټاپو',
 			'TF' => 'د فرانسے جنوبي سیمے',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'collation' => {
 				'standard' => q{معياري د لټے ترتيب},
 			},
 			'numbers' => {
 				'arabext' => q{غځېدلے عربي ۔ اينډيک عدد},
 			},

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
			auxiliary => qr{[‌‍‎‏]},
			main => qr{[َ ِ ُ ً ٍ ٌ ّ ْ ٔ ٰ آ اأ ء ب پ ت ټ ث ج ځ چ څ ح خ د ډ ذ ر ړ ز ژ ږ س ش ښ ص ض ط ظ ع غ ف ق ک ګگ ل م ن ڼ هة وؤ یےيېۍئ]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} د جاذبے قوه),
						'other' => q({0} د جاذبے قوه),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} د جاذبے قوه),
						'other' => q({0} د جاذبے قوه),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(آرک ثانيے),
						'one' => q({0} آرک ثانيه),
						'other' => q({0} آرک ثانيے),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(آرک ثانيے),
						'one' => q({0} آرک ثانيه),
						'other' => q({0} آرک ثانيے),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} درجے),
						'other' => q({0} درجے),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} درجے),
						'other' => q({0} درجے),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} هيکتر),
						'other' => q({0} هيکترے),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} هيکتر),
						'other' => q({0} هيکترے),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} په هره ورځ کے),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} په هره ورځ کے),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} مياشت),
						'other' => q({0} مياشتے),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} مياشت),
						'other' => q({0} مياشتے),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0} په هره اونۍ کے),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0} په هره اونۍ کے),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(فلکي احدے),
						'one' => q({0} فلکي احد),
						'other' => q({0} فلکي احدے),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(فلکي احدے),
						'one' => q({0} فلکي احد),
						'other' => q({0} فلکي احدے),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} انچ),
						'other' => q({0} انچے),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} انچ),
						'other' => q({0} انچے),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(د پارے انچے),
						'one' => q({0} د پارے انچ),
						'other' => q({0} د پارے انچے),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(د پارے انچے),
						'one' => q({0} د پارے انچ),
						'other' => q({0} د پارے انچے),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(د پارے ملي مترز),
						'one' => q({0} د پارے ملي متر),
						'other' => q({0} د پارے ملي مترز),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(د پارے ملي مترز),
						'one' => q({0} د پارے ملي متر),
						'other' => q({0} د پارے ملي مترز),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(درجے سيلسيس),
						'one' => q({0} درجے سيلسيس),
						'other' => q({0} درجے سيلسيس),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(درجے سيلسيس),
						'one' => q({0} درجے سيلسيس),
						'other' => q({0} درجے سيلسيس),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(درجے فارنهايټ),
						'one' => q({0} درجے فارنهايټ),
						'other' => q({0} درجے فارنهايټ),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(درجے فارنهايټ),
						'one' => q({0} درجے فارنهايټ),
						'other' => q({0} درجے فارنهايټ),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} پياله),
						'other' => q({0} پيالے),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} پياله),
						'other' => q({0} پيالے),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(د ميز کاچوغے),
						'one' => q({0} د ميز کاچوغه),
						'other' => q({0} د ميز کاچوغے),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(د ميز کاچوغے),
						'one' => q({0} د ميز کاچوغه),
						'other' => q({0} د ميز کاچوغے),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(درجے),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(درجے),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(د جاذبے قوه),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(د جاذبے قوه),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(درجے),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(درجے),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(هيکترے),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(هيکترے),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ورځے),
						'one' => q({0} ورځ),
						'other' => q({0} ورځے),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ورځے),
						'one' => q({0} ورځ),
						'other' => q({0} ورځے),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(مياشتے),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(مياشتے),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(انچے),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(انچے),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(پيالے),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(پيالے),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'PKR' => {
			symbol => 'Rs',
			display_name => {
				'one' => q(پاکستانۍ کلداره),
				'other' => q(پاکستانۍ کلدارے),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(نامعلومه مروجه پېسے),
				'one' => q(\(د نامعلومه مروجه پېسو واحد\)),
				'other' => q(\(نامعلومه مروجه پېسے\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'islamic' => {
				'format' => {
					wide => {
						nonleap => [
							undef(),
							'د صفرے د'
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
		},
		'islamic' => {
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
		'islamic' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'islamic' => {
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
		'islamic' => {
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
		'Africa/Harare' => {
			exemplarCity => q#هرارے#,
		},
		'Alaska' => {
			long => {
				'daylight' => q#د الاسکا د ورځے روښانه کول#,
			},
		},
		'America/Lower_Princes' => {
			exemplarCity => q#د کمتر شهزاده درے میاشتنۍ#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#مرکزي رڼا ورځے وخت#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ختيځ د رڼا ورځے وخت#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#د غره د رڼا ورځے وخت#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#پیسفک د رڼا ورځے وخت#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#د اپیا د ورځے وخت#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#د عربي ورځپاڼے وخت#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#اتلانتیک د رڼا ورځے وخت#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#د اسټرالیا لویدیځ د ورځے وخت#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#د چين د رڼا ورځے وخت#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#کیوبا د رڼا ورځے وخت#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#د لودیځے اورپا د اوړي وخت#,
				'generic' => q#لوېديزے اروپا وخت#,
				'standard' => q#د لودیځے اروپا معیاري وخت#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#د فرانسے سویل او انټارټيک وخت#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#هوایی الیوتین رڼا ورځے وخت#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#د ایران د ورځے وخت#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#د اسراییلو د ورځے وخت#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#جاپان د رڼا ورځے وخت#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#د کوریا د ورځے د ورځے وخت#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#د کرښے ټاټوبي وخت#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#رب هاو د ورځے د رڼا وخت#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#د شمال لویدیځ مکسیکو رڼا ورځے وخت#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#مکسیکن پیسفک رڼا ورځے وخت#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#د نیوزی لینڈ د ورځے د رڼا وخت#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#د نوي فیلډلینډ رڼا ورځے وخت#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#سینټ پییرا و ميکلين رڼا ورځے وخت#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#د سموا د ورځے روښانه کول#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
