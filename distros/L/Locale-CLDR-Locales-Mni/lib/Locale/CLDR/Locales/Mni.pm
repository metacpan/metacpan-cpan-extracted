=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mni - Package for language Manipuri

=cut

package Locale::CLDR::Locales::Mni;
# This file auto generated from Data\common\main\mni.xml
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
				'ar' => 'আরাবিক',
 				'ar_001' => 'মোর্দর্ন স্তেন্দর্দ আরাবিক',
 				'bn' => 'বাংলা',
 				'de' => 'জর্মন',
 				'de_AT' => 'ওষ্ট্রিয়ান জর্মন',
 				'de_CH' => 'স্বিজ হায় জর্মন',
 				'en' => 'ইংলিস',
 				'en_AU' => 'ওষ্ট্রেলিয়ান ইংলিস',
 				'en_CA' => 'কানাদিয়ান ইংলিস',
 				'en_GB' => 'ব্রিটিশ ইংলিস',
 				'en_GB@alt=short' => 'য়ু কে ইংলিস',
 				'en_US' => 'অমেরিকান ইংলিস',
 				'en_US@alt=short' => 'য়ু এস ইংলিস',
 				'es' => 'স্পেনিস',
 				'es_419' => 'লেটিন অমেরিকান স্পেনিস',
 				'es_ES' => 'য়ুরোপিয়ান স্পেনিস',
 				'es_MX' => 'মেক্সিকান স্পেনিস',
 				'fr' => 'ফ্রেঞ্চ',
 				'fr_CA' => 'কানাদিয়ান ফ্রেঞ্চ',
 				'fr_CH' => 'স্বিজ ফ্রেঞ্চ',
 				'hi' => 'হিন্দী',
 				'id' => 'ইন্দোনেসিয়া',
 				'it' => 'ইটালিয়ন',
 				'ja' => 'জাপানিজ',
 				'ko' => 'কোরিয়ন',
 				'mni' => 'মৈতৈলোন্',
 				'nl' => 'দচ',
 				'nl_BE' => 'ফ্লেমিশ',
 				'pl' => 'পোলিশ',
 				'pt' => 'পোর্টুগিজ',
 				'pt_BR' => 'ব্রাজিলিয়ান পোর্টুগিজ',
 				'pt_PT' => 'য়ুরোপিয়ান পোর্টুগিজ',
 				'ru' => 'রুসিয়ান',
 				'th' => 'থাই',
 				'tr' => 'টর্কিশ',
 				'und' => 'মশকখংদবা লোল',
 				'zh' => 'চাইনিজ',
 				'zh@alt=menu' => 'চাইনিজ মন্দারিন',
 				'zh_Hans' => 'সিমপ্লিফাইদ চাইনিজ',
 				'zh_Hans@alt=long' => 'সিমপ্লিফাইদ মন্দারিন চাইনিজ',
 				'zh_Hant' => 'ত্রেদিস্নেল চাইনিজ',
 				'zh_Hant@alt=long' => 'ত্রেদিস্নেল মন্দারিন চাইনিজ',

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
			'Arab' => 'আরবিক',
 			'Beng' => 'বাংলা',
 			'Cyrl' => 'সিরিলিক',
 			'Hans' => 'লাইথোকহল্লবা',
 			'Hans@alt=stand-alone' => 'লাইথোকহল্লবা চাইনিজ',
 			'Hant' => 'ত্রেদিস্নেল',
 			'Hant@alt=stand-alone' => 'ত্রেদিস্নেল চাইনিজ',
 			'Jpan' => 'জপানিজ',
 			'Kore' => 'কোরিয়ন',
 			'Latn' => 'লেটিন',
 			'Mtei' => 'মীতৈ ময়েক',
 			'Zxxx' => 'ইদবা',
 			'Zzzz' => 'মশকখংদবা স্ক্রিপ্ট',

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
			'001' => 'মালেম',
 			'002' => 'অফ্রিকা',
 			'019' => 'অমেরিকাশিং',
 			'150' => 'য়ুরোপ',
 			'BR' => 'ব্রাজিল',
 			'CN' => 'চিনা',
 			'DE' => 'জর্মনি',
 			'FR' => 'ফ্রান্স',
 			'GB' => 'য়ুনাইটেদ কিংদম',
 			'IN' => 'ইন্দিয়া',
 			'IT' => 'ইটালি',
 			'JP' => 'জাপান',
 			'RU' => 'রুসিয়া',
 			'US' => 'য়ুনাইটেদ ষ্টেটস',
 			'ZZ' => 'মশকখংদবা লমদম',

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
 				'gregorian' => q{গ্রিগোরিয়ান কেলেন্দর},
 			},
 			'collation' => {
 				'standard' => q{ষ্টেন্দর্দ সোর্ট ওর্দর},
 			},
 			'numbers' => {
 				'beng' => q{বাংলা দিজিট},
 				'latn' => q{ৱেস্তর্ন দিজিট},
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
			'metric' => q{মেত্রিক},
 			'UK' => q{য়ু কে},
 			'US' => q{য়ু এস},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'লোল: {0}',
 			'script' => 'স্ক্রিপ্ট: {0}',
 			'region' => 'লমদম: {0}',

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
			auxiliary => qr{[‌‍]},
			main => qr{[় ঁংঃ অ আ ই ঈ উ ঊ ঋ এ ঐ ও ঔ ক খ গ ঘ ঙ চ ছ জ ঝ ঞ ট ঠ ড{ড়} ঢ{ঢ়} ণ ত থ দ ধ ন প ফ ব ভ ম য{য়} র ল ৱ শ ষ স হ া ি ী ু ূ ৃ ে ৈ ো ৌ ্]},
			numbers => qr{[\- ‑ , . % ‰ + 0০ 1১ 2২ 3৩ 4৪ 5৫ 6৬ 7৭ 8৮ 9৯]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:য়েস|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:নো|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} অমসুং {1}),
				2 => q({0} অমসুং {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'beng',
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(ব্রাজিলিয়ান রেয়াল),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(চাইনিজ য়ুআন),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(য়ুরো),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ব্রিটিশ পাউন্দ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ইন্দিয়ান রুপী),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(জাপানিজ য়েন),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(রুসিয়ান রুবল),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(য়ু এস দি),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(মশকখংদবা করেন্সি),
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
							'জন',
							'ফেব্রুৱারি',
							'মার্চ',
							'এপ্রিল',
							'মে',
							'জুন',
							'জুলাই',
							'ওগ',
							'সেপ্টেম্বর',
							'ওক্টোবর',
							'নভেম্বর',
							'ডিসেম্বর'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'জা',
							'ফে',
							'মার',
							'এপ',
							'মে',
							'জুন',
							'জুল',
							'আ',
							'সে',
							'ওক',
							'নব',
							'ডি'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'জনুৱারী',
							'ফেব্রুৱারি',
							'মার্চ',
							'এপ্রিল',
							'মে',
							'জুন',
							'জুলাই',
							'‌ওগষ্ট',
							'সেপ্টেম্বর',
							'ওক্টোবর',
							'নভেম্বর',
							'ডিসেম্বর'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'জানু',
							'ফেব্রু',
							'মার',
							'এপ্রি',
							'মে',
							'জুন',
							'জুলা',
							'আগ',
							'সেপ্ট',
							'ওক্টো',
							'নভে',
							'ডিসে'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'জা',
							'ফে',
							'মার',
							'এপ',
							'মে',
							'জুন',
							'জুল',
							'আ',
							'সে',
							'ও',
							'নব',
							'ডি'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'জানুৱারি',
							'ফেব্রুৱারি',
							'মার্চ',
							'এপ্রিল',
							'মে',
							'জুন',
							'জুলাই',
							'ওগষ্ট',
							'সেপ্টেম্বর',
							'ওক্টোবর',
							'নবেম্বর',
							'ডিসেম্বর'
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
					narrow => {
						mon => 'নিং',
						tue => 'লৈবা',
						wed => 'য়ুম',
						thu => 'শগো',
						fri => 'ইরা',
						sat => 'থাং',
						sun => 'নোং'
					},
					wide => {
						mon => 'নিংথৌকাবা',
						tue => 'লৈবাকপোকপা',
						wed => 'য়ুমশকৈশা',
						thu => 'শগোলশেন',
						fri => 'ইরাই',
						sat => 'থাংজ',
						sun => 'নোংমাইজিং'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'নিং',
						tue => 'লৈ',
						wed => 'য়ুম',
						thu => 'শগ',
						fri => 'ইরা',
						sat => 'থাং',
						sun => 'নো'
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
					wide => {0 => 'অহানবা মসুং',
						1 => 'অনীশুবা মসুং',
						2 => 'অহুমশুবা মসুং',
						3 => 'মরীশুবা মসুং'
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
					'am' => q{নুমাং},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{এ এম},
					'pm' => q{পি এম},
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
				'0' => 'খৃ: মমাং',
				'1' => 'খৃ: মতুং'
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
			'full' => q{MMMM d, y G, EEEE},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{MMMM d, y, EEEE},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{d/M/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			GyMd => q{GGGGG dd-MM-y},
			MEd => q{d/M, E},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{d/M/y, E},
			yMMM => q{MMM y},
			yMMMEd => q{MMM d, y, E},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{d/M/y},
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
		'generic' => {
			fallback => '{0} - {1}',
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(জি এম টি {0}),
		gmtZeroFormat => q(জি এম টি),
		regionFormat => q({0} টাইম),
		regionFormat => q({0} (+1) দেলাইট টাইম),
		regionFormat => q({0} (+0) ষ্টেন্দর্দ টাইম),
		'America_Central' => {
			long => {
				'daylight' => q#নোর্থ অমেরিকান সেন্ত্রেল দেলাইট টাইম#,
				'generic' => q#নোর্থ অমেরিকান সেন্ত্রেল টাইম#,
				'standard' => q#নোর্থ অমেরিকান সেন্ত্রেল ষ্টেন্দর্দ টাইম#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#নোর্থ অমেরিকান ইষ্টর্ন দেলাইট টাইম#,
				'generic' => q#নোর্থ অমেরিকান ইষ্টর্ন টাইম#,
				'standard' => q#নোর্থ অমেরিকান ইষ্টর্ন ষ্টেন্দর্দ টাইম#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#নোর্থ অমেরিকান মাউন্টেন দেলাইট টাইম#,
				'generic' => q#নোর্থ অমেরিকান মাউন্টেন টাইম#,
				'standard' => q#নোর্থ অমেরিকান মাউন্টেন ষ্টেন্দর্দ টাইম#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#নোর্থ অমেরিকান পেসিফিক দেলাইট টাইম#,
				'generic' => q#নোর্থ অমেরিকান পেসিফিক টাইম#,
				'standard' => q#নোর্থ অমেরিকান পেসিফিক ষ্টেন্দর্দ টাইম#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#অটলান্টিক দেলাইট টাইম#,
				'generic' => q#অটলান্টিক টাইম#,
				'standard' => q#অটলান্টিক ষ্টেন্দর্দ টাইম#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#কোওর্দিনেটেদ য়ুনিভর্সেল টাইম#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#মশকখংদবা সিটী#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#সেন্ত্রেল য়ুরোপিয়ান সমর টাইম#,
				'generic' => q#সেন্ত্রেল য়ুরোপিয়ান টাইম#,
				'standard' => q#সেন্ত্রেল য়ুরোপিয়ান ষ্টেন্দর্দ টাইম#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ইষ্টর্ন য়ুরোপিয়ান সমর টাইম#,
				'generic' => q#ইষ্টর্ন য়ুরোপিয়ান টাইম#,
				'standard' => q#ইষ্টর্ন য়ুরোপিয়ান ষ্টেন্দর্দ টাইম#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ৱেষ্টর্ন য়ুরোপিয়ান সমর টাইম#,
				'generic' => q#ৱেষ্টর্ন য়ুরোপিয়ান টাইম#,
				'standard' => q#ৱেষ্টর্ন য়ুরোপিয়ান ষ্টেন্দর্দ টাইম#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#গ্রিনৱিচ মিন টাইম#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
