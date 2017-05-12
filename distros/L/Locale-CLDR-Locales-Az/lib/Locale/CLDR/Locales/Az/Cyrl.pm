=head1

Locale::CLDR::Locales::Az::Cyrl - Package for language Azerbaijani

=cut

package Locale::CLDR::Locales::Az::Cyrl;
# This file auto generated from Data\common\main\az_Cyrl.xml
#	on Fri 29 Apr  6:52:00 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Az');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'az' => 'азәрбајҹан дили',
 				'de' => 'алман дили',
 				'en' => 'инҝилис дили',
 				'es' => 'испан дили',
 				'fr' => 'франсыз дили',
 				'it' => 'италјан дили',
 				'ja' => 'јапон дили',
 				'pt' => 'португал дили',
 				'ru' => 'рус дили',
 				'zh' => 'чин дили',

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
			'Cyrl' => 'Кирил',

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
			'AZ' => 'Азәрбајҹан',
 			'BR' => 'Бразилија',
 			'CN' => 'Чин',
 			'DE' => 'Алманија',
 			'FR' => 'Франса',
 			'IN' => 'Һиндистан',
 			'IT' => 'Италија',
 			'JP' => 'Јапонија',
 			'RU' => 'Русија',
 			'US' => 'Америка Бирләшмиш Штатлары',

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
			auxiliary => qr{(?^u:[ц щ ъ ь э ю я])},
			index => ['А', 'Ә', 'Б', 'В', 'Г', 'Ғ', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'Ј', 'К', 'Ҝ', 'Л', 'М', 'Н', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Һ', 'Ч', 'Ҹ', 'Ш', 'Ы'],
			main => qr{(?^u:[а ә б в г ғ д е ж з и й ј к ҝ л м н о ө п р с т у ү ф х һ ч ҹ ш ы])},
		};
	},
EOT
: sub {
		return { index => ['А', 'Ә', 'Б', 'В', 'Г', 'Ғ', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'Ј', 'К', 'Ҝ', 'Л', 'М', 'Н', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Һ', 'Ч', 'Ҹ', 'Ш', 'Ы'], };
},
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

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
		'AZN' => {
			symbol => '₼',
			display_name => {
				'currency' => q(манат),
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
							'јанвар',
							'феврал',
							'март',
							'апрел',
							'май',
							'ијун',
							'ијул',
							'август',
							'сентјабр',
							'октјабр',
							'нојабр',
							'декабр'
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
						mon => 'базар ертәси',
						tue => 'чәршәнбә ахшамы',
						wed => 'чәршәнбә',
						thu => 'ҹүмә ахшамы',
						fri => 'ҹүмә',
						sat => 'шәнбә',
						sun => 'базар'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => '1',
						tue => '2',
						wed => '3',
						thu => '4',
						fri => '5',
						sat => '6',
						sun => '7'
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night2' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night2' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
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
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, d, MMMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{dd.MM.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d, MMMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{dd.MM.yy},
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
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{E, d, MMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			yyyyM => q{MM.y G},
			yyyyMEd => q{E, dd.MM.y G},
			yyyyMMM => q{MMM, y G},
			yyyyMMMEd => q{E, d, MMM, y G},
			yyyyMMMd => q{d MMM, y G},
			yyyyMd => q{dd.MM.y G},
		},
		'gregorian' => {
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{E, d, MMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			yM => q{MM.y},
			yMEd => q{E, dd.MM.y},
			yMMM => q{MMM, y},
			yMMMEd => q{E, d, MMM, y},
			yMMMd => q{d MMM, y},
			yMd => q{dd.MM.y},
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

no Moo;

1;

# vim: tabstop=4
