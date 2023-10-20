=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Os - Package for language Ossetic

=cut

package Locale::CLDR::Locales::Os;
# This file auto generated from Data\common\main\os.xml
#	on Fri 13 Oct  9:32:47 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

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
			index => ['А', 'Ӕ', 'Б', 'В', 'Г', '{Гъ}', 'Д', '{Дж}', '{Дз}', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й', 'К', '{Къ}', 'Л', 'М', 'Н', 'О', 'П', '{Пъ}', 'Р', 'С', 'Т', '{Тъ}', 'У', 'Ф', 'Х', '{Хъ}', 'Ц', '{Цъ}', 'Ч', '{Чъ}', 'Ш', 'Щ', 'Ы', 'Э', 'Ю', 'Я'],
			main => qr{[а ӕ б в г {гъ} д {дж} {дз} е ё ж з и й к {къ} л м н о п {пъ} р с т {тъ} у ф х {хъ} ц {цъ} ч {чъ} ш щ ъ ы ь э ю я]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ‚ " “ „ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Ӕ', 'Б', 'В', 'Г', '{Гъ}', 'Д', '{Дж}', '{Дз}', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й', 'К', '{Къ}', 'Л', 'М', 'Н', 'О', 'П', '{Пъ}', 'Р', 'С', 'Т', '{Тъ}', 'У', 'Ф', 'Х', '{Хъ}', 'Ц', '{Цъ}', 'Ч', '{Чъ}', 'Ш', 'Щ', 'Ы', 'Э', 'Ю', 'Я'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
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
					'day' => {
						'name' => q(боны),
						'one' => q({0} бон),
						'other' => q({0} боны),
					},
					'hour' => {
						'name' => q(сахаты),
						'one' => q({0} сахат),
						'other' => q({0} сахаты),
					},
					'minute' => {
						'name' => q(минуты),
						'one' => q({0} минут),
						'other' => q({0} минуты),
					},
					'month' => {
						'name' => q(мӕйы),
						'one' => q({0} мӕй),
						'other' => q({0} мӕйы),
					},
					'second' => {
						'name' => q(секунды),
						'one' => q({0} секунд),
						'other' => q({0} секунды),
					},
					'week' => {
						'name' => q(къуырийы),
						'one' => q({0} къуыри),
						'other' => q({0} къуырийы),
					},
					'year' => {
						'name' => q(азы),
						'one' => q({0} аз),
						'other' => q({0} азы),
					},
				},
				'short' => {
					'day' => {
						'name' => q(боны),
						'one' => q({0} бон),
						'other' => q({0} боны),
					},
					'hour' => {
						'name' => q(сахаты),
						'one' => q({0} с.),
						'other' => q({0} с.),
					},
					'minute' => {
						'name' => q(минуты),
						'one' => q({0} мин.),
						'other' => q({0} мин.),
					},
					'month' => {
						'name' => q(мӕйы),
					},
					'second' => {
						'name' => q(секунды),
					},
					'week' => {
						'name' => q(къуырийы),
					},
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} ӕмӕ {1}),
				2 => q({0} ӕмӕ {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(НН),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Бразилиаг реал),
				'one' => q(бразилиаг реал),
				'other' => q(бразилиаг реалы),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Евро),
				'one' => q(евро),
				'other' => q(евройы),
			},
		},
		'GBP' => {
			symbol => '£',
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-аг квартал',
						1 => '2-аг квартал',
						2 => '3-аг квартал',
						3 => '4-ӕм квартал'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1-аг кв.',
						1 => '2-аг кв.',
						2 => '3-аг кв.',
						3 => '4-ӕм кв.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
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
			'full' => q{EEEE, d MMMM, y 'аз' G},
			'long' => q{d MMMM, y 'аз' G},
			'medium' => q{dd MMM y 'аз' G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y 'аз'},
			'long' => q{d MMMM, y 'аз'},
			'medium' => q{dd MMM y 'аз'},
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
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{ccc, d MMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM.y},
			yMEd => q{E, dd.MM.y},
			yMMM => q{LLL y},
			yMMMEd => q{E, d MMM y},
			yQQQ => q{y-'ӕм' 'азы' QQQ},
			yQQQQ => q{y-'ӕм' 'азы' QQQQ},
		},
		'gregorian' => {
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{ccc, d MMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
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
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} рӕстӕг),
		fallbackFormat => q({1} ({0})),
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
