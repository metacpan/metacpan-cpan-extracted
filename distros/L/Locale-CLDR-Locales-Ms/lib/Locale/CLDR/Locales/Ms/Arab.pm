=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ms::Arab - Package for language Malay

=cut

package Locale::CLDR::Locales::Ms::Arab;
# This file auto generated from Data\common\main\ms_Arab.xml
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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'عرب',
 				'de' => 'جرمان',
 				'en' => 'ايغضريس',
 				'fr' => 'ڤرنچيس',
 				'hi' => 'هيندي',
 				'id' => 'إندونيسيا',
 				'it' => 'إيطاليا',
 				'ja' => 'جڤون',
 				'jv' => 'جاو',
 				'ml' => 'مالايالم',
 				'ms' => 'بهاس ملايو',
 				'nl' => 'بلندا',
 				'pl' => 'ڤولندا',
 				'pt' => 'ڤورتوݢيس',
 				'ta' => 'تاميل',
 				'tr' => 'ترکيا',
 				'und' => 'بهاس تيدق دکتاهوءي',
 				'zh' => 'چينا',
 				'zh_Hans' => 'چينا ريڠکس',
 				'zh_Hant' => 'چينا تراديسيونل',
 				'zxx' => 'تيدق کندوڠن ليڠݢوٴيستيک',

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
			'Arab' => 'عرب',
 			'Deva' => 'ديؤاناݢري',
 			'Hans' => 'ريڠکس',
 			'Hans@alt=stand-alone' => 'هن ريڠکس',
 			'Hant' => 'تراديسيونل',
 			'Hant@alt=stand-alone' => 'هن تراديسيونل',
 			'Jpan' => 'جڤون',
 			'Latn' => 'لاتين',
 			'Mlym' => 'مالايالم',
 			'Taml' => 'تاميل',
 			'Zsym' => 'سيمبول',
 			'Zxxx' => 'تيدق دتوليس',
 			'Zyyy' => 'بياسا',
 			'Zzzz' => 'سکريڤ تيدق دکتاهوءي',

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
			'001' => 'دنيا',
 			'030' => 'اسيا تيمور',
 			'034' => 'اسيا سلاتن',
 			'035' => 'اسيا تڠݢارا',
 			'142' => 'اسيا',
 			'143' => 'اسيا تڠه',
 			'145' => 'اسيا بارات',
 			'419' => 'اميريک لاتين',
 			'BN' => 'بروني',
 			'BR' => 'البرازيل',
 			'CN' => 'چينا',
 			'DE' => 'جرمان',
 			'FR' => 'ڤرنچيس',
 			'ID' => 'إندونيسيا',
 			'IN' => 'اينديا',
 			'IT' => 'إيطاليا',
 			'JP' => 'جڤون',
 			'MY' => 'مليسيا',
 			'SA' => 'عرب سعودي',
 			'SG' => 'سيڠاڤورا',
 			'TH' => 'تايلان',
 			'TW' => 'تايوان',
 			'US' => 'اميريک شريکت',
 			'ZZ' => 'ولايه تيدق دکتاهوءي',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'کومبڠ',
 			'currency' => 'ماتواڠ',
 			'numbers' => 'نو',
 			'timezone' => 'زون وقتو',

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
 				'buddhist' => q{کومبڠ بودا},
 				'chinese' => q{کومبڠ چينا},
 				'indian' => q{کومبڠ کبڠساٴن اينديا},
 				'islamic' => q{کومبڠ اسلام},
 				'islamic-civil' => q{کومبڠ سيۏيل اسلام},
 				'japanese' => q{کومبڠ جڤون},
 				'persian' => q{کومبڠ ڤرسي},
 			},
 			'collation' => {
 				'dictionary' => q{اتورن ايسيه قاموس},
 				'phonebook' => q{اتورن ايسيه بوکو تيليفون},
 				'phonetic' => q{اوروتن ايسيه فونيتيک},
 				'reformed' => q{اتورن ايسيه ڤمبهاروان},
 				'search' => q{چارين توجوان عموم},
 				'traditional' => q{اتورن ايسيه تراديسيونل},
 				'unihan' => q{اتورن ايسيه چوريتن راديکل},
 			},
 			'numbers' => {
 				'finance' => q{اڠک کأواڠن},
 				'hanidec' => q{اڠک ڤرڤولوهن چينا},
 				'hans' => q{اڠک چينا ريڠکس},
 				'hansfin' => q{اڠک کأواڠن چينا ريڠکس},
 				'hant' => q{اڠک چينا تراديسيونل},
 				'hantfin' => q{اڠک کأواڠن چينا تراديسيونل},
 				'jpan' => q{اڠک جڤون},
 				'jpanfin' => q{اڠک کأواڠن جڤون},
 				'latn' => q{ديݢيت بارات},
 				'mlym' => q{ديݢيت مالايالم},
 				'native' => q{ديݢيت اصل},
 				'taml' => q{اڠک تاميل},
 				'tamldec' => q{ديݢيت تاميل},
 				'traditional' => q{اڠک تراديسيونل},
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
			'metric' => q{ميتريک},

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
			auxiliary => qr{[ڬ ۑ]},
			main => qr{[ء آ أ ؤ إ ئ ا ب ة ت ث ج چ ح خ د ذ ر ز س ش ص ض ط ظ ع غ ڠ ف ڤ ق ك ک ݢ ل م ن ڽ ه و ۏ ى ي]},
		};
	},
EOT
: sub {
		return {};
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
	default		=> qq{”},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0} مينيت),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0} مينيت),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} تاهون),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} تاهون),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0} هاري),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0} هاري),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} جم),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} جم),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} بولن),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} بولن),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0} ساعت),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0} ساعت),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} ميڠݢو),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} ميڠݢو),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} thn),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} thn),
					},
				},
			} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'other' => '0 ريبو',
				},
				'10000' => {
					'other' => '00 ريبو',
				},
				'100000' => {
					'other' => '000 ريبو',
				},
				'1000000' => {
					'other' => '0 جوتا',
				},
				'10000000' => {
					'other' => '00 جوتا',
				},
				'100000000' => {
					'other' => '000 جوتا',
				},
				'1000000000' => {
					'other' => '0 بيليون',
				},
				'10000000000' => {
					'other' => '00 بيليون',
				},
				'100000000000' => {
					'other' => '000 بيليون',
				},
				'1000000000000' => {
					'other' => '0 تريليون',
				},
				'10000000000000' => {
					'other' => '00 تريليون',
				},
				'100000000000000' => {
					'other' => '000 تريليون',
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
					'accounting' => {
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
		'BND' => {
			display_name => {
				'currency' => q(دولر بروني),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ڤاٴون ستيرليڠ بريتيش),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(روڤياە إندونيسيا),
			},
		},
		'MYR' => {
			symbol => 'RM',
			display_name => {
				'currency' => q(ريڠݢيت مليسيا),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(دولر سيڠاڤورا),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(مات واڠ تيدق دکتاهوءي),
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
							'جانواري',
							'فيبواري',
							'مچ',
							'اڤريل',
							'مي',
							'جون',
							'جولاي',
							'ݢوس',
							'سيڤتيمبر',
							'اوکتوبر',
							'نوۏيمبر',
							'ديسيمبر'
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
						mon => 'اثنين',
						tue => 'ثلاث',
						wed => 'رابو',
						thu => 'خميس',
						fri => 'جمعة',
						sat => 'سبتو',
						sun => 'احد'
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
					abbreviated => {0 => 'سوکو 1',
						1 => 'سوکو ک-2',
						2 => 'سوکو ک-3',
						3 => 'سوکو ک-4'
					},
					wide => {0 => 'سوکو ڤرتام',
						1 => 'سوکو ک-2',
						2 => 'سوکو ک-3',
						3 => 'سوکو ک-4'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1400
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 100;
					return 'morning2' if $time >= 100
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
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

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'full' => q{EEEE، d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd/MM/y G},
			'short' => q{d/MM/y G},
		},
		'chinese' => {
			'full' => q{EEEE، U MMMM dd},
			'long' => q{U MMMM d},
			'medium' => q{U MMM d},
			'short' => q{y-M-d},
		},
		'generic' => {
			'full' => q{EEEE، d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd/MM/y G},
			'short' => q{d/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE، d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{dd/MM/y},
			'short' => q{d/MM/yy},
		},
		'islamic' => {
			'full' => q{EEEE، d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd/MM/y G},
			'short' => q{d/MM/y G},
		},
		'japanese' => {
			'full' => q{EEEE، d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd/MM/y G},
			'short' => q{d/MM/y G},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'islamic' => {
		},
		'japanese' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
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
		'islamic' => {
		},
		'japanese' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			Ed => q{E, d},
			MEd => q{E، d/M},
			Md => q{d/M},
			yM => q{M/y G},
			yMEd => q{E، d/M/y G},
			yMMM => q{MMM y G},
			yMMMEd => q{E، d MMM y G},
			yMMMd => q{d MMM y G},
		},
		'generic' => {
			Ed => q{d E},
			Hmm => q{H:mm},
			MEd => q{E، d-M},
			MMMEd => q{E، d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d-M},
			y => q{y},
			yM => q{M-y},
			yMEd => q{E، d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E، d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{d E},
			Hmm => q{H:mm},
			MEd => q{E، d-M},
			MMMEd => q{E، d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d-M},
			yM => q{M-y},
			yMEd => q{E، d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E، d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'islamic' => {
			Ed => q{E، d},
			MEd => q{E، d/M},
			Md => q{d/M},
			yyyyM => q{M/y G},
			yyyyMEd => q{E، d/M/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E، d MMM y G},
			yyyyMMMd => q{d MMM y G},
		},
		'japanese' => {
			Ed => q{E، d},
			MEd => q{E، d/M},
			Md => q{d/M},
			yyyyM => q{M/y G},
			yyyyMEd => q{E، d/M/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E، d MMM y G},
			yyyyMMMd => q{d MMM y G},
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
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E، d/M – E، d/M},
				d => q{E، d/M – E، d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E، d MMM – E، d MMM},
				d => q{E، d MMM – E، d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E، d/M/y – E، d/M/y},
				d => q{E، d/M/y – E، d/M/y},
				y => q{E، d/M/y – E، d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E، d MMM – E، d MMM، y},
				d => q{E، d MMM – E، d MMM، y},
				y => q{E، d MMM y – E، d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM، y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
		'gregorian' => {
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E، d/M – E، d/M},
				d => q{E، d/M – E، d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E، d MMM – E، d MMM},
				d => q{E، d MMM – E، d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			fallback => '{0} – {1}',
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E، d/M/y – E، d/M/y},
				d => q{E، d/M/y – E، d/M/y},
				y => q{E، d/M/y – E، d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E، d MMM – E، d MMM، y},
				d => q{E، d MMM – E، d MMM، y},
				y => q{E، d MMM y – E، d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM، y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(وقتو {0}),
		'Asia/Singapore' => {
			exemplarCity => q#سيڠاڤورا#,
		},
		'Brunei' => {
			long => {
				'standard' => q#وقتو بروني دارالسلام#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#باندر تيدق دکتاهوءي#,
		},
		'India' => {
			long => {
				'standard' => q#وقتو ڤياواي اينديا#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#وقتو لاٴوتن هيندي#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#وقتو إندونيسيا تڠه#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#وقتو إندونيسيا تيمور#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#وقتو إندونيسيا بارات#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#وقتو مليسيا#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
