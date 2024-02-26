=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sr::Cyrl::Ba - Package for language Serbian

=cut

package Locale::CLDR::Locales::Sr::Cyrl::Ba;
# This file auto generated from Data\common\main\sr_Cyrl_BA.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Sr::Cyrl');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'be' => 'бјелоруски',
 				'bm' => 'бамананкан',
 				'bn' => 'бангла',
 				'crl' => 'сјевероисточни кри',
 				'de' => 'њемачки',
 				'de_CH' => 'швајцарски високи њемачки',
 				'frr' => 'сјевернофризијски',
 				'gsw' => 'њемачки (Швајцарска)',
 				'ht' => 'хаићански креолски',
 				'lrc' => 'сјеверни лури',
 				'nd' => 'сјеверни ндебеле',
 				'nds' => 'нискоњемачки',
 				'nso' => 'сјеверни сото',
 				'ojb' => 'сјеверозападни оџибва',
 				'se' => 'сјеверни сами',
 				'ttm' => 'сјеверни тучон',

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
			'001' => 'свијет',
 			'003' => 'Сјеверноамерички континент',
 			'015' => 'Сјеверна Африка',
 			'019' => 'Сјеверна и Јужна Америка',
 			'021' => 'Сјеверна Америка',
 			'154' => 'Сјеверна Европа',
 			'AC' => 'острво Асенсион',
 			'AX' => 'Оландска острва',
 			'BL' => 'Сен Бартелеми',
 			'BN' => 'Брунеји',
 			'BV' => 'острво Буве',
 			'BY' => 'Бјелорусија',
 			'CC' => 'Кокосова (Килинг) острва',
 			'CP' => 'острво Клипертон',
 			'CZ' => 'Чешка Република',
 			'DE' => 'Њемачка',
 			'FK' => 'Фокландска острва',
 			'FK@alt=variant' => 'Фолкландска (Малвинска) острва',
 			'FO' => 'Фарска острва',
 			'GS' => 'Јужна Џорџија и Јужна Сендвичка острва',
 			'GU' => 'Гвам',
 			'GW' => 'Гвинеја Бисао',
 			'HK' => 'Хонгконг (САО Кине)',
 			'HM' => 'острво Херд и острва Макдоналд',
 			'KM' => 'Комори',
 			'KP' => 'Сјеверна Кореја',
 			'MK' => 'Сјеверна Македонија',
 			'MM' => 'Мјанмар (Бурма)',
 			'MP' => 'Сјеверна Маријанска острва',
 			'NF' => 'острво Норфок',
 			'NU' => 'Нијуе',
 			'PS' => 'палестинске територије',
 			'RE' => 'Реунион',
 			'TF' => 'Француске јужне територије',
 			'UM' => 'Спољна острва САД',
 			'VC' => 'Свети Винсент и Гренадини',
 			'VG' => 'Британска Дјевичанска острва',
 			'VI' => 'Америчка Дјевичанска острва',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'collation' => 'редослијед сортирања',
 			'ms' => 'систем мјерних јединица',

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
 				'compat' => q{претходни редослијед сортирања, због компатибилности},
 				'dictionary' => q{редослијед сортирања у рјечнику},
 				'ducet' => q{подразумијевани Unicode редослијед сортирања},
 				'phonetic' => q{фонетски редослијед сортирања},
 				'reformed' => q{реформисани редослијед сортирања},
 				'search' => q{претрага опште намјене},
 				'standard' => q{стандардни редослијед сортирања},
 				'unihan' => q{редослијед сортирања радикалних потеза},
 			},
 			'numbers' => {
 				'mymr' => q{мјанмарске цифре},
 			},

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(јоби{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(јоби{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(q{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(q{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(R{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(R{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(Q{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(Q{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0} G),
						'one' => q({0} ге сила),
						'other' => q({0} ге сила),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} G),
						'one' => q({0} ге сила),
						'other' => q({0} ге сила),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} вијека),
						'name' => q(вијекови),
						'one' => q({0} вијек),
						'other' => q({0} вијекова),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} вијека),
						'name' => q(вијекови),
						'one' => q({0} вијек),
						'other' => q({0} вијекова),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} мјесеца),
						'one' => q({0} мјесец),
						'other' => q({0} мјесеци),
						'per' => q({0} мјесечно),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} мјесеца),
						'one' => q({0} мјесец),
						'other' => q({0} мјесеци),
						'per' => q({0} мјесечно),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} недјеље),
						'name' => q(недјеље),
						'one' => q({0} недјеља),
						'other' => q({0} недјеља),
						'per' => q({0} недјељно),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} недјеље),
						'name' => q(недјеље),
						'one' => q({0} недјеља),
						'other' => q({0} недјеља),
						'per' => q({0} недјељно),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} mA),
						'one' => q({0} милиампер),
						'other' => q({0} милиампера),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} mA),
						'one' => q({0} милиампер),
						'other' => q({0} милиампера),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} kJ),
						'one' => q({0} килоџул),
						'other' => q({0} килоџула),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} kJ),
						'one' => q({0} килоџул),
						'other' => q({0} килоџула),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} Hz),
						'one' => q({0} херц),
						'other' => q({0} херца),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} Hz),
						'one' => q({0} херц),
						'other' => q({0} херца),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} свјетлосне године),
						'name' => q(свјетлосне године),
						'one' => q({0} свјетлосна година),
						'other' => q({0} свјетлосних година),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} свјетлосне године),
						'name' => q(свјетлосне године),
						'one' => q({0} свјетлосна година),
						'other' => q({0} свјетлосних година),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} грана),
						'one' => q({0} гран),
						'other' => q({0} гранова),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} грана),
						'one' => q({0} гран),
						'other' => q({0} гранова),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} inHg),
						'one' => q({0} инч живиног стуба),
						'other' => q({0} инча живиног стуба),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} inHg),
						'one' => q({0} инч живиног стуба),
						'other' => q({0} инча живиног стуба),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} милибар),
						'other' => q({0} милибара),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} милибар),
						'other' => q({0} милибара),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} акер стопе),
						'one' => q({0} ac ft),
						'other' => q({0} акер стопа),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} акер стопе),
						'one' => q({0} ac ft),
						'other' => q({0} акер стопа),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'one' => q({0} имп. галон),
						'other' => q({0} имп. галона),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'one' => q({0} имп. галон),
						'other' => q({0} имп. галона),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} мјес.),
						'one' => q({0} м),
						'other' => q({0} м),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} мјес.),
						'one' => q({0} м),
						'other' => q({0} м),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} с),
						'one' => q({0} сек),
						'other' => q({0} с),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} с),
						'one' => q({0} сек),
						'other' => q({0} с),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} н),
						'one' => q({0} нед.),
						'other' => q({0} н),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} н),
						'one' => q({0} нед.),
						'other' => q({0} н),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} год.),
						'one' => q({0} г),
						'other' => q({0} г),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} год.),
						'one' => q({0} г),
						'other' => q({0} г),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} hp),
						'one' => q({0} кс),
						'other' => q({0} кс),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} hp),
						'one' => q({0} кс),
						'other' => q({0} кс),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} д. каш.),
						'name' => q(д. каш.),
						'one' => q({0} д. каш.),
						'other' => q({0} д. каш.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} д. каш.),
						'name' => q(д. каш.),
						'one' => q({0} д. каш.),
						'other' => q({0} д. каш.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} и. д. к.),
						'name' => q(и. д. к.),
						'one' => q({0} и. д. к.),
						'other' => q({0} и. д. к.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} и. д. к.),
						'name' => q(и. д. к.),
						'one' => q({0} и. д. к.),
						'other' => q({0} и. д. к.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'one' => q({0}/gal Imp),
						'other' => q({0}/gal Imp),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'one' => q({0}/gal Imp),
						'other' => q({0}/gal Imp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} мјес.),
						'name' => q(мјесеци),
						'one' => q({0} мјес.),
						'other' => q({0} мјес.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} мјес.),
						'name' => q(мјесеци),
						'one' => q({0} мјес.),
						'other' => q({0} мјес.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(свјетлосне год.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(свјетлосне год.),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} грана),
						'name' => q(гран),
						'one' => q({0} гран),
						'other' => q({0} гранова),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} грана),
						'name' => q(гран),
						'one' => q({0} гран),
						'other' => q({0} гранова),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'one' => q(B {0}),
						'other' => q(Б {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'one' => q(B {0}),
						'other' => q(Б {0}),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BAM' => {
			display_name => {
				'currency' => q(Босанскохерцеговачка конвертибилна марка),
				'few' => q(босанскохерцеговачке конвертибилне маркe),
				'one' => q(босанскохерцеговачка конвертибилна марка),
				'other' => q(босанскохерцеговачких конвертибилних марака),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Бјелоруска рубља),
				'few' => q(бјелоруске рубље),
				'one' => q(бјелоруска рубља),
				'other' => q(бјелоруских рубљи),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Сјевернокорејски вон),
				'few' => q(сјевернокорејска вона),
				'one' => q(сјевернокорејски вон),
				'other' => q(сјевернокорејских вона),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Никарагванска златна кордоба),
				'few' => q(никарагванске златне кордобе),
				'one' => q(никарагванска златна кордоба),
				'other' => q(никарагванских златних кордоба),
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
						mon => 'пон',
						tue => 'уто',
						wed => 'сри',
						thu => 'чет',
						fri => 'пет',
						sat => 'суб',
						sun => 'нед'
					},
					wide => {
						mon => 'понедјељак',
						tue => 'уторак',
						wed => 'сриједа',
						thu => 'четвртак',
						fri => 'петак',
						sat => 'субота',
						sun => 'недјеља'
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{прије подне},
					'pm' => q{по подне},
				},
				'narrow' => {
					'afternoon1' => q{по подне},
					'evening1' => q{увече},
					'midnight' => q{поноћ},
					'morning1' => q{ујутро},
					'night1' => q{ноћу},
					'noon' => q{подне},
				},
				'wide' => {
					'am' => q{прије подне},
					'pm' => q{по подне},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{а},
					'pm' => q{p},
				},
				'wide' => {
					'am' => q{прије подне},
					'pm' => q{по подне},
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
			wide => {
				'0' => 'прије нове ере'
			},
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
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
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
		regionFormat => q({0}, љетње вријеме),
		regionFormat => q({0}, стандардно вријеме),
		'Afghanistan' => {
			long => {
				'standard' => q#Авганистан вријеме#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Централно-афричко вријеме#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Источно-афричко вријеме#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Јужно-афричко вријеме#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Западно-афричко љетње вријеме#,
				'generic' => q#Западно-афричко вријеме#,
				'standard' => q#Западно-афричко стандардно вријеме#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Аљаска, љетње вријеме#,
				'generic' => q#Аљаска#,
				'standard' => q#Аљаска, стандардно вријеме#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Амазон, љетње вријеме#,
				'generic' => q#Амазон вријеме#,
				'standard' => q#Амазон, стандардно вријеме#,
			},
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Виви, Индијана#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Винсенс, Индијана#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Индијанаполис#,
		},
		'America/Louisville' => {
			exemplarCity => q#Луивил#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Бјула, Сјеверна Дакота#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Центар, Сјеверна Дакота#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Нови Салем, Сјеверна Дакота#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Порт-о-Пренс#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Порт ов Спејн#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Порторико#,
		},
		'America/Regina' => {
			exemplarCity => q#Реџајна#,
		},
		'America/Resolute' => {
			exemplarCity => q#Резолут#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Итокортормит#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Сен Бартелеми#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Сент Џонс#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Сент Томас#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Свифт Карент#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Сјеверноамеричко централно љетње вријеме#,
				'generic' => q#Сјеверноамеричко централно вријеме#,
				'standard' => q#Сјеверноамеричко централно стандардно вријеме#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Сјеверноамеричко источно љетње вријеме#,
				'generic' => q#Сјеверноамеричко источно вријеме#,
				'standard' => q#Сјеверноамеричко источно стандардно вријеме#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Сјеверноамеричко планинско љетње вријеме#,
				'generic' => q#Сјеверноамеричко планинско вријеме#,
				'standard' => q#Сјеверноамеричко планинско стандардно вријеме#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Сјеверноамеричко пацифичко летње вријеме#,
				'generic' => q#Сјеверноамеричко пацифичко вријеме#,
				'standard' => q#Сјеверноамеричко пацифичко стандардно вријеме#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Димон д’Ирвил#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Маквори#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Апија, љетње вријеме#,
				'generic' => q#Апија вријеме#,
				'standard' => q#Апија, стандардно вријеме#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Арабијско љетње вријеме#,
				'generic' => q#Арабијско вријеме#,
				'standard' => q#Арабијско стандардно вријеме#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Лонгјир#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Аргентина, љетње вријеме#,
				'generic' => q#Аргентина вријеме#,
				'standard' => q#Аргентина, стандардно вријеме#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Западна Аргентина, љетње вријеме#,
				'generic' => q#Западна Аргентина вријеме#,
				'standard' => q#Западна Аргентина, стандардно вријеме#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Јерменија, љетње вријеме#,
				'generic' => q#Јерменија вријеме#,
				'standard' => q#Јерменија, стандардно вријеме#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Атлантско љетње вријеме#,
				'generic' => q#Атлантско вријеме#,
				'standard' => q#Атлантско стандардно вријеме#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Аустралијско централно љетње вријеме#,
				'generic' => q#Аустралијско централно вријеме#,
				'standard' => q#Аустралијско централно стандардно вријеме#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Аустралијско централно западно љетње вријеме#,
				'generic' => q#Аустралијско централно западно вријеме#,
				'standard' => q#Аустралијско централно западно стандардно вријеме#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Аустралијско источно љетње вријеме#,
				'generic' => q#Аустралијско источно вријеме#,
				'standard' => q#Аустралијско источно стандардно вријеме#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Аустралијско западно љетње вријеме#,
				'generic' => q#Аустралијско западно вријеме#,
				'standard' => q#Аустралијско западно стандардно вријеме#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Азербејџан, љетње вријеме#,
				'generic' => q#Азербејџан вријеме#,
				'standard' => q#Азербејџан, стандардно вријеме#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Азори, љетње вријеме#,
				'generic' => q#Азори вријеме#,
				'standard' => q#Азори, стандардно вријеме#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Бангладеш, љетње вријеме#,
				'generic' => q#Бангладеш вријеме#,
				'standard' => q#Бангладеш, стандардно вријеме#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Бутан вријеме#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Боливија вријеме#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Бразилија, љетње вријеме#,
				'generic' => q#Бразилија вријеме#,
				'standard' => q#Бразилија, стандардно вријеме#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Брунеј Дарусалум вријеме#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Зеленортска Острва, љетње вријеме#,
				'generic' => q#Зеленортска Острва вријеме#,
				'standard' => q#Зеленортска Острва, стандардно вријеме#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Чаморо вријеме#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Чатам, љетње вријеме#,
				'generic' => q#Чатам вријеме#,
				'standard' => q#Чатам, стандардно вријеме#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Чиле, љетње вријеме#,
				'generic' => q#Чиле вријеме#,
				'standard' => q#Чиле, стандардно вријеме#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Кина, љетње вријеме#,
				'generic' => q#Кина вријеме#,
				'standard' => q#Кинеско стандардно вријеме#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Чојбалсан, љетње вријеме#,
				'generic' => q#Чојбалсан вријеме#,
				'standard' => q#Чојбалсан, стандардно вријеме#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Божићно острво вријеме#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Кокосова (Килинг) острва вријеме#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Колумбија, љетње вријеме#,
				'generic' => q#Колумбија вријеме#,
				'standard' => q#Колумбија, стандардно вријеме#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Кукова Острва, полуљетње вријеме#,
				'generic' => q#Кукова Острва вријеме#,
				'standard' => q#Кукова Острва, стандардно вријеме#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Куба, љетње вријеме#,
				'generic' => q#Куба#,
				'standard' => q#Куба, стандардно вријеме#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Дејвис вријеме#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Димон д’Ирвил вријеме#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Источни Тимор вријеме#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ускршња острва, љетње вријеме#,
				'generic' => q#Ускршња острва вријеме#,
				'standard' => q#Ускршња острва, стандардно вријеме#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Еквадор вријеме#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Координисано универзално вријеме#,
			},
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Ирска, стандардно вријеме#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Британија, љетње вријеме#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Средњоевропско љетње вријеме#,
				'generic' => q#Средњоевропско вријеме#,
				'standard' => q#Средњоевропско стандардно вријеме#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Источноевропско љетње вријеме#,
				'generic' => q#Источноевропско вријеме#,
				'standard' => q#Источноевропско стандардно вријеме#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Западноевропско љетње вријеме#,
				'generic' => q#Западноевропско вријеме#,
				'standard' => q#Западноевропско стандардно вријеме#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Фолкландска Острва, љетње вријеме#,
				'generic' => q#Фолкландска Острва вријеме#,
				'standard' => q#Фолкландска Острва, стандардно вријеме#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Фиџи, љетње вријеме#,
				'generic' => q#Фиџи вријеме#,
				'standard' => q#Фиџи, стандардно вријеме#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Француска Гвајана вријеме#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Француско јужно и антарктичко вријеме#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Средње вријеме по Гриничу#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Галапагос вријеме#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Гамбије вријеме#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Грузија, љетње вријеме#,
				'generic' => q#Грузија вријеме#,
				'standard' => q#Грузија, стандардно вријеме#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Гилбертова острва вријеме#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Источни Гренланд, љетње вријеме#,
				'generic' => q#Источни Гренланд#,
				'standard' => q#Источни Гренланд, стандардно вријеме#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Западни Гренланд, љетње вријеме#,
				'generic' => q#Западни Гренланд#,
				'standard' => q#Западни Гренланд, стандардно вријеме#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Заливско вријеме#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Гвајана вријеме#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Хавајско-алеутско љетње вријеме#,
				'generic' => q#Хавајско-алеутско вријеме#,
				'standard' => q#Хавајско-алеутско стандардно вријеме#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Хонг Конг, љетње вријеме#,
				'generic' => q#Хонг Конг вријеме#,
				'standard' => q#Хонг Конг, стандардно вријеме#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ховд, љетње вријеме#,
				'generic' => q#Ховд вријеме#,
				'standard' => q#Ховд, стандардно вријеме#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Индијско стандардно вријеме#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Индијско океанско вријеме#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Индокина вријеме#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Централно-индонезијско вријеме#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Источно-индонезијско вријеме#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Западно-индонезијско вријеме#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Иран, љетње вријеме#,
				'generic' => q#Иран вријеме#,
				'standard' => q#Иран, стандардно вријеме#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Иркуцк, љетње вријеме#,
				'generic' => q#Иркуцк вријеме#,
				'standard' => q#Иркуцк, стандардно вријеме#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Израелско љетње вријеме#,
				'generic' => q#Израелско вријеме#,
				'standard' => q#Израелско стандардно вријеме#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Јапанско љетње вријеме#,
				'generic' => q#Јапанско вријеме#,
				'standard' => q#Јапанско стандардно вријеме#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Источно-казахстанско вријеме#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Западно-казахстанско вријеме#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Корејско љетње вријеме#,
				'generic' => q#Корејско вријеме#,
				'standard' => q#Корејско стандардно вријеме#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Кошре вријеме#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Краснојарск, љетње вријеме#,
				'generic' => q#Краснојарск вријеме#,
				'standard' => q#Краснојарск, стандардно вријеме#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Киргистан вријеме#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Линијска острва вријеме#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Лорд Хов, љетње вријеме#,
				'generic' => q#Лорд Хов вријеме#,
				'standard' => q#Лорд Хов, стандардно вријеме#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#острво Маквори вријеме#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Магадан, љетње вријеме#,
				'generic' => q#Магадан вријеме#,
				'standard' => q#Магадан, стандардно вријеме#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Малезија вријеме#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Малдиви вријеме#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Маркиз вријеме#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Маршалска Острва вријеме#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Маурицијус, љетње вријеме#,
				'generic' => q#Маурицијус вријеме#,
				'standard' => q#Маурицијус, стандардно вријеме#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Мосон вријеме#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Сјеверозападни Мексико, летње вријеме#,
				'generic' => q#Сјеверозападни Мексико#,
				'standard' => q#Сјеверозападни Мексико, стандардно вријеме#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Мексички Пацифик, љетње вријеме#,
				'generic' => q#Мексички Пацифик#,
				'standard' => q#Мексички Пацифик, стандардно вријеме#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Улан Батор, љетње вријееме#,
				'generic' => q#Улан Батор вријеме#,
				'standard' => q#Улан Батор, стандардно вријеме#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Москва, љетње вријеме#,
				'generic' => q#Москва вријеме#,
				'standard' => q#Москва, стандардно вријеме#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Мјанмар вријеме#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Науру вријеме#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Непал вријеме#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Нова Каледонија, љетње вријеме#,
				'generic' => q#Нова Каледонија вријеме#,
				'standard' => q#Нова Каледонија, стандардно вријеме#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Нови Зеланд, љетње вријеме#,
				'generic' => q#Нови Зеланд вријеме#,
				'standard' => q#Нови Зеланд, стандардно вријеме#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Њуфаундленд, љетње вријеме#,
				'generic' => q#Њуфаундленд#,
				'standard' => q#Њуфаундленд, стандардно вријеме#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Нијуе вријеме#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#острво Норфолк, љетње вријеме#,
				'generic' => q#острво Норфолк вријеме#,
				'standard' => q#острво Норфолк, стандардно вријеме#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Фернандо де Нороња, љетње вријеме#,
				'generic' => q#Фернандо де Нороња вријеме#,
				'standard' => q#Фернандо де Нороња, стандардно вријеме#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Новосибирск, љетње вријеме#,
				'generic' => q#Новосибирск вријеме#,
				'standard' => q#Новосибирск, стандардно вријеме#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Омск, љетње вријеме#,
				'generic' => q#Омск вријеме#,
				'standard' => q#Омск, стандардно вријеме#,
			},
		},
		'Pacific/Niue' => {
			exemplarCity => q#Нијуе#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Пакистан, љетње вријеме#,
				'generic' => q#Пакистан вријеме#,
				'standard' => q#Пакистан, стандардно вријеме#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Палау вријеме#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Папуа Нова Гвинеја вријеме#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Парагвај, љетње вријеме#,
				'generic' => q#Парагвај вријеме#,
				'standard' => q#Парагвај, стандардно вријеме#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Перу, љетње вријеме#,
				'generic' => q#Перу вријеме#,
				'standard' => q#Перу, стандардно вријеме#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Филипини, љетње вријеме#,
				'generic' => q#Филипини вријеме#,
				'standard' => q#Филипини, стандардно вријеме#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Феникс острва вријеме#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Сен Пјер и Микелон, љетње вријеме#,
				'generic' => q#Сен Пјер и Микелон#,
				'standard' => q#Сен Пјер и Микелон, стандардно вријеме#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Питкерн вријеме#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Понпеј вријеме#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Пјонгјаншко вријеме#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Реунион вријеме#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ротера вријеме#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Сахалин, љетње вријеме#,
				'generic' => q#Сахалин вријеме#,
				'standard' => q#Сахалин, стандардно вријеме#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Самоа, љетње вријеме#,
				'generic' => q#Самоа вријеме#,
				'standard' => q#Самоа, стандардно вријеме#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Сејшели вријеме#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Сингапур, стандардно вријеме#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Соломонска Острва вријеме#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Јужна Џорџија вријеме#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Суринам вријеме#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Шова вријеме#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Тахити вријеме#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Тајпеј, љетње вријеме#,
				'generic' => q#Тајпеј вријеме#,
				'standard' => q#Тајпеј, стандардно вријеме#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Таџикистан вријеме#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Токелау вријеме#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Тонга, љетње вријеме#,
				'generic' => q#Тонга вријеме#,
				'standard' => q#Тонга, стандардно вријеме#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Чук вријеме#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Туркменистан, љетње вријеме#,
				'generic' => q#Туркменистан вријеме#,
				'standard' => q#Туркменистан, стандардно вријеме#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Тувалу вријеме#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Уругвај, љетње вријеме#,
				'generic' => q#Уругвај вријеме#,
				'standard' => q#Уругвај, стандардно вријеме#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Узбекистан, љетње вријеме#,
				'generic' => q#Узбекистан вријеме#,
				'standard' => q#Узбекистан, стандардно вријеме#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Вануату, љетње вријеме#,
				'generic' => q#Вануату вријеме#,
				'standard' => q#Вануату, стандардно вријеме#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Венецуела вријеме#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Владивосток, љетње вријеме#,
				'generic' => q#Владивосток вријеме#,
				'standard' => q#Владивосток, стандардно вријеме#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Волгоград, љетње вријеме#,
				'generic' => q#Волгоград вријеме#,
				'standard' => q#Волгоград, стандардно вријеме#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Восток вријеме#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#острво Вејк вријеме#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#острва Валис и Футуна вријеме#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Јакутск, љетње вријеме#,
				'generic' => q#Јакутск вријеме#,
				'standard' => q#Јакутск, стандардно вријеме#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Јекатеринбург, љетње вријеме#,
				'generic' => q#Јекатеринбург вријеме#,
				'standard' => q#Јекатеринбург, стандардно вријеме#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
