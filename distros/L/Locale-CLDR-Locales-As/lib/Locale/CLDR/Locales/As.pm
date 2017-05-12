=head1

Locale::CLDR::Locales::As - Package for language Assamese

=cut

package Locale::CLDR::Locales::As;
# This file auto generated from Data\common\main\as.xml
#	on Fri 29 Apr  6:51:01 pm GMT

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
				'as' => 'অসমীয়া',
 				'ie' => 'উপস্থাপন ভাষা',
 				'km' => 'কম্বোডিয়ান',

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
			'Beng' => 'বঙালী',

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
			'AQ' => 'এন্টাৰ্টিকা',
 			'BR' => 'ব্ৰাজিল',
 			'BV' => 'বভেট দ্বীপ',
 			'CN' => 'চীন',
 			'DE' => 'জাৰ্মানি',
 			'FR' => 'ফ্ৰান্স',
 			'GB' => 'সংযুক্ত ৰাজ্য',
 			'GS' => 'দক্ষিণ জৰ্জিয়া আৰু দক্ষিণ চেণ্ডৱিচ্‌ দ্বীপ',
 			'HM' => 'হাৰ্ড দ্বীপ আৰু মেক্‌ডোনাল্ড দ্বীপ',
 			'IN' => 'ভাৰত',
 			'IO' => 'ব্ৰিটিশ্ব ইণ্ডিয়ান মহাসাগৰৰ অঞ্চল',
 			'IT' => 'ইটালি',
 			'JP' => 'জাপান',
 			'RU' => 'ৰুচ',
 			'TF' => 'দক্ষিণ ফ্ৰান্সৰ অঞ্চল',
 			'US' => 'যুক্তৰাষ্ট্ৰ',
 			'ZZ' => 'অজ্ঞাত বা অবৈধ অঞ্চল',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'পঞ্জিকা',
 			'collation' => 'শৰীকৰণ',
 			'currency' => 'মুদ্ৰা',

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
 				'buddhist' => q{বৌদ্ধ পঞ্জিকা},
 				'chinese' => q{চীনা পঞ্জিকা},
 				'gregorian' => q{গ্ৰিগোৰীয় পঞ্জিকা},
 				'hebrew' => q{হীব্ৰু পঞ্জিকা},
 				'indian' => q{ভাৰতীয় ৰাষ্ট্ৰীয় পঞ্জিকা},
 				'islamic' => q{ইচলামী পঞ্জিকা},
 				'islamic-civil' => q{ইচলামী-নাগৰিকৰ পঞ্জিকা},
 				'japanese' => q{জাপানী পঞ্জিকা},
 				'roc' => q{চীনা গণৰাজ্যৰ পঞ্জিকা},
 			},
 			'collation' => {
 				'big5han' => q{পৰম্পৰাগত চীনা শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম - Big5},
 				'gb2312han' => q{সৰল চীনা শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম - GB2312},
 				'phonebook' => q{টেলিফোন বহিৰ মতেশৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম},
 				'pinyin' => q{পিন্‌য়িন শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম},
 				'stroke' => q{স্ট্ৰোক শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম},
 				'traditional' => q{পৰম্পৰাগতভাবে শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম},
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
			'metric' => q{মেট্ৰিক},
 			'US' => q{ইউ.এছ.},

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
			auxiliary => qr{(?^u:[‌‍ ৲])},
			index => ['অ', 'আ', 'ই', 'ঈ', 'উ', 'ঊ', 'ঋ', 'ৠ', 'ঌ', 'ৡ', 'এ', 'ঐ', 'ও', 'ঔ', 'ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ', 'ছ', 'জ', 'ঝ', 'ঞ', 'ট', 'ঠ', 'ড', 'ঢ', 'ণ', 'ৎ', 'ত', 'থ', 'দ', 'ধ', 'ন', 'প', 'ফ', 'ব', 'ভ', 'ম', 'য', 'ৰ', 'ল', 'ৱ', 'শ', 'ষ', 'স', 'হ', 'ঽ'],
			main => qr{(?^u:[় অ আ ই ঈ উ ঊ ঋ এ ঐ ও ঔ ং ঁ ঃ ক খ গ ঘ ঙ চ ছ জ ঝ ঞ ট ঠ ড {ড়} ঢ {ঢ়} ণ ত থ দ ধ ন প ফ ব ভ ম য {য়} ৰ ল ৱ শ ষ স হ {ক্ষ} া ি ী ু ূ ৃ ে ৈ ো ৌ ্])},
		};
	},
EOT
: sub {
		return { index => ['অ', 'আ', 'ই', 'ঈ', 'উ', 'ঊ', 'ঋ', 'ৠ', 'ঌ', 'ৡ', 'এ', 'ঐ', 'ও', 'ঔ', 'ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ', 'ছ', 'জ', 'ঝ', 'ঞ', 'ট', 'ঠ', 'ড', 'ঢ', 'ণ', 'ৎ', 'ত', 'থ', 'দ', 'ধ', 'ন', 'প', 'ফ', 'ব', 'ভ', 'ম', 'য', 'ৰ', 'ল', 'ৱ', 'শ', 'ষ', 'স', 'হ', 'ঽ'], };
},
);


has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'beng',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'beng',
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'standard' => {
					'' => '#,##,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'' => '#,##,##0%',
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
						'positive' => '¤ #,##,##0.00',
					},
				},
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
							'জানু',
							'ফেব্ৰু',
							'মাৰ্চ',
							'এপ্ৰিল',
							'মে',
							'জুন',
							'জুলাই',
							'আগ',
							'সেপ্ট',
							'অক্টো',
							'নভে',
							'ডিসে'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'জানুৱাৰী',
							'ফেব্ৰুৱাৰী',
							'মাৰ্চ',
							'এপ্ৰিল',
							'মে',
							'জুন',
							'জুলাই',
							'আগষ্ট',
							'ছেপ্তেম্বৰ',
							'অক্টোবৰ',
							'নৱেম্বৰ',
							'ডিচেম্বৰ'
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
						mon => 'সোম',
						tue => 'মঙ্গল',
						wed => 'বুধ',
						thu => 'বৃহষ্পতি',
						fri => 'শুক্ৰ',
						sat => 'শনি',
						sun => 'ৰবি'
					},
					wide => {
						mon => 'সোমবাৰ',
						tue => 'মঙ্গলবাৰ',
						wed => 'বুধবাৰ',
						thu => 'বৃহষ্পতিবাৰ',
						fri => 'শুক্ৰবাৰ',
						sat => 'শনিবাৰ',
						sun => 'দেওবাৰ'
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
					wide => {0 => 'প্ৰথম প্ৰহৰ',
						1 => 'দ্বিতীয় প্ৰহৰ',
						2 => 'তৃতীয় প্ৰহৰ',
						3 => 'চতুৰ্থ প্ৰহৰ'
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
					'am' => q{পূৰ্বাহ্ণ},
					'pm' => q{অপৰাহ্ণ},
				},
				'abbreviated' => {
					'am' => q{পূৰ্বাহ্ণ},
					'pm' => q{অপৰাহ্ণ},
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
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, d MMMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{dd-MM-y G},
			'short' => q{d-M-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{dd-MM-y},
			'short' => q{d-M-y},
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
			'full' => q{h.mm.ss a zzzz},
			'long' => q{h.mm.ss a z},
			'medium' => q{h.mm.ss a},
			'short' => q{h.mm. a},
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
		'Asia/Calcutta' => {
			exemplarCity => q#এলাহাৱাদ#,
		},
		'India' => {
			long => {
				'standard' => q(ভাৰতীয় সময়),
			},
			short => {
				'standard' => q(ভা. স.),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
