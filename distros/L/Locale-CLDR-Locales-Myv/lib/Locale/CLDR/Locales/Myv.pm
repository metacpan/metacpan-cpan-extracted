=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Myv - Package for language Erzya

=cut

package Locale::CLDR::Locales::Myv;
# This file auto generated from Data\common\main\myv.xml
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
				'ab' => 'абхазонь кель',
 				'ace' => 'ачехень кель',
 				'de' => 'немецень кель',
 				'de_AT' => 'Австриянь немецень кель',
 				'de_CH' => 'Швецариянь немецень кель',
 				'en' => 'англонь кель',
 				'en_AU' => 'Австралиянь англонь кель',
 				'en_CA' => 'Канадань англонь кель',
 				'en_GB' => 'Британиянь англонь кель',
 				'en_US' => 'Американь англонь кель',
 				'es' => 'испанонь кель',
 				'es_ES' => 'Европань испанонь кель',
 				'fr' => 'французонь кель',
 				'fr_CA' => 'Канадань французонь кель',
 				'fr_CH' => 'Швецариянь французонь кель',
 				'it' => 'италиянь кель',
 				'ja' => 'япононь кель',
 				'ko' => 'Кореань кель',
 				'myv' => 'эрзянь кель',
 				'pl' => 'польшань кель',
 				'pt' => 'португалонь кель',
 				'ru' => 'рузонь кель',
 				'und' => 'асодавикс кель',
 				'zh' => 'китаень кель',

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
			'Arab' => 'арабонь сёрма',
 			'Cyrl' => 'кирилликань сёрма',
 			'Jpan' => 'япононь сёрма',
 			'Kore' => 'кореань сёрма',
 			'Latn' => 'латинэнь сёрма',

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
			'001' => 'Масторланго',
 			'002' => 'Африка',
 			'011' => 'Африкань чивалгома ёнкс',
 			'014' => 'Африкань чилисема ёнкс',
 			'015' => 'Африкань пелеве ёнкс',
 			'017' => 'Африкань куншка',
 			'019' => 'Америкат',
 			'030' => 'Азиянь чилисема ёнкс',
 			'034' => 'Азиянь чинеле ёнкс',
 			'035' => 'Азиянь чинеле-чилисема ёнкс',
 			'039' => 'Европань чипеле ёнкс',
 			'142' => 'Азия',
 			'143' => 'Азиянь куншка',
 			'145' => 'Азиянь чивалгома ёнкс',
 			'150' => 'Европа',
 			'151' => 'Европань чилисема ёнкс',
 			'154' => 'Европань пелеве ёнкс',
 			'155' => 'Европань чивалгома ёнкс',
 			'AD' => 'Андорра',
 			'AF' => 'Афганистан',
 			'AL' => 'Албания',
 			'AM' => 'Арменэнь мастор',
 			'AO' => 'Ангола',
 			'AQ' => 'Антарктида',
 			'AR' => 'Аргентина',
 			'AS' => 'Американь Самоа',
 			'AT' => 'Австрия',
 			'AU' => 'Австралия',
 			'AX' => 'Аландонь усият',
 			'BB' => 'Барбадос',
 			'BD' => 'Бангладеш',
 			'BE' => 'Белгия',
 			'BG' => 'Болгария',
 			'BI' => 'Бурунди',
 			'BJ' => 'Бенин',
 			'BM' => 'Бермуда',
 			'BO' => 'Боливия',
 			'BR' => 'Бразил',
 			'BW' => 'Ботсвана',
 			'BY' => 'Беларусия',
 			'CA' => 'Канада',
 			'CH' => 'Швейцария',
 			'CK' => 'Кук усият',
 			'CL' => 'Чили',
 			'CN' => 'Китай',
 			'CO' => 'Колумбия',
 			'CU' => 'Куба',
 			'CZ' => 'Чехия',
 			'CZ@alt=variant' => 'Чех Раськемастор',
 			'DE' => 'Германия',
 			'DK' => 'Дания',
 			'DZ' => 'Алгерия',
 			'EE' => 'Эстэнь мастор',
 			'ER' => 'Эритрея',
 			'ES' => 'Испания',
 			'FI' => 'Финнэнь мастор',
 			'FJ' => 'Фиджи',
 			'FO' => 'Фарерэнь усият',
 			'FR' => 'Франция',
 			'GA' => 'Габон',
 			'GD' => 'Гренада',
 			'GM' => 'Гамбия',
 			'GR' => 'Грекень мастор',
 			'GT' => 'Гватемала',
 			'GU' => 'Гуам',
 			'HR' => 'Хорватия',
 			'HT' => 'Гаити',
 			'HU' => 'Венгрия',
 			'IE' => 'Ирландия',
 			'IM' => 'Ман усия',
 			'IN' => 'Индия',
 			'IR' => 'Иран',
 			'IS' => 'Исландия',
 			'IT' => 'Италия',
 			'JP' => 'Япононь мастор',
 			'LI' => 'Лихтенштейн',
 			'LT' => 'Литва',
 			'LU' => 'Люксембург',
 			'LV' => 'Латвия',
 			'MC' => 'Монако',
 			'MD' => 'Молдова',
 			'ME' => 'Монтенегро',
 			'ML' => 'Мали',
 			'MN' => 'Монголонь мастор',
 			'MT' => 'Малта',
 			'MW' => 'Малави',
 			'NA' => 'Намибия',
 			'NC' => 'Од Каледония',
 			'NE' => 'Нигер',
 			'NG' => 'Нигерия',
 			'NL' => 'Нидерланд',
 			'NO' => 'Норвегия',
 			'NP' => 'Непал',
 			'NR' => 'Науру',
 			'NZ' => 'Од Зеландия',
 			'NZ@alt=variant' => 'Аотеароа Од Зеландия',
 			'PA' => 'Панама',
 			'PE' => 'Перу',
 			'PK' => 'Пакистан',
 			'PL' => 'Польша',
 			'PT' => 'Португалонь мастор',
 			'PY' => 'Парагвай',
 			'RO' => 'Румыния',
 			'RS' => 'Сербень мастор',
 			'RU' => 'Рузонь мастор',
 			'SB' => 'Соломон усият',
 			'SD' => 'Судан',
 			'SE' => 'Шведэнь мастор',
 			'SI' => 'Словения',
 			'SK' => 'Словакия',
 			'SN' => 'Сенегал',
 			'SO' => 'Сомалия',
 			'TD' => 'Чад',
 			'TG' => 'Того',
 			'TH' => 'Таймастор',
 			'TO' => 'Тонга',
 			'TV' => 'Тувалу',
 			'TW' => 'Тайван',
 			'TZ' => 'Танзания',
 			'UA' => 'Украина',
 			'UG' => 'Уганда',
 			'UN' => 'Вейсэндязь Раськетнень Организация',
 			'US' => 'Американь Вейсэндявкс Штаттнэ',
 			'US@alt=short' => 'АВШ',
 			'UY' => 'Уругвай',
 			'VA' => 'Ватикан ош',
 			'VU' => 'Вануату',
 			'WS' => 'Самоа',
 			'XK' => 'Косово',
 			'ZM' => 'Замбия',
 			'ZW' => 'Зимбабве',
 			'ZZ' => 'Асодавикс Ёнкс',

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
			auxiliary => qr{[ӓ ә є җ ѕ і ҥ ў ѡ џ ѣ ѳ ѵѷ]},
			index => ['А', 'Б', 'В', 'Г', 'Д', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'],
			main => qr{[а б в г д её ж з и й к л м н о п р с т у ф х ц ч ш щ ъ ы ь э ю я]},
			punctuation => qr{[\- ‐‑ – , ; \: ! ? . … ’ ” » ( ) \[ \] § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'В', 'Г', 'Д', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:истя|и|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:арась|а|no|n)$' }
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
							'якшамков',
							'даволков',
							'эйзюрков',
							'чадыков',
							'панжиков',
							'аштемков',
							'медьков',
							'умарьков',
							'таштамков',
							'ожоков',
							'сундерьков',
							'ацамков'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'якш',
							'дав',
							'эйз',
							'чад',
							'пан',
							'ашт',
							'мед',
							'ума',
							'таш',
							'ожо',
							'сун',
							'аца'
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
						mon => 'атя',
						tue => 'вас',
						wed => 'кун',
						thu => 'кал',
						fri => 'сюк',
						sat => 'шля',
						sun => 'тар'
					},
					wide => {
						mon => 'атяньчистэ',
						tue => 'вастаньчистэ',
						wed => 'куншкачистэ',
						thu => 'калоньчистэ',
						fri => 'сюконьчистэ',
						sat => 'шлямочистэ',
						sun => 'таргочистэ'
					},
				},
				'stand-alone' => {
					wide => {
						mon => 'атяньчи',
						tue => 'вастаньчи',
						wed => 'куншкачи',
						thu => 'калоньчи',
						fri => 'сюконьчи',
						sat => 'шлямочи',
						sun => 'таргочи'
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
					'am' => q{обедтэ икеле},
					'pm' => q{обедтэ мейле},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{обедтэ икеле},
					'pm' => q{обедтэ мейле},
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
				'0' => 'Христосонь чачомадо икеле',
				'1' => 'Христосонь чачомадо мейле'
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
		'Afghanistan' => {
			long => {
				'standard' => q#Афганистанонь шка#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Аляскань кизэнь шка#,
				'generic' => q#Аляскань шка#,
				'standard' => q#Аляскань свалонь шка#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Амазононь кизэнь шка#,
				'generic' => q#Амазононь шка#,
				'standard' => q#Амазононь свалонь шка#,
			},
		},
		'America/Boise' => {
			exemplarCity => q#Бойси#,
		},
		'America/Chicago' => {
			exemplarCity => q#Шикаго#,
		},
		'America/Denver' => {
			exemplarCity => q#Денвер#,
		},
		'America/Grenada' => {
			exemplarCity => q#Гренада#,
		},
		'America/Panama' => {
			exemplarCity => q#Панама#,
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Лонгйирбюен#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Багдад#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Баку#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Гонконг#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Омской#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Сахалин#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Самарканд#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Сеул#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Шанхай#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Тайпей#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Ташкент#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Токио#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Томской#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Улан-батор#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Бермуда#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Мадейра#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Рейкьявик#,
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Бангладешень кизэнь шка#,
				'generic' => q#Бангладешень шка#,
				'standard' => q#Бангладешень свалонь шка#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Базилиянь кизэнь шка#,
				'generic' => q#Базилиянь шка#,
				'standard' => q#Базилиянь свалонь шка#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Чилинь кизэнь шка#,
				'generic' => q#Чилинь шка#,
				'standard' => q#Чилинь свалонь шка#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Китаень кизэнь шка#,
				'generic' => q#Китаень шка#,
				'standard' => q#Китаень свалонь шка#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Кубань кизэнь шка#,
				'generic' => q#Кубань шка#,
				'standard' => q#Кубань свалонь шка#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Асодавикс Ош#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Амстердам#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Андорра#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Афины#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Белград#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Берлин#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Братислава#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Брюссель#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Бухарест#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Будапешт#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Копенгаген#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Дублин#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Хельсинки#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Киев#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Киров#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Лиссабон#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Любляна#,
		},
		'Europe/London' => {
			exemplarCity => q#Лондон#,
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Люксембург#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Мадрид#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Мальта#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Минской#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Монако#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Москов#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Осло#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Париж#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Подгорица#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Прага#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Рига#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Рим#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Самара#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Сан-Марино#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Сараево#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Саратов#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Симферополь#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Скопье#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#София#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Стокгольм#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Таллин#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Тирана#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ужгород#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Вадуц#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Ватикан#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Вена#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Вильнюс#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Варшава#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Загреб#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Запорожье#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Цюрих#,
		},
		'India' => {
			long => {
				'standard' => q#Индиянь свалонь шка#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Иранонь кизэнь шка#,
				'generic' => q#Иранонь шка#,
				'standard' => q#Иранонь свалонь шка#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Япониянь кизэнь шка#,
				'generic' => q#Япониянь шка#,
				'standard' => q#Япониянь свалонь шка#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Казахстанонь чилисемань шка#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Казахстанонь чивалгомань шка#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Кореань кизэнь шка#,
				'generic' => q#Кореань шка#,
				'standard' => q#Кореань свалонь шка#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Московонь кизэнь шка#,
				'generic' => q#Московонь шка#,
				'standard' => q#Московонь свалонь шка#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Од Зеландиянь кизэнь шка#,
				'generic' => q#Од Зеландиянь шка#,
				'standard' => q#Од Зеландиянь свалонь шка#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Омскоень кизэнь шка#,
				'generic' => q#Омскоень шка#,
				'standard' => q#Омскоень свалонь шка#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Парагваень кизэнь шка#,
				'generic' => q#Парагваень шка#,
				'standard' => q#Парагваень свалонь шка#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Сахалинэнь кизэнь шка#,
				'generic' => q#Сахалинэнь шка#,
				'standard' => q#Сахалинэнь свалонь шка#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Уругваень кизэнь шка#,
				'generic' => q#Уругваень шка#,
				'standard' => q#Уругваень свалонь шка#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Узбекистанонь кизэнь шка#,
				'generic' => q#Узбекистанонь шка#,
				'standard' => q#Узбекистанонь свалонь шка#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
