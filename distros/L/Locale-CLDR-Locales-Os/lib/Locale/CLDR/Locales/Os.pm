=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Os - Package for language Ossetic

=cut

package Locale::CLDR::Locales::Os;
# This file auto generated from Data\common\main\os.xml
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
				'ab' => 'абхазаг',
 				'ady' => 'адыгейаг',
 				'ae' => 'авестӕ',
 				'af' => 'африкаанс',
 				'ang' => 'рагон англисаг',
 				'ar' => 'араббаг',
 				'av' => 'авайраг',
 				'az' => 'тӕтӕйраг',
 				'ba' => 'башкираг',
 				'bg' => 'болгайраг',
 				'bs' => 'босниаг',
 				'bua' => 'бурятаг',
 				'ca' => 'каталайнаг',
 				'ce' => 'цӕцӕйнаг',
 				'cop' => 'коптаг',
 				'cs' => 'чехаг',
 				'cv' => 'чувашаг',
 				'da' => 'даниаг',
 				'de' => 'немыцаг',
 				'de_AT' => 'австралиаг немыцаг',
 				'de_CH' => 'швйецариаг немыцаг',
 				'egy' => 'рагон египтаг',
 				'el' => 'бердзейнаг',
 				'en' => 'англисаг',
 				'en_AU' => 'австралиаг англисаг',
 				'en_CA' => 'канадӕйаг англисаг',
 				'en_GB' => 'бритайнаг англисаг',
 				'en_US' => 'америкаг англисаг',
 				'eo' => 'есперанто',
 				'es' => 'испайнаг',
 				'es_419' => 'латинаг америкаг англисаг',
 				'es_ES' => 'европӕйаг англисаг',
 				'es_MX' => 'мексикӕйаг испайнаг',
 				'et' => 'естойнаг',
 				'eu' => 'баскаг',
 				'fa' => 'персайнаг',
 				'fi' => 'финнаг',
 				'fil' => 'филиппинаг',
 				'fj' => 'фиджи',
 				'fo' => 'фарераг',
 				'fr' => 'францаг',
 				'fr_CA' => 'канадӕйаг францаг',
 				'fr_CH' => 'швейцариаг францаг',
 				'fro' => 'рагон францаг',
 				'ga' => 'ирландиаг',
 				'grc' => 'рагон бердзейнаг',
 				'he' => 'уираг',
 				'hr' => 'хорватаг',
 				'hu' => 'венгериаг',
 				'hy' => 'сомихаг',
 				'inh' => 'мӕхъӕлон',
 				'it' => 'италиаг',
 				'ja' => 'япойнаг',
 				'ka' => 'гуырдзиаг',
 				'kbd' => 'кӕсгон',
 				'krc' => 'бӕлхъӕрон',
 				'ku' => 'курдаг',
 				'kum' => 'хъуымыхъхъаг',
 				'la' => 'латинаг',
 				'lez' => 'лекъаг',
 				'mk' => 'мӕчъидон',
 				'os' => 'ирон',
 				'pt' => 'португалиаг',
 				'pt_BR' => 'бразилиаг португалиаг',
 				'pt_PT' => 'европӕйаг полтугалиаг',
 				'rom' => 'цигайнаг',
 				'ru' => 'уырыссаг',
 				'und' => 'нӕзонгӕ ӕвзаг',
 				'zh' => 'китайаг',
 				'zh_Hans' => 'ӕнцонгонд китайаг',
 				'zh_Hant' => 'традицион китайаг',

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
			'Arab' => 'Араббаг',
 			'Cyrl' => 'Киррилицӕ',
 			'Hans' => 'Ӕнцонгонд китайаг',
 			'Hant' => 'Традицион китайаг',
 			'Latn' => 'Латинаг',
 			'Zxxx' => 'Нӕфысгӕ',
 			'Zzzz' => 'Нӕзонгӕ скрипт',

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
			'001' => 'Дуне',
 			'002' => 'Африкӕ',
 			'009' => 'Океани',
 			'019' => 'Америкӕ',
 			'142' => 'Ази',
 			'150' => 'Европӕ',
 			'BR' => 'Бразили',
 			'CN' => 'Китай',
 			'DE' => 'Герман',
 			'FR' => 'Франц',
 			'GB' => 'Стыр Британи',
 			'GE' => 'Гуырдзыстон',
 			'IN' => 'Инди',
 			'IT' => 'Итали',
 			'JP' => 'Япон',
 			'RU' => 'Уӕрӕсе',
 			'US' => 'АИШ',
 			'ZZ' => 'Нӕзонгӕ бӕстӕ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Къӕлиндар',
 			'numbers' => 'Нымӕцтӕ',

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
 				'gregorian' => q{Грегориан къӕлиндар},
 				'hebrew' => q{Уирӕгты къӕлиндар},
 				'persian' => q{Персайнаг къӕлиндар},
 			},
 			'numbers' => {
 				'latn' => q{Нырыккон цифрӕтӕ},
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
			'metric' => q{Метрикон},
 			'UK' => q{СБ},
 			'US' => q{АИШ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Ӕвзаг: {0}',
 			'script' => 'Скрипт: {0}',
 			'region' => 'Бӕстӕ: {0}',

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
			index => ['А', 'Ӕ', 'Б', 'В', 'Г', '{Гъ}', 'Д', '{Дж}', '{Дз}', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', '{Къ}', 'Л', 'М', 'Н', 'О', 'П', '{Пъ}', 'Р', 'С', 'Т', '{Тъ}', 'У', 'Ф', 'Х', '{Хъ}', 'Ц', '{Цъ}', 'Ч', '{Чъ}', 'Ш', 'Щ', 'Ы', 'Э', 'Ю', 'Я'],
			main => qr{[а ӕ б в г {гъ} д {дж} {дз} её ж з и й к {къ} л м н о п {пъ} р с т {тъ} у ф х {хъ} ц {цъ} ч {чъ} ш щ ъ ы ь э ю я]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘‚ "“„ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Ӕ', 'Б', 'В', 'Г', '{Гъ}', 'Д', '{Дж}', '{Дз}', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', '{Къ}', 'Л', 'М', 'Н', 'О', 'П', '{Пъ}', 'Р', 'С', 'Т', '{Тъ}', 'У', 'Ф', 'Х', '{Хъ}', 'Ц', '{Цъ}', 'Ч', '{Чъ}', 'Ш', 'Щ', 'Ы', 'Э', 'Ю', 'Я'], };
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
	default		=> qq{„},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} сахат),
						'other' => q({0} сахаты),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} сахат),
						'other' => q({0} сахаты),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} минут),
						'other' => q({0} минуты),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} минут),
						'other' => q({0} минуты),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} мӕй),
						'other' => q({0} мӕйы),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} мӕй),
						'other' => q({0} мӕйы),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} секунд),
						'other' => q({0} секунды),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} секунд),
						'other' => q({0} секунды),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} къуыри),
						'other' => q({0} къуырийы),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} къуыри),
						'other' => q({0} къуырийы),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} аз),
						'other' => q({0} азы),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} аз),
						'other' => q({0} азы),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(боны),
						'one' => q({0} бон),
						'other' => q({0} боны),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(боны),
						'one' => q({0} бон),
						'other' => q({0} боны),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(сахаты),
						'one' => q({0} с.),
						'other' => q({0} с.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(сахаты),
						'one' => q({0} с.),
						'other' => q({0} с.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(минуты),
						'one' => q({0} мин.),
						'other' => q({0} мин.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(минуты),
						'one' => q({0} мин.),
						'other' => q({0} мин.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(мӕйы),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(мӕйы),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(секунды),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(секунды),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(къуырийы),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(къуырийы),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(азы),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(азы),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:уойы|у|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:нӕйы|н|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} ӕмӕ {1}),
				2 => q({0} ӕмӕ {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
			'nan' => q(НН),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(Бразилиаг реал),
				'one' => q(бразилиаг реал),
				'other' => q(бразилиаг реалы),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Евро),
				'one' => q(евро),
				'other' => q(евройы),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Бритайнаг Фунт),
				'one' => q(бритайнаг фунт),
				'other' => q(бритайнаг фунты),
			},
		},
		'GEL' => {
			symbol => '₾',
			display_name => {
				'currency' => q(Лар),
				'one' => q(лар),
				'other' => q(лары),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Сом),
				'one' => q(сом),
				'other' => q(сомы),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(АИШ-ы Доллар),
				'one' => q(АИШ-ы доллар),
				'other' => q(АИШ-ы доллары),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Нӕзонгӕ валютӕ),
				'one' => q(нӕзонгӕ валютӕ),
				'other' => q(нӕзонгӕ валютӕйы),
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
							'янв.',
							'фев.',
							'мар.',
							'апр.',
							'майы',
							'июны',
							'июлы',
							'авг.',
							'сен.',
							'окт.',
							'ноя.',
							'дек.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'январы',
							'февралы',
							'мартъийы',
							'апрелы',
							'майы',
							'июны',
							'июлы',
							'августы',
							'сентябры',
							'октябры',
							'ноябры',
							'декабры'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Янв.',
							'Февр.',
							'Март.',
							'Апр.',
							'Май',
							'Июнь',
							'Июль',
							'Авг.',
							'Сент.',
							'Окт.',
							'Нояб.',
							'Дек.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Я',
							'Ф',
							'М',
							'А',
							'М',
							'И',
							'И',
							'А',
							'С',
							'О',
							'Н',
							'Д'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Январь',
							'Февраль',
							'Мартъи',
							'Апрель',
							'Май',
							'Июнь',
							'Июль',
							'Август',
							'Сентябрь',
							'Октябрь',
							'Ноябрь',
							'Декабрь'
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
						mon => 'крс',
						tue => 'дцг',
						wed => 'ӕрт',
						thu => 'цпр',
						fri => 'мрб',
						sat => 'сбт',
						sun => 'хцб'
					},
					wide => {
						mon => 'къуырисӕр',
						tue => 'дыццӕг',
						wed => 'ӕртыццӕг',
						thu => 'цыппӕрӕм',
						fri => 'майрӕмбон',
						sat => 'сабат',
						sun => 'хуыцаубон'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Крс',
						tue => 'Дцг',
						wed => 'Ӕрт',
						thu => 'Цпр',
						fri => 'Мрб',
						sat => 'Сбт',
						sun => 'Хцб'
					},
					narrow => {
						mon => 'К',
						tue => 'Д',
						wed => 'Ӕ',
						thu => 'Ц',
						fri => 'М',
						sat => 'С',
						sun => 'Х'
					},
					wide => {
						mon => 'Къуырисӕр',
						tue => 'Дыццӕг',
						wed => 'Ӕртыццӕг',
						thu => 'Цыппӕрӕм',
						fri => 'Майрӕмбон',
						sat => 'Сабат',
						sun => 'Хуыцаубон'
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
					abbreviated => {0 => '1-аг кв.',
						1 => '2-аг кв.',
						2 => '3-аг кв.',
						3 => '4-ӕм кв.'
					},
					wide => {0 => '1-аг квартал',
						1 => '2-аг квартал',
						2 => '3-аг квартал',
						3 => '4-ӕм квартал'
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
					'am' => q{ӕмбисбоны размӕ},
					'pm' => q{ӕмбисбоны фӕстӕ},
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
				'0' => 'н.д.а.',
				'1' => 'н.д.'
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
			'full' => q{EEEE, d MMMM, y 'аз' G},
			'long' => q{d MMMM, y 'аз' G},
			'medium' => q{dd MMM y 'аз' G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y 'аз'},
			'long' => q{d MMMM, y 'аз'},
			'medium' => q{dd MMM y 'аз'},
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
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
		'generic' => {
			MEd => q{E, dd.MM},
			MMMEd => q{ccc, d MMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y},
			yM => q{MM.y},
			yMEd => q{E, dd.MM.y},
			yMMM => q{LLL y},
			yMMMEd => q{E, d MMM y},
			yQQQ => q{y-'ӕм' 'азы' QQQ},
			yQQQQ => q{y-'ӕм' 'азы' QQQQ},
		},
		'gregorian' => {
			MEd => q{E, dd.MM},
			MMMEd => q{ccc, d MMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			yM => q{MM.y},
			yMEd => q{E, dd.MM.y},
			yMMM => q{LLL y},
			yMMMEd => q{E, d MMM y},
			yQQQ => q{y-'ӕм' 'азы' QQQ},
			yQQQQ => q{y-'ӕм' 'азы' QQQQ},
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
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'gregorian' => {
			M => {
				M => q{M–M},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} рӕстӕг),
		'Asia/Tbilisi' => {
			exemplarCity => q#Тбилис#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#Нӕзонгӕ#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Минск#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Мӕскуы#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Астӕуккаг Европӕйаг сӕрдыгон рӕстӕг#,
				'generic' => q#Астӕуккаг Европӕйаг рӕстӕг#,
				'standard' => q#Астӕуккаг Европӕйаг стандартон рӕстӕг#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Скӕсӕн Европӕйаг сӕрдыгон рӕстӕг#,
				'generic' => q#Скӕсӕн Европӕйаг рӕстӕг#,
				'standard' => q#Скӕсӕн Европӕйаг стандартон рӕстӕг#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ныгъуылӕн Европӕйаг сӕрдыгон рӕстӕг#,
				'generic' => q#Ныгъуылӕн Европӕйаг рӕстӕг#,
				'standard' => q#Ныгъуылӕн Европӕйаг стандартон рӕстӕг#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Гринвичы рӕстӕмбис рӕстӕг#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Гуырдзыстоны сӕрдыгон рӕстӕг#,
				'generic' => q#Гуырдзыстоны рӕстӕг#,
				'standard' => q#Гуырдзыстоны стандартон рӕстӕг#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Мӕскуыйы сӕрдыгон рӕстӕг#,
				'generic' => q#Мӕскуыйы рӕстӕг#,
				'standard' => q#Мӕскуыйы стандартон рӕстӕг#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
