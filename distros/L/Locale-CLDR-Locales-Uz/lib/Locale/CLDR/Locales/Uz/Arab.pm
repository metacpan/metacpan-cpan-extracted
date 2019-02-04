=encoding utf8

=head1

Locale::CLDR::Locales::Uz::Arab - Package for language Uzbek

=cut

package Locale::CLDR::Locales::Uz::Arab;
# This file auto generated from Data\common\main\uz_Arab.xml
#	on Sun  3 Feb  2:25:32 pm GMT

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

extends('Locale::CLDR::Locales::Uz');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'fa' => 'دری',
 				'ps' => 'پشتو',
 				'uz' => 'اوزبیک',

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
			auxiliary => qr{[‌‍‎‏ ټ ځ څ ډ ړ ږ ښ ګ ڼ ي ۍ ې]},
			index => ['ء', 'آ', 'أ', 'ؤ', 'ئ', 'ا', 'ب', 'پ', 'ة', 'ت', 'ث', 'ټ', 'ج', 'چ', 'ح', 'خ', 'ځ', 'څ', 'د', 'ذ', 'ډ', 'ر', 'ز', 'ړ', 'ږ', 'ژ', 'س', 'ش', 'ښ', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'ګ', 'گ', 'ل', 'م', 'ن', 'ڼ', 'ه', 'و', 'ۇ', 'ۉ', 'ي', 'ی', 'ۍ', 'ې'],
			main => qr{[ً ٌ ٍ َ ُ ِ ّ ْ ٔ ٰ ء آ أ ؤ ئ ا ب پ ة ت ث ج چ ح خ د ذ ر ز ژ س ش ص ض ط ظ ع غ ف ق ک گ ل م ن ه و ۇ ۉ ی]},
			numbers => qr{[‎ \- , ٫ ٬ . % ٪ ‰ ؉ + − 0۰ 1۱ 2۲ 3۳ 4۴ 5۵ 6۶ 7۷ 8۸ 9۹]},
		};
	},
EOT
: sub {
		return { index => ['ء', 'آ', 'أ', 'ؤ', 'ئ', 'ا', 'ب', 'پ', 'ة', 'ت', 'ث', 'ټ', 'ج', 'چ', 'ح', 'خ', 'ځ', 'څ', 'د', 'ذ', 'ډ', 'ر', 'ز', 'ړ', 'ږ', 'ژ', 'س', 'ش', 'ښ', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'ګ', 'گ', 'ل', 'م', 'ن', 'ڼ', 'ه', 'و', 'ۇ', 'ۉ', 'ي', 'ی', 'ۍ', 'ې'], };
},
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
			'group' => q(.),
			'minusSign' => q(‎−),
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
				'currency' => q(افغانی),
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
							'فبر',
							'مار',
							'اپر',
							'می',
							'جون',
							'جول',
							'اگس',
							'سپت',
							'اکت',
							'نوم',
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
						mon => 'د.',
						tue => 'س.',
						wed => 'چ.',
						thu => 'پ.',
						fri => 'ج.',
						sat => 'ش.',
						sun => 'ی.'
					},
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
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'ق.م.',
				'1' => 'م.'
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
			'full' => q{G y نچی ییل d نچی MMMM EEEE کونی},
			'long' => q{d نچی MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{GGGGG y/M/d},
		},
		'gregorian' => {
			'full' => q{y نچی ییل d نچی MMMM EEEE کونی},
			'long' => q{d نچی MMMM y},
			'medium' => q{d MMM y},
			'short' => q{y/M/d},
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
		'generic' => {
			MMMMd => q{d نچی MMMM},
			Md => q{M/d},
		},
		'gregorian' => {
			MMMMd => q{d نچی MMMM},
			Md => q{M/d},
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
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Afghanistan' => {
			long => {
				'standard' => q#افغانستان وقتی#,
			},
		},
		'Asia/Kabul' => {
			exemplarCity => q#کابل#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
