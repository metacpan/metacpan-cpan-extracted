=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Cv - Package for language Chuvash

=cut

package Locale::CLDR::Locales::Cv;
# This file auto generated from Data\common\main\cv.xml
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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'арап',
 				'ar_001' => 'арап литератури',
 				'bn' => 'бенгал',
 				'cv' => 'чӑваш',
 				'de' => 'нимӗҫ',
 				'de_AT' => 'австрин нимӗҫ',
 				'de_CH' => 'швейцарин нимӗҫ',
 				'en' => 'акӑлчан',
 				'en_AU' => 'австралин акӑлчан',
 				'en_CA' => 'канадӑн акӑлчан',
 				'en_GB' => 'британин акӑлчан',
 				'en_US' => 'америкӑн акӑлчан',
 				'es' => 'испани',
 				'es_419' => 'латинла америкӑн испани',
 				'es_ES' => 'европӑн испани',
 				'es_MX' => 'мексикӑн испани',
 				'fr' => 'франци',
 				'fr_CA' => 'канадӑн франци',
 				'fr_CH' => 'швейцарӗн франци',
 				'hi' => 'хинди',
 				'hi_Latn' => 'хинди чĕлхи (латин)',
 				'hi_Latn@alt=variant' => 'хинди (латин)',
 				'id' => 'индонези',
 				'it' => 'итали',
 				'ja' => 'япони',
 				'ko' => 'корей',
 				'nl' => 'голланди',
 				'nl_BE' => 'фламанди',
 				'pl' => 'поляк',
 				'pt' => 'португали',
 				'pt_BR' => 'бразилин португали',
 				'pt_PT' => 'европӑн португали',
 				'ru' => 'вырӑс',
 				'th' => 'тай',
 				'tr' => 'турккӑ',
 				'und' => 'паллӑ мар чӗлхе',
 				'zh' => 'китай',
 				'zh@alt=menu' => 'ҫурҫӗр китай',
 				'zh_Hans' => 'китай, ҫӑмӑллатнӑ ҫыру',
 				'zh_Hans@alt=long' => 'ҫурҫӗр китай, ҫӑмӑллатнӑ ҫыру',
 				'zh_Hant' => 'китай, традициллӗ ҫыру',
 				'zh_Hant@alt=long' => 'ҫурҫӗр китай, традициллӗ ҫыру',

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
			'Arab' => 'арап',
 			'Cyrl' => 'кириллица',
 			'Hans' => 'ҫӑмӑллатнӑн китай',
 			'Hans@alt=stand-alone' => 'ҫӑмӑллатнӑ китай',
 			'Hant' => 'традициллӗн китай',
 			'Jpan' => 'япони',
 			'Kore' => 'корей',
 			'Latn' => 'латин',
 			'Zxxx' => 'ҫырусӑр',
 			'Zzzz' => 'паллӑ мар ҫырулах',

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
			'001' => 'тӗнче',
 			'002' => 'Африка',
 			'003' => 'Ҫурҫӗр Америка',
 			'005' => 'Кӑнтӑр Америка',
 			'009' => 'Океани',
 			'011' => 'Анӑҫ Африка',
 			'013' => 'Тӗп Америка',
 			'014' => 'Хӗвелтухӑҫ Африка',
 			'015' => 'Ҫурҫӗр Африка',
 			'017' => 'Тӗп Африка',
 			'018' => 'Кӑнтӑр Африка',
 			'019' => 'Америка',
 			'021' => 'Ҫурҫӗр Америка регион',
 			'029' => 'Карибсем',
 			'030' => 'Хӗвелтухӑҫ Ази',
 			'034' => 'Кӑнтӑр Ази',
 			'035' => 'Кӑнтӑр хӗвелтухӑҫ Ази',
 			'039' => 'Кӑнтӑр Европа',
 			'053' => 'Австралази',
 			'054' => 'Меланези',
 			'057' => 'Микронези регион',
 			'061' => 'Полинези',
 			'142' => 'Ази',
 			'143' => 'Тӗп Ази',
 			'145' => 'Анӑҫ Ази',
 			'150' => 'Европа',
 			'151' => 'Хӗвелтухӑҫ Европа',
 			'154' => 'Ҫурҫӗр Европа',
 			'155' => 'Анӑҫ Европа',
 			'202' => 'Тропик Африка',
 			'419' => 'Латинла Америка',
 			'AC' => 'Вознесени утравӗ',
 			'AD' => 'Андорра',
 			'AE' => 'Арапсен Пӗрлешӳллӗ Эмирачӗ',
 			'AF' => 'Афганистан',
 			'AG' => 'Антигуа тата Барбуда',
 			'AI' => 'Ангилья',
 			'AL' => 'Албани',
 			'AM' => 'Армени',
 			'AO' => 'Ангола',
 			'AQ' => 'Антарктида',
 			'AR' => 'Аргентина',
 			'AS' => 'Америка Самоа',
 			'AT' => 'Австри',
 			'AU' => 'Австрали',
 			'AW' => 'Аруба',
 			'AX' => 'Аланди утравӗсем',
 			'AZ' => 'Азербайджан',
 			'BA' => 'Боснипе Герцеговина',
 			'BB' => 'Барбадос',
 			'BD' => 'Бангладеш',
 			'BE' => 'Бельги',
 			'BF' => 'Буркина-Фасо',
 			'BG' => 'Болгари',
 			'BH' => 'Бахрейн',
 			'BI' => 'Бурунди',
 			'BJ' => 'Бенин',
 			'BL' => 'Сен-Бартелеми',
 			'BM' => 'Бермуд утравӗсем',
 			'BN' => 'Бруней-Даруссалам',
 			'BO' => 'Боливи',
 			'BQ' => 'Бонэйр, Синт-Эстатиус тата Саба',
 			'BR' => 'Бразили',
 			'BS' => 'Пахам утравӗсем',
 			'BT' => 'Бутан',
 			'BV' => 'Буве утравӗ',
 			'BW' => 'Ботсвана',
 			'BY' => 'Беларуҫ',
 			'BZ' => 'Белиз',
 			'CA' => 'Канада',
 			'CC' => 'Кокос утравӗсем',
 			'CD' => 'Конго - Киншаса',
 			'CD@alt=variant' => 'Конго (КДР)',
 			'CF' => 'Тӗп Африка Республики',
 			'CG' => 'Конго - Браззавиль',
 			'CG@alt=variant' => 'Конго Республики',
 			'CH' => 'Швейцари',
 			'CI' => 'Кот-д’Ивуар',
 			'CK' => 'Кук утравӗсем',
 			'CL' => 'Чили',
 			'CM' => 'Камерун',
 			'CN' => 'Китай',
 			'CO' => 'Колумби',
 			'CP' => 'Клиппертон утравӗ',
 			'CR' => 'Коста-Рика',
 			'CU' => 'Куба',
 			'CV' => 'Кабо-Верде',
 			'CW' => 'Кюрасао',
 			'CX' => 'Раштав утравӗ',
 			'CY' => 'Кипр',
 			'CZ' => 'Чехи',
 			'CZ@alt=variant' => 'Чех Республики',
 			'DE' => 'Германи',
 			'DG' => 'Диего-Гарсия',
 			'DJ' => 'Джибути',
 			'DK' => 'Дани',
 			'DM' => 'Доминика',
 			'DO' => 'Доминикан Республики',
 			'DZ' => 'Алжир',
 			'EA' => 'Сеута тата Мелилья',
 			'EC' => 'Эквадор',
 			'EE' => 'Эстони',
 			'EG' => 'Египет',
 			'EH' => 'Анӑҫ Сахара',
 			'ER' => 'Эритрей',
 			'ES' => 'Испани',
 			'ET' => 'Эфиопи',
 			'EU' => 'Европа пӗрлешӗвӗ',
 			'EZ' => 'Еврозон',
 			'FI' => 'Финлянди',
 			'FJ' => 'Фиджи',
 			'FK' => 'Фолкленд утравӗсем',
 			'FK@alt=variant' => 'Фолкленд (Мальвински) утравӗсем',
 			'FM' => 'Микронези',
 			'FO' => 'Фарер утравӗсем',
 			'FR' => 'Франци',
 			'GA' => 'Габон',
 			'GB' => 'Аслӑ Британи',
 			'GB@alt=short' => 'Британи',
 			'GD' => 'Гренада',
 			'GE' => 'Грузи',
 			'GF' => 'Франци Гвиана',
 			'GG' => 'Гернси',
 			'GH' => 'Гана',
 			'GI' => 'Гибралтар',
 			'GL' => 'Гренланди',
 			'GM' => 'Гамби',
 			'GN' => 'Гвиней',
 			'GP' => 'Гваделупа',
 			'GQ' => 'Экваториаллӑ Гвиней',
 			'GR' => 'Греци',
 			'GS' => 'Кӑнтӑр Георги тата Сандвичев утравӗсем',
 			'GT' => 'Гватемала',
 			'GU' => 'Гуам',
 			'GW' => 'Гвиней-Бисау',
 			'GY' => 'Гайана',
 			'HK' => 'Гонконг (САР)',
 			'HK@alt=short' => 'Гонконг',
 			'HM' => 'Херд тата Макдональд утравӗ',
 			'HN' => 'Гондурас',
 			'HR' => 'Хорвати',
 			'HT' => 'Гаити',
 			'HU' => 'Венгри',
 			'IC' => 'Канар утравӗсем',
 			'ID' => 'Индонези',
 			'IE' => 'Ирланди',
 			'IL' => 'Израиль',
 			'IM' => 'Мэн утравӗ',
 			'IN' => 'Инди',
 			'IO' => 'Британин территори Инди океанӗре',
 			'IO@alt=biot' => 'Британи территори Инди океанӗре',
 			'IO@alt=chagos' => 'Чагос архипелаге',
 			'IQ' => 'Ирак',
 			'IR' => 'Иран',
 			'IS' => 'Исланди',
 			'IT' => 'Итали',
 			'JE' => 'Джерси',
 			'JM' => 'Ямайка',
 			'JO' => 'Иордани',
 			'JP' => 'Япони',
 			'KE' => 'Кени',
 			'KG' => 'Киргизи',
 			'KH' => 'Камбоджа',
 			'KI' => 'Кирибати',
 			'KM' => 'Комор утравӗсем',
 			'KN' => 'Сент-Китс тата Невис',
 			'KP' => 'КХДР',
 			'KR' => 'Корей Республики',
 			'KW' => 'Кувейт',
 			'KY' => 'Кайман утравӗсем',
 			'KZ' => 'Казахстан',
 			'LA' => 'Лаос',
 			'LB' => 'Ливан',
 			'LC' => 'Сент-Люсия',
 			'LI' => 'Лихтенштейн',
 			'LK' => 'Шри-Ланка',
 			'LR' => 'Либери',
 			'LS' => 'Лесото',
 			'LT' => 'Литва',
 			'LU' => 'Люксембург',
 			'LV' => 'Латви',
 			'LY' => 'Ливи',
 			'MA' => 'Марокко',
 			'MC' => 'Монако',
 			'MD' => 'Молдова',
 			'ME' => 'Черногори',
 			'MF' => 'Сен-Мартен',
 			'MG' => 'Мадагаскар',
 			'MH' => 'Маршаллов утравӗсем',
 			'MK' => 'Ҫурҫӗр Македони',
 			'ML' => 'Мали',
 			'MM' => 'Мьянма (Бирма)',
 			'MN' => 'Монголи',
 			'MO' => 'Макао (САР)',
 			'MO@alt=short' => 'Макао',
 			'MP' => 'Ҫурҫӗр Мариан утравӗсем',
 			'MQ' => 'Мартиника',
 			'MR' => 'Мавритани',
 			'MS' => 'Монтсеррат',
 			'MT' => 'Мальта',
 			'MU' => 'Маврики',
 			'MV' => 'Мальдивсем',
 			'MW' => 'Малави',
 			'MX' => 'Мексика',
 			'MY' => 'Малайзи',
 			'MZ' => 'Мозамбик',
 			'NA' => 'Намиби',
 			'NC' => 'Ҫӗнӗ Каледони',
 			'NE' => 'Нигер',
 			'NF' => 'Норфолк утравӗ',
 			'NG' => 'Нигери',
 			'NI' => 'Никарагуа',
 			'NL' => 'Нидерланд',
 			'NO' => 'Норвеги',
 			'NP' => 'Непал',
 			'NR' => 'Науру',
 			'NU' => 'Ниуэ',
 			'NZ' => 'Ҫӗнӗ Зеланди',
 			'NZ@alt=variant' => 'Аотеароа (Ҫӗнӗ Зеланди)',
 			'OM' => 'Оман',
 			'PA' => 'Панама',
 			'PE' => 'Перу',
 			'PF' => 'Франци Полинези',
 			'PG' => 'Папуа — Ҫӗнӗ Гвиней',
 			'PH' => 'Филиппинсем',
 			'PK' => 'Пакистан',
 			'PL' => 'Польша',
 			'PM' => 'Сен-Пьер & Микелон',
 			'PN' => 'Питкэрн утравӗсем',
 			'PR' => 'Пуэрто-Рико',
 			'PS' => 'Палестинӑн территорийӗсем',
 			'PS@alt=short' => 'Палестина',
 			'PT' => 'Португали',
 			'PW' => 'Палау',
 			'PY' => 'Парагвай',
 			'QA' => 'Катар',
 			'QO' => 'Тулаш Океани',
 			'RE' => 'Реюньон',
 			'RO' => 'Румыни',
 			'RS' => 'Серби',
 			'RU' => 'Раҫҫей',
 			'RW' => 'Руанда',
 			'SA' => 'Сауд Аравийӗ',
 			'SB' => 'Соломон утравӗсем',
 			'SC' => 'Сейшел утравӗсем',
 			'SD' => 'Судан',
 			'SE' => 'Швеци',
 			'SG' => 'Сингапур',
 			'SH' => 'Сӑваплӑ Елена утравӗ',
 			'SI' => 'Словени',
 			'SJ' => 'Шпицберген тата Ян-Майен',
 			'SK' => 'Словаки',
 			'SL' => 'Сьерра-Леоне',
 			'SM' => 'Сан-Марино',
 			'SN' => 'Сенегал',
 			'SO' => 'Сомали',
 			'SR' => 'Суринам',
 			'SS' => 'Кӑнтӑр Судан',
 			'ST' => 'Сан-Томе тата Принсипи',
 			'SV' => 'Сальвадор',
 			'SX' => 'Синт-Мартен',
 			'SY' => 'Сири',
 			'SZ' => 'Эсватини',
 			'SZ@alt=variant' => 'Свазиленд',
 			'TA' => 'Тристан-да-Кунья',
 			'TC' => 'Тёркс тата Кайкос утравӗсем',
 			'TD' => 'Чад',
 			'TF' => 'Франци Кӑнтӑр территорийӗсем',
 			'TG' => 'Того',
 			'TH' => 'Таиланд',
 			'TJ' => 'Таджикистан',
 			'TK' => 'Токелау',
 			'TL' => 'Хӗвелтухӑҫ Тимор',
 			'TL@alt=variant' => 'Тимор-Лесте',
 			'TM' => 'Туркменистан',
 			'TN' => 'Тунис',
 			'TO' => 'Тонга',
 			'TR' => 'Турци',
 			'TT' => 'Тринидад тата Тобаго',
 			'TV' => 'Тувалу',
 			'TW' => 'Тайвань',
 			'TZ' => 'Танзани',
 			'UA' => 'Украина',
 			'UG' => 'Уганда',
 			'UM' => 'Тулашӗнчи утравӗсем (АПШ)',
 			'UN' => 'Пӗрлешӳллӗ Нацисен Организацийӗ',
 			'US' => 'Пӗрлешӗннӗ Штатсем',
 			'US@alt=short' => 'АПШ',
 			'UY' => 'Уругвай',
 			'UZ' => 'Узбекистан',
 			'VA' => 'Ватикан',
 			'VC' => 'Сент-Винсент тата Гренадины',
 			'VE' => 'Венесуэла',
 			'VG' => 'Британин Виргини утравӗсем',
 			'VI' => 'Виргини утравӗсем (АПШ)',
 			'VN' => 'Вьетнам',
 			'VU' => 'Вануату',
 			'WF' => 'Уоллис тата Футуна',
 			'WS' => 'Самоа',
 			'XA' => 'псевдакцентсем',
 			'XB' => 'псевд-Bidi',
 			'XK' => 'Косово',
 			'YE' => 'Йемен',
 			'YT' => 'Майотта',
 			'ZA' => 'Кӑнтӑр Африка Республики',
 			'ZM' => 'Замби',
 			'ZW' => 'Зимбабве',
 			'ZZ' => 'паллӑ мар регион',

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
 				'gregorian' => q{грегориан календарӗ},
 				'iso8601' => q{календарӗ ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{стандартлӑ сортировка},
 			},
 			'numbers' => {
 				'latn' => q{хальхи араб цифрисем},
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
			'metric' => q{Метрикӑлла},
 			'UK' => q{Акӑлчан},
 			'US' => q{Америка},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Чӗлхе: {0}',
 			'script' => 'Ҫырулӑх: {0}',
 			'region' => 'Регион: {0}',

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
			auxiliary => qr{[{а́} {е́} {и́} {о́} {у́} {ы́} {э́} {ю́} {я́}]},
			index => ['АӐ', 'Б', 'В', 'Г', 'Д', 'ЕӖЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Ҫ', 'Т', 'УӲ', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'],
			main => qr{[аӑ б в г д еӗё ж з и й к л м н о п р с ҫ т уӳ ф х ц ч ш щ ъ ы ь э ю я]},
			numbers => qr{[\- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘‚ "“„ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['АӐ', 'Б', 'В', 'Г', 'Д', 'ЕӖЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Ҫ', 'Т', 'УӲ', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'], };
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
					'coordinate' => {
						'east' => q({0} хӗвелтухӑҫ тӑрӑхӗ),
						'north' => q({0} ҫурҫӗр тӑрӑхӗ),
						'south' => q({0} кӑнтӑр тӑрӑхӗ),
						'west' => q({0} анăҫ тӑрӑхӗ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} хӗвелтухӑҫ тӑрӑхӗ),
						'north' => q({0} ҫурҫӗр тӑрӑхӗ),
						'south' => q({0} кӑнтӑр тӑрӑхӗ),
						'west' => q({0} анăҫ тӑрӑхӗ),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(енӗ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(енӗ),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} х. т.),
						'north' => q({0} ҫ. т.),
						'south' => q({0} к. т.),
						'west' => q({0} а. т.),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} х. т.),
						'north' => q({0} ҫ. т.),
						'south' => q({0} к. т.),
						'west' => q({0} а. т.),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} тата {1}),
				2 => q({0} тата {1}),
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
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
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
		'AED' => {
			display_name => {
				'currency' => q(АПЭ дирхамӗ),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(афганийӗ),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Албани лекӗ),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Армяни драмӗ),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Нидерланд Антиллиан гульденӗ),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Ангола кванзӗ),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Аргентина песийӗ),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Австрали долларӗ),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Аруба флоринӗ),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Азербайджан маначӗ),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Боснипе Герцеговина конвертланакан марки),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Барбадос долларӗ),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Бангладеш таки),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Болгари левӗ),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Бахрейн динарӗ),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Бурунди франкӗ),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Бермуд долларӗ),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Бруней долларӗ),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Боливи боливианӗ),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Бразили реалӗ),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Багам долларӗ),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Бутан нгултрумӗ),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Ботсвана пули),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Беларуҫ тенкӗ),
				'other' => q(Беларуҫ тенки),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Белиз долларӗ),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Канада долларӗ),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Конголези франкӗ),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Швейцари франкӗ),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Чили песийӗ),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Китай офшор юанӗ),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Китай юанӗ),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Колумби песийӗ),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Коста-Рика колонӗ),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Куба конвертланакан песийӗ),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Куба песийӗ),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Кабо-Верде эскудӗ),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Чехи кронӗ),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Джибути франкӗ),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Дани кронӗ),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Доминикан песийӗ),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Алжир динарӗ),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Египет фунчӗ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Эритрей накфӗ),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Эфиопи бырӗ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(евро),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Фиджи долларӗ),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Факланд утравӗсен фунчӗ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Британи фунчӗ),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Грузи ларийӗ),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Гана седийӗ),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Гибралтар фунчӗ),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Гамби даласийӗ),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Гвиней франкӗ),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Гватемала кетсалӗ),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Гайана долларӗ),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Гонконг долларӗ),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Гондурас лемпирӗ),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Хорвати куни),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Гаити гурдӗ),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Венгри форинчӗ),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Индонези рупийӗ),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Ҫӗнӗ Израиль шекелӗ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Инди рупийӗ),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Ирак динарӗ),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Иран риалӗ),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Исланди кронӗ),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Ямайка долларӗ),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Иордан динарӗ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Япони иени),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Кени шиллингӗ),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Киргиз сомӗ),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Камбоджа риелӗ),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Комора франкӗ),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(КХДР вони),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Корей вони),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Кувейт динарӗ),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Кайман утравӗсен долларӗ),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Казах тенгейӗ),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Лаос кипӗ),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Ливан фунчӗ),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Шри-ланка рупийӗ),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Либери долларӗ),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Лесото лотийӗ),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Ливи динарӗ),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Марокко дирхамӗ),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Молдова лайӗ),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Малагаси ариарийӗ),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Македони денарӗ),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Мьянман кьятӗ),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Монголи тугрикӗ),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Макао патаки),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Мавритани угийӗ),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Маврики рупийӗ),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Мальдивсен руфийӗ),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Малави квачӗ),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Мексика песийӗ),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Малайзи ринггичӗ),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Мозамбик метикалӗ),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Намиби долларӗ),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Нигери найрӗ),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Никарагуа кордобӗ),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Норвеги кронӗ),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Непал рупийӗ),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Ҫӗнӗ Зеланди долларӗ),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Оман риалӗ),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Панама бальбоа),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Перу солӗ),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Папуа – Ҫӗнӗ Гвиней кини),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Филиппин песийӗ),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(пакистан рупийӗ),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Польша злотыйӗ),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Парагвай гуаранӗ),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Катар риалӗ),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Румыни лейӗ),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Серби динарӗ),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(Раҫҫей тенкӗ),
				'other' => q(Раҫҫей тенки),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Руанда франкӗ),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Сауд риялӗ),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Соломон утравӗсен долларӗ),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Сейшел рупийӗ),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Судан фунчӗ),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Швеци кронӗ),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Сингапур долларӗ),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Сӑваплӑ Елена утравӗн фунчӗ),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(леонӗ),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(леонӗ \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Сомали шиллингӗ),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Суринам долларӗ),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Кӑнтӑр Судан фунчӗ),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Сан-Томе тата Принсипи добрӗ),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Сири фунчӗ),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Свази лилангенийӗ),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Таиланд барӗ),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Таджик сомонийӗ),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Туркмен маначӗ),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Тунези динарӗ),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Тонган паанги),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Турци лири),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Тринидад тата Тобаго долларӗ),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Ҫӗнӗ Тайван долларӗ),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Танзани шиллингӗ),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Украина гривни),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Уганда шиллингӗ),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(АПШ долларӗ),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Уругвай песийӗ),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Узбек сумӗ),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Венесуэла боливарӗ),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Вьетнам донгӗ),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Вануату ватуйӗ),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Самоа тали),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Тӗп Африка КФА франкӗ),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Хӗвелтухӑҫ Карибсем долларӗ),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(КФА ВСЕАО франкӗ),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Франци Лӑпкӑ океан франкӗ),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(паллӑ мар валюта),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Йемен риалӗ),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Кӑнтӑр Африка рэндӗ),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Замби квачи),
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
							'кӑр.',
							'нар.',
							'пуш',
							'ака',
							'ҫу',
							'ҫӗр.',
							'утӑ',
							'ҫур.',
							'авӑн',
							'юпа',
							'чӳк',
							'раш.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'кӑрлач',
							'нарӑс',
							'пуш',
							'ака',
							'ҫу',
							'ҫӗртме',
							'утӑ',
							'ҫурла',
							'авӑн',
							'юпа',
							'чӳк',
							'раштав'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'К',
							'Н',
							'П',
							'А',
							'Ҫ',
							'Ҫ',
							'У',
							'Ҫ',
							'А',
							'Ю',
							'Ч',
							'Р'
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
						mon => 'тун.',
						tue => 'ытл.',
						wed => 'юн.',
						thu => 'кӗҫ.',
						fri => 'эр.',
						sat => 'шӑм.',
						sun => 'выр.'
					},
					wide => {
						mon => 'тунтикун',
						tue => 'ытларикун',
						wed => 'юнкун',
						thu => 'кӗҫнерникун',
						fri => 'эрнекун',
						sat => 'шӑматкун',
						sun => 'вырсарникун'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'Т',
						tue => 'Ы',
						wed => 'Ю',
						thu => 'К',
						fri => 'Э',
						sat => 'Ш',
						sun => 'В'
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
					abbreviated => {0 => '1-мӗш кв.',
						1 => '2-мӗш кв.',
						2 => '3-мӗш кв.',
						3 => '4-мӗш кв.'
					},
					wide => {0 => '1-мӗш квартал',
						1 => '2-мӗш квартал',
						2 => '3-мӗш квартал',
						3 => '4-мӗш квартал'
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
				'0' => 'п. э.',
				'1' => 'х. э.'
			},
			wide => {
				'0' => 'Христос ҫуралнӑ кунччен',
				'1' => 'Христос ҫуралнӑ кунран'
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
			'full' => q{EEEE, d MMMM y 'ҫ'. G},
			'long' => q{d MMMM y 'ҫ'. G},
			'medium' => q{d MMM y 'ҫ'. G},
			'short' => q{dd.MM.y G},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y 'ҫ'.},
			'long' => q{d MMMM y 'ҫ'.},
			'medium' => q{d MMM y 'ҫ'.},
			'short' => q{dd.MM.y},
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
			EHm => q{ccc HH:mm},
			EHms => q{ccc HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{ccc, h:mm a},
			Ehms => q{ccc, h:mm:ss a},
			Gy => q{y 'ҫ'. G},
			GyMMM => q{LLL y 'ҫ'. G},
			GyMMMEd => q{E, d MMM y 'ҫ'. G},
			GyMMMd => q{d MMM y 'ҫ'. G},
			GyMd => q{dd.MM.y G},
			MEd => q{E, dd.MM},
			MMMEd => q{ccc, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			y => q{y 'ҫ'. G},
			yyyy => q{y 'ҫ'. G},
			yyyyM => q{MM.y G},
			yyyyMEd => q{E, dd.MM.y G},
			yyyyMMM => q{LLL y 'ҫ'. G},
			yyyyMMMEd => q{E, d MMM y 'ҫ'. G},
			yyyyMMMM => q{LLLL y 'ҫ'. G},
			yyyyMMMd => q{d MMM y 'ҫ'. G},
			yyyyMd => q{dd.MM.y G},
			yyyyQQQ => q{QQQ y 'ҫ'. G},
			yyyyQQQQ => q{QQQQ y 'ҫ'. G},
		},
		'gregorian' => {
			EBhm => q{ccc, h:mm B},
			EBhms => q{ccc, h:mm:ss B},
			Ed => q{ccc, d},
			Ehms => q{E h:mm:ss a},
			Gy => q{y 'ҫ'. G},
			GyMMM => q{LLL y 'ҫ'. G},
			GyMMMEd => q{E, d MMM y 'ҫ'. G},
			GyMMMd => q{d MMM y 'ҫ'. G},
			GyMd => q{dd.MM.y GGGGG},
			MEd => q{E, dd.MM},
			MMMEd => q{ccc, d MMM},
			MMMMW => q{MMMM W-'мӗш' 'эрни'},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			yM => q{MM.y},
			yMEd => q{ccc, dd.MM.y 'ҫ'.},
			yMMM => q{LLL y 'ҫ'.},
			yMMMEd => q{E, d MMM y 'ҫ'.},
			yMMMM => q{LLLL y 'ҫ'.},
			yMMMd => q{d MMM y 'ҫ'.},
			yMd => q{dd.MM.y},
			yQQQ => q{QQQ y 'ҫ'.},
			yQQQQ => q{QQQQ y 'ҫ'.},
			yw => q{w-'мӗш' 'эрни' Y 'ҫ'.},
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
			Gy => {
				G => q{y 'ҫ'. G – y 'ҫ'. G},
				y => q{y–y 'ҫҫ'. G},
			},
			GyM => {
				G => q{MM.y G – MM.y G},
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			GyMEd => {
				G => q{ccc, dd.MM.y G – ccc, dd.MM.y G},
				M => q{ccc, dd.MM.y – ccc, dd.MM.y G},
				d => q{ccc, dd.MM.y – ccc, dd.MM.y G},
				y => q{ccc, dd.MM.y – ccc, dd.MM.y G},
			},
			GyMMM => {
				G => q{LLL y 'ҫ'. G – LLL y 'ҫ'. G},
				M => q{LLL – LLL y 'ҫ'. G},
				y => q{LLL y – LLL y 'ҫҫ'. G},
			},
			GyMMMEd => {
				G => q{ccc, d MMM y 'ҫ'. G – ccc, d MMM y 'ҫ'. G},
				M => q{ccc, d MMM – ccc, d MMM y 'ҫ'. G},
				d => q{ccc, d MMM – ccc, d MMM y 'ҫ'. G},
				y => q{ccc, d MMM y – ccc, d MMM y 'ҫҫ'. G},
			},
			GyMMMd => {
				G => q{d MMM y 'ҫ'. G – d MMM y 'ҫ'. G},
				M => q{d MMM – d MMM y 'ҫ'. G},
				d => q{d–d MMM y 'ҫ'. G},
				y => q{d MMM y – d MMM y 'ҫҫ'. G},
			},
			GyMd => {
				G => q{dd.MM.y G – dd.MM.y G},
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMMEd => {
				M => q{ccc, d MMM – ccc, d MMM},
				d => q{ccc, d MMM – ccc, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			y => {
				y => q{y–y 'ҫҫ'. G},
			},
			yM => {
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			yMEd => {
				M => q{ccc, dd.MM.y – ccc, dd.MM.y G},
				d => q{ccc, dd.MM.y – ccc, dd.MM.y G},
				y => q{ccc, dd.MM.y – ccc, dd.MM.y G},
			},
			yMMM => {
				M => q{LLL – LLL y 'ҫ'. G},
				y => q{LLL y 'ҫ'. – LLL y 'ҫ'. G},
			},
			yMMMEd => {
				M => q{ccc, d MMM – ccc, d MMM y 'ҫ'. G},
				d => q{ccc, d MMM – ccc, d MMM y 'ҫ'. G},
				y => q{ccc, d MMM y 'ҫ'. – ccc, d MMM y 'ҫ'. G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y 'ҫ'. G},
				y => q{LLLL y 'ҫ'. – LLLL y 'ҫ'. G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y 'ҫ'. G},
				d => q{d–d MMM y 'ҫ'. G},
				y => q{d MMM y 'ҫ'. – d MMM y 'ҫ'. G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y 'ҫ'. G – y 'ҫ'. G},
				y => q{y–y 'ҫҫ'. G},
			},
			GyM => {
				G => q{MM.y G – MM.y G},
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			GyMEd => {
				G => q{ccc, dd.MM.y G – ccc, dd.MM.y G},
				M => q{ccc, dd.MM.y – ccc, dd.MM.y G},
				d => q{ccc, dd.MM.y – ccc, dd.MM.y G},
				y => q{ccc, dd.MM.y – ccc, dd.MM.y G},
			},
			GyMMM => {
				G => q{LLL y 'ҫ'. G – LLL y 'ҫ'. G},
				M => q{LLL – LLL y 'ҫ'. G},
				y => q{LLL y – LLL y 'ҫҫ'. G},
			},
			GyMMMEd => {
				G => q{ccc, d MMM y 'ҫ'. G – ccc, d MMM y 'ҫ'. G},
				M => q{ccc, d MMM – ccc, d MMM y 'ҫ'. G},
				d => q{ccc, d MMM – ccc, d MMM y 'ҫ'. G},
				y => q{ccc, d MMM y – ccc, d MMM y 'ҫҫ'. G},
			},
			GyMMMd => {
				G => q{d MMM y 'ҫ'. G – d MMM y 'ҫ'. G},
				M => q{d MMM – d MMM y 'ҫ'. G},
				d => q{d–d MMM y 'ҫ'. G},
				y => q{d MMM y – d MMM y 'ҫҫ'. G},
			},
			GyMd => {
				G => q{dd.MM.y G – dd.MM.y G},
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{ccc, dd.MM.y – ccc, dd.MM.y},
				d => q{ccc, dd.MM.y – ccc, dd.MM.y},
				y => q{ccc, dd.MM.y – ccc, dd.MM.y},
			},
			yMMM => {
				M => q{LLL – LLL y 'ҫ'.},
				y => q{LLL y 'ҫ'. – LLL y 'ҫ'.},
			},
			yMMMEd => {
				M => q{ccc, d MMM – ccc, d MMM y 'ҫ'.},
				d => q{ccc, d – ccc, d MMM y 'ҫ'.},
				y => q{ccc, d MMM y 'ҫ'. – ccc, d MMM y 'ҫ'.},
			},
			yMMMM => {
				M => q{LLLL – LLLL y 'ҫ'.},
				y => q{LLLL y 'ҫ'. – LLLL y 'ҫ'.},
			},
			yMMMd => {
				M => q{d MMM – d MMM y 'ҫ'.},
				d => q{d–d MMM y 'ҫ'.},
				y => q{d MMM y 'ҫ'. – d MMM y 'ҫ'.},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} ҫуллахи вӑхӑчӗ),
		regionFormat => q({0} стандартлӑ вӑхӑчӗ),
		'Afghanistan' => {
			long => {
				'standard' => q#Афганистан вӑхӑчӗ#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Абиджан#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Аккра#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Аддис-Абеба#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Алжир#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Асмэра#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Бамако#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Банги#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Банжул#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Бисау#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Блантайр#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Браззавиль#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Бужумбура#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Каир#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Касабланка#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Сеута#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Конакри#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Дакар#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Дар-эс-Салам#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Джибути#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Дуала#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Эль-Аюн#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Фритаун#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Габороне#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Хараре#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Йоханнесбург#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Джуба#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Кампала#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Хартум#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Кигали#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Киншаса#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Лагос#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Либревиль#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Ломе#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Луанда#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Лубумбаши#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Лусака#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Малабо#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Мапуту#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Масеру#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Мбабане#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Могадишо#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Монрови#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Найроби#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Нджамена#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Ниамей#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Нуакшот#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Уагадугу#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Порто-Ново#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Сан-Томе Сан-Томе#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Триполи#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Тунис#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Виндхук#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Тӗп Африка вӑхӑчӗ#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Хӗвелтухӑҫ Африка вӑхӑчӗ#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Кӑнтӑр Африка вӑхӑчӗ#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Анӑҫ Африка ҫуллахи вӑхӑчӗ#,
				'generic' => q#Анӑҫ Африка вӑхӑчӗ#,
				'standard' => q#Анӑҫ Африка стандартлӑ вӑхӑчӗ#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Аляска ҫуллахи вӑхӑчӗ#,
				'generic' => q#Аляска вӑхӑчӗ#,
				'standard' => q#Аляска стандартлӑ вӑхӑчӗ#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Амазонка ҫуллахи вӑхӑчӗ#,
				'generic' => q#Амазонка вӑхӑчӗ#,
				'standard' => q#Амазонка стандартлӑ вӑхӑчӗ#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Адак#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Анкоридж#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Ангилья#,
		},
		'America/Antigua' => {
			exemplarCity => q#Антигуа#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Арагуаина#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Ла-Риоха#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Рио-Гальегос#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Сальта#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#Сан-Хуан#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Сан-Луис Сан-Луис#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Тукуман#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ушуая#,
		},
		'America/Aruba' => {
			exemplarCity => q#Аруба#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Асунсьон#,
		},
		'America/Bahia' => {
			exemplarCity => q#Баия#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Баия-де-Бандерас#,
		},
		'America/Barbados' => {
			exemplarCity => q#Барбадос#,
		},
		'America/Belem' => {
			exemplarCity => q#Белен#,
		},
		'America/Belize' => {
			exemplarCity => q#Белиз#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Бланк-Саблон#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Боа-Виста#,
		},
		'America/Bogota' => {
			exemplarCity => q#Богота#,
		},
		'America/Boise' => {
			exemplarCity => q#Бойсе#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Буэнос-Айрес#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Кеймбридж-Бей#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Кампу-Гранди#,
		},
		'America/Cancun' => {
			exemplarCity => q#Канкун#,
		},
		'America/Caracas' => {
			exemplarCity => q#Каракас#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Катамарка#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Кайенна#,
		},
		'America/Cayman' => {
			exemplarCity => q#Кайман утравӗсем#,
		},
		'America/Chicago' => {
			exemplarCity => q#Чикаго#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Чиуауа#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Корал-Харбор#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Кордова#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Коста-Рика#,
		},
		'America/Creston' => {
			exemplarCity => q#Крестон#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Куяба#,
		},
		'America/Curacao' => {
			exemplarCity => q#Кюрасао#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Денмарксхавн#,
		},
		'America/Dawson' => {
			exemplarCity => q#Доусон#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Доусон-Крик#,
		},
		'America/Denver' => {
			exemplarCity => q#Денвер#,
		},
		'America/Detroit' => {
			exemplarCity => q#Детройт#,
		},
		'America/Dominica' => {
			exemplarCity => q#Доминика#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Эдмонтон#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Эйрунепе#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Сальвадор#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Форт Нельсон#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Форталеза#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Глейс-Бей#,
		},
		'America/Godthab' => {
			exemplarCity => q#Нуук#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Гус-Бей#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Гранд-Терк#,
		},
		'America/Grenada' => {
			exemplarCity => q#Гренада#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Гваделупа#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Гватемала#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Гуаякиль#,
		},
		'America/Guyana' => {
			exemplarCity => q#Гайана#,
		},
		'America/Halifax' => {
			exemplarCity => q#Галифакс#,
		},
		'America/Havana' => {
			exemplarCity => q#Гавана#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Эрмосильо#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Нокс, Индиана#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Маренго, Индиана#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Питерсберг, Индиана#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Телл-Сити, Индиана#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Вевей, Индиана#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Винсеннес, Индиана#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Уинамак, Индиана#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Индианаполис#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Инувик#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Икалуит#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Ямайка#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Жужуй#,
		},
		'America/Juneau' => {
			exemplarCity => q#Джуно#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Монтиселло, Кентукки#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Кралендейк#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Ла-Пас#,
		},
		'America/Lima' => {
			exemplarCity => q#Лима#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Лос-Анджелес#,
		},
		'America/Louisville' => {
			exemplarCity => q#Луисвилл#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Лоуэр-Принс-Куотер#,
		},
		'America/Maceio' => {
			exemplarCity => q#Масейо#,
		},
		'America/Managua' => {
			exemplarCity => q#Манагуа#,
		},
		'America/Manaus' => {
			exemplarCity => q#Манаус#,
		},
		'America/Marigot' => {
			exemplarCity => q#Мариго#,
		},
		'America/Martinique' => {
			exemplarCity => q#Мартиника#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Матаморос#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Масатлан#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Мендоса#,
		},
		'America/Menominee' => {
			exemplarCity => q#Меномини#,
		},
		'America/Merida' => {
			exemplarCity => q#Мерида#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Метлакатла#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Мехико#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Микелон#,
		},
		'America/Moncton' => {
			exemplarCity => q#Монктон#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Монтеррей#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Монтевидео#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Монтсеррат#,
		},
		'America/Nassau' => {
			exemplarCity => q#Нассау#,
		},
		'America/New_York' => {
			exemplarCity => q#Нью-Йорк#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Нипигон#,
		},
		'America/Nome' => {
			exemplarCity => q#Ном#,
		},
		'America/Noronha' => {
			exemplarCity => q#Норонья#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Бойла, Ҫурҫӗр Дакота#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Центр, Ҫурҫӗр Дакота#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Нью-Сейлем, Ҫурҫӗр Дакота#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Охинага#,
		},
		'America/Panama' => {
			exemplarCity => q#Панама#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Пангниртанг#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Парамарибо#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Финикс#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Порт-о-Пренс#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Порт-оф-Спейн#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Порту-Велью#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Пуэрто-Рико#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Пунта-Аренас#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Рейни-Ривер#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Ранкин-Инлет#,
		},
		'America/Recife' => {
			exemplarCity => q#Ресифи#,
		},
		'America/Regina' => {
			exemplarCity => q#Реджайна#,
		},
		'America/Resolute' => {
			exemplarCity => q#Резольют#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Риу-Бранку#,
		},
		'America/Santarem' => {
			exemplarCity => q#Сантарен#,
		},
		'America/Santiago' => {
			exemplarCity => q#Сантьяго#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Санто-Доминго#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Сан-Паулу Сан-Паулу#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Скорсбисунн#,
		},
		'America/Sitka' => {
			exemplarCity => q#Ситка#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Сен-Бартелеми#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Сент-Джонс#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Сент-Китс#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Сент-Люсия#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Сент-Томас#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Сент-Винсент#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Свифт-Керрент#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Тегусигальпа#,
		},
		'America/Thule' => {
			exemplarCity => q#Туле#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Тандер-Бей#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Тихуана#,
		},
		'America/Toronto' => {
			exemplarCity => q#Торонто#,
		},
		'America/Tortola' => {
			exemplarCity => q#Тортола#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Ванкувер#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Уайтхорс#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Виннипег#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Якутат#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Йеллоунайф#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Тӗп Америка ҫуллахи вӑхӑчӗ#,
				'generic' => q#Тӗп Америка вӑхӑчӗ#,
				'standard' => q#Тӗп Америка стандартлӑ вӑхӑчӗ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Хӗвелтухӑҫ Америка ҫуллахи вӑхӑчӗ#,
				'generic' => q#Хӗвелтухӑҫ Америка вӑхӑчӗ#,
				'standard' => q#Хӗвелтухӑҫ Америка стандартлӑ вӑхӑчӗ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ҫуллахи ту вӑхӑчӗ (Ҫурҫӗр Америка)#,
				'generic' => q#Ту вӑхӑчӗ (Ҫурҫӗр Америка)#,
				'standard' => q#Стандартлӑ ту вӑхӑчӗ (Ҫурҫӗр Америка)#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Лӑпкӑ океан ҫуллахи вӑхӑчӗ#,
				'generic' => q#Лӑпкӑ океан вӑхӑчӗ#,
				'standard' => q#Лӑпкӑ океан стандартлӑ вӑхӑчӗ#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Кейси#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Дейвис#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Дюмон-д’Юрвиль Дюмон-д’Юрвиль#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Маккуори#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Моусон#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Мак-Мердо#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Палмер#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Ротера#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Сёва#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Тролль#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Восток#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Апиа ҫуллахи вӑхӑчӗ#,
				'generic' => q#Апиа вӑхӑчӗ#,
				'standard' => q#Апиа стандартлӑ вӑхӑчӗ#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Арап ҫуллахи вӑхӑчӗ#,
				'generic' => q#Арап вӑхӑчӗ#,
				'standard' => q#Арап стандартлӑ вӑхӑчӗ#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Лонгйир#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Аргентина ҫуллахи вӑхӑчӗ#,
				'generic' => q#Аргентина вӑхӑчӗ#,
				'standard' => q#Аргентина стандартлӑ вӑхӑчӗ#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Анӑҫ Аргентина ҫуллахи вӑхӑчӗ#,
				'generic' => q#Анӑҫ Аргентина вӑхӑчӗ#,
				'standard' => q#Анӑҫ Аргентина стандартлӑ вӑхӑчӗ#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Армени ҫуллахи вӑхӑчӗ#,
				'generic' => q#Армени вӑхӑчӗ#,
				'standard' => q#Армени стандартлӑ вӑхӑчӗ#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Аден#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Алматы#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Амман#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Анадырь#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Актау#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Актобе#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ашхабад#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Атырау#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Багдад#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Бахрейн#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Баку#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Бангкок#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Барнаул#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Бейрут#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Бишкек#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Бруней#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Калькутта#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Чита#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Чойбалсан#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Коломбо#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Дамаск#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Дакка#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Дили#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Дубай#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Душанбе#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Фамагуста#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Газа#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Хеврон#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Гонконг#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Ховд#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Иркутск#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Джакарта#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Джаяпура#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Иерусалим#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Кабул#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Петропавловск-Камчатски#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Карачи#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Катманду#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Хандыга#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Красноярск#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Куала-Лумпур#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Кучинг#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Кувейт#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Макао#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Магадан#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Макасар#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Манила#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Маскат#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Никоси#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Новокузнецк#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Новосибирск#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Омск#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Уральск#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Пномпень#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Понтианак#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Пхеньян#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Катар#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Костанай#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Кызылорда#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Янгон#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Эр-Рияд#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Хошимин#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Сахалин утравӗ#,
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
		'Asia/Singapore' => {
			exemplarCity => q#Сингапур#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Среднеколымск#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Тайбэй#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Ташкент#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Тбилиси#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Тегеран#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Тхимпху#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Токио#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Томск#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Улан-Батор#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Урумчи#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Усть-Нера#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Вьентьян#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Владивосток#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Якутск#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Екатеринбург#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ереван#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Атлантика ҫуллахи вӑхӑчӗ#,
				'generic' => q#Атлантика вӑхӑчӗ#,
				'standard' => q#Атлантика стандартлӑ вӑхӑчӗ#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Азор утравӗсем#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Бермуд утравӗсем#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Канар утравӗсем#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Кабо-Верде#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Фарер утравӗсем#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Мадейра#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Рейкьявик#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Кӑнтӑр Георги#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Сӑваплӑ Елена утравӗ#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Стэнли#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Аделаида#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Брисбен#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Брокен-Хилл#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Дарвин#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Юкла#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Хобарт#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Линдеман#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Лорд-Хау#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Мельбурн#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Перт#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Сидней#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Тӗп Австрали ҫуллахи вӑхӑчӗ#,
				'generic' => q#Тӗп Австрали вӑхӑчӗ#,
				'standard' => q#Тӗп Австрали стандартлӑ вӑхӑчӗ#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Тӗп Австрали анӑҫ ҫуллахи вӑхӑчӗ#,
				'generic' => q#Тӗп Австрали анӑҫ вӑхӑчӗ#,
				'standard' => q#Тӗп Австрали анӑҫ стандартлӑ вӑхӑчӗ#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Хӗвелтухӑҫ Австрали ҫуллахи вӑхӑчӗ#,
				'generic' => q#Хӗвелтухӑҫ Австрали вӑхӑчӗ#,
				'standard' => q#Хӗвелтухӑҫ Австрали стандартлӑ вӑхӑчӗ#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Анӑҫ Австрали ҫуллахи вӑхӑчӗ#,
				'generic' => q#Анӑҫ Австрали вӑхӑчӗ#,
				'standard' => q#Анӑҫ Австрали стандартлӑ вӑхӑчӗ#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Азербайджан ҫуллахи вӑхӑчӗ#,
				'generic' => q#Азербайджан вӑхӑчӗ#,
				'standard' => q#Азербайджан стандартлӑ вӑхӑчӗ#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Азор утравӗсен ҫуллахи вӑхӑчӗ#,
				'generic' => q#Азор утравӗсен вӑхӑчӗ#,
				'standard' => q#Азор утравӗсен стандартлӑ вӑхӑчӗ#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Бангладеш ҫуллахи вӑхӑчӗ#,
				'generic' => q#Бангладеш вӑхӑчӗ#,
				'standard' => q#Бангладеш стандартлӑ вӑхӑчӗ#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Бутан вӑхӑчӗ#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Боливи вӑхӑчӗ#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Бразили ҫуллахи вӑхӑчӗ#,
				'generic' => q#Бразили вӑхӑчӗ#,
				'standard' => q#Бразили стандартлӑ вӑхӑчӗ#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Бруней-Даруссалам вӑхӑчӗ#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Кабо-Верде ҫуллахи вӑхӑчӗ#,
				'generic' => q#Кабо-Верде вӑхӑчӗ#,
				'standard' => q#Кабо-Верде стандартлӑ вӑхӑчӗ#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Чаморро вӑхӑчӗ#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Чатем ҫуллахи вӑхӑчӗ#,
				'generic' => q#Чатем вӑхӑчӗ#,
				'standard' => q#Чатем стандартлӑ вӑхӑчӗ#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Чили ҫуллахи вӑхӑчӗ#,
				'generic' => q#Чили вӑхӑчӗ#,
				'standard' => q#Чили стандартлӑ вӑхӑчӗ#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Китай ҫуллахи вӑхӑчӗ#,
				'generic' => q#Китай вӑхӑчӗ#,
				'standard' => q#Китай стандартлӑ вӑхӑчӗ#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Чойбалсан ҫуллахи вӑхӑчӗ#,
				'generic' => q#Чойбалсан вӑхӑчӗ#,
				'standard' => q#Чойбалсан стандартлӑ вӑхӑчӗ#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Раштав утравӗн вӑхӑчӗ#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Кокос утравӗсен вӑхӑчӗ#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Колумби ҫуллахи вӑхӑчӗ#,
				'generic' => q#Колумби вӑхӑчӗ#,
				'standard' => q#Колумби стандартлӑ вӑхӑчӗ#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Кукӑн утравӗсен ҫуллахи вӑхӑчӗ#,
				'generic' => q#Кукӑн утравӗсен вӑхӑчӗ#,
				'standard' => q#Кукӑн утравӗсен стандартлӑ вӑхӑчӗ#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Куба ҫуллахи вӑхӑчӗ#,
				'generic' => q#Куба вӑхӑчӗ#,
				'standard' => q#Куба стандартлӑ вӑхӑчӗ#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Дейвис вӑхӑчӗ#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Дюмон-д’Юрвиль вӑхӑчӗ#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Хӗвелтухӑҫ Тимор вӑхӑчӗ#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Мӑнкун утравӗн ҫуллахи вӑхӑчӗ#,
				'generic' => q#Мӑнкун утравӗн вӑхӑчӗ#,
				'standard' => q#Мӑнкун утравӗн стандартлӑ вӑхӑчӗ#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Эквадор вӑхӑчӗ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Пӗтӗм тӗнчери координацилене вӑхӑчӗ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Паллӑ мар хула#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Амстердам#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Андорра#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Астрахань#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Афинсем#,
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
		'Europe/Busingen' => {
			exemplarCity => q#Бюзинген#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Кишинев#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Копенгаген#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Дублин#,
			long => {
				'daylight' => q#Ирланди стандартлӑ вӑхӑчӗ#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Гибралтар#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Гернси#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Хельсинки#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Мэн утравӗ#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Стамбул#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Джерси#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Калининград#,
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
			long => {
				'daylight' => q#Британи ҫуллахи вӑхӑчӗ#,
			},
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
		'Europe/Mariehamn' => {
			exemplarCity => q#Мариехамн#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Минск#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Монако#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Мускав#,
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
			exemplarCity => q#Софи#,
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
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ульяновск#,
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
		'Europe/Volgograd' => {
			exemplarCity => q#Волгоград#,
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
		'Europe_Central' => {
			long => {
				'daylight' => q#Тӗп Европа ҫуллахи вӑхӑчӗ#,
				'generic' => q#Тӗп Европа вӑхӑчӗ#,
				'standard' => q#Тӗп Европа стандартлӑ вӑхӑчӗ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Хӗвелтухӑҫ Европа ҫуллахи вӑхӑчӗ#,
				'generic' => q#Хӗвелтухӑҫ Европа вӑхӑчӗ#,
				'standard' => q#Хӗвелтухӑҫ Европа стандартлӑ вӑхӑчӗ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Инҫет-хӗвелтухӑҫ Европа вӑхӑчӗ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Анӑҫ Европа ҫуллахи вӑхӑчӗ#,
				'generic' => q#Анӑҫ Европа вӑхӑчӗ#,
				'standard' => q#Анӑҫ Европа стандартлӑ вӑхӑчӗ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Фолкленд утравӗсен ҫуллахи вӑхӑчӗ#,
				'generic' => q#Фолкленд утравӗсен вӑхӑчӗ#,
				'standard' => q#Фолкленд утравӗсен стандартлӑ вӑхӑчӗ#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Фиджи ҫуллахи вӑхӑчӗ#,
				'generic' => q#Фиджи вӑхӑчӗ#,
				'standard' => q#Фиджи стандартлӑ вӑхӑчӗ#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Франци Гвиана вӑхӑчӗ#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Франци Кӑнтӑрпа Антарктика территорийӗсен вӑхӑчӗ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Гринвичпа вӑтам вӑхӑчӗ#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Галапагос утравӗсен вӑхӑчӗ#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Гамбье вӑхӑчӗ#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Грузи ҫуллахи вӑхӑчӗ#,
				'generic' => q#Грузи вӑхӑчӗ#,
				'standard' => q#Грузи стандартлӑ вӑхӑчӗ#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Гилбертӑн утравӗсен вӑхӑчӗ#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Хӗвелтухӑҫ Гринланди ҫуллахи вӑхӑчӗ#,
				'generic' => q#Хӗвелтухӑҫ Гринланди вӑхӑчӗ#,
				'standard' => q#Хӗвелтухӑҫ Гринланди стандартлӑ вӑхӑчӗ#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Анӑҫ ҫуллахи вӑхӑчӗ#,
				'generic' => q#Анӑҫ Гринланди вӑхӑчӗ#,
				'standard' => q#Анӑҫ Гринланди стандартлӑ вӑхӑчӗ#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Перси залив вӑхӑчӗ#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Гайана вӑхӑчӗ#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Гавайи Алеут ҫуллахи вӑхӑчӗ#,
				'generic' => q#Гавайи Алеут вӑхӑчӗ#,
				'standard' => q#Гавайи Алеут стандартлӑ вӑхӑчӗ#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Гонконг ҫуллахи вӑхӑчӗ#,
				'generic' => q#Гонконг вӑхӑчӗ#,
				'standard' => q#Гонконг стандартлӑ вӑхӑчӗ#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ховд ҫуллахи вӑхӑчӗ#,
				'generic' => q#Ховд вӑхӑчӗ#,
				'standard' => q#Ховд стандартлӑ вӑхӑчӗ#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Инди вӑхӑчӗ#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Антананариву#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Чагос#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Раштав утравӗ#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Кокос утравӗсем#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Коморсем#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Кергелен#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Маэ#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Мальдивсем#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Маврикий#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Майотта#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Реюньон#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Инди океанӗ вӑхӑчӗ#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Индокитай вӑхӑчӗ#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Тӗп Индонези вӑхӑчӗ#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Хӗвелтухӑҫ Индонези вӑхӑчӗ#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Анӑҫ Индонези вӑхӑчӗ#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Иран ҫуллахи вӑхӑчӗ#,
				'generic' => q#Иран вӑхӑчӗ#,
				'standard' => q#Иран стандартлӑ вӑхӑчӗ#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Иркутск ҫуллахи вӑхӑчӗ#,
				'generic' => q#Иркутск вӑхӑчӗ#,
				'standard' => q#Иркутск стандартлӑ вӑхӑчӗ#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Израиль ҫуллахи вӑхӑчӗ#,
				'generic' => q#Израиль вӑхӑчӗ#,
				'standard' => q#Израиль стандартлӑ вӑхӑчӗ#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Япони ҫуллахи вӑхӑчӗ#,
				'generic' => q#Япони вӑхӑчӗ#,
				'standard' => q#Япони стандартлӑ вӑхӑчӗ#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Хӗвелтухӑҫ Казахстан вӑхӑчӗ#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Анӑҫ Казахстан вӑхӑчӗ#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Корей ҫуллахи вӑхӑчӗ#,
				'generic' => q#Корей вӑхӑчӗ#,
				'standard' => q#Корей стандартлӑ вӑхӑчӗ#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Косрае вӑхӑчӗ#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Красноярск ҫуллахи вӑхӑчӗ#,
				'generic' => q#Красноярск вӑхӑчӗ#,
				'standard' => q#Красноярск стандартлӑ вӑхӑчӗ#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Киргизи вӑхӑчӗ#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Лайн утравӗсен вӑхӑчӗ#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Лорд-Хау ҫуллахи вӑхӑчӗ#,
				'generic' => q#Лорд-Хау вӑхӑчӗ#,
				'standard' => q#Лорд-Хау стандартлӑ вӑхӑчӗ#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Маккуори вӑхӑчӗ#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Магадан ҫуллахи вӑхӑчӗ#,
				'generic' => q#Магадан вӑхӑчӗ#,
				'standard' => q#Магадан стандартлӑ вӑхӑчӗ#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Малайзи вӑхӑчӗ#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Мальдивсем вӑхӑчӗ#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Маркизас утравӗсен вӑхӑчӗ#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Маршалл утравӗсен вӑхӑчӗ#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Маврикий ҫуллахи вӑхӑчӗ#,
				'generic' => q#Маврикий вӑхӑчӗ#,
				'standard' => q#Маврикий стандартлӑ вӑхӑчӗ#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Моусон вӑхӑчӗ#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Ҫурҫӗр-анӑҫ Мексика ҫуллахи вӑхӑчӗ#,
				'generic' => q#Ҫурҫӗр-анӑҫ Мексика вӑхӑчӗ#,
				'standard' => q#Ҫурҫӗр-анӑҫ Мексика стандартлӑ вӑхӑчӗ#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Мексика Лӑпкӑ океан ҫуллахи вӑхӑчӗ#,
				'generic' => q#Мексика Лӑпкӑ океан вӑхӑчӗ#,
				'standard' => q#Мексика Лӑпкӑ океан стандартлӑ вӑхӑчӗ#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Улан-Батор ҫуллахи вӑхӑчӗ#,
				'generic' => q#Улан-Батор вӑхӑчӗ#,
				'standard' => q#Улан-Батор стандартлӑ вӑхӑчӗ#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Мускав ҫуллахи вӑхӑчӗ#,
				'generic' => q#Мускав вӑхӑчӗ#,
				'standard' => q#Мускав стандартлӑ вӑхӑчӗ#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Мьянма вӑхӑчӗ#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Науру вӑхӑчӗ#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Непал вӑхӑчӗ#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ҫӗнӗ Каледони ҫуллахи вӑхӑчӗ#,
				'generic' => q#Ҫӗнӗ Каледони вӑхӑчӗ#,
				'standard' => q#Ҫӗнӗ Каледони стандартлӑ вӑхӑчӗ#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ҫӗнӗ Зеланди ҫуллахи вӑхӑчӗ#,
				'generic' => q#Ҫӗнӗ Зеланди вӑхӑчӗ#,
				'standard' => q#Ҫӗнӗ Зеланди стандартлӑ вӑхӑчӗ#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ньюфаундленд ҫуллахи вӑхӑчӗ#,
				'generic' => q#Ньюфаундленд вӑхӑчӗ#,
				'standard' => q#Ньюфаундленд стандартлӑ вӑхӑчӗ#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ниуэ вӑхӑчӗ#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Норфолк ҫуллахи вӑхӑчӗ#,
				'generic' => q#Норфолк вӑхӑчӗ#,
				'standard' => q#Норфолк стандартлӑ вӑхӑчӗ#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Фернанду-ди-Норонья ҫуллахи вӑхӑчӗ#,
				'generic' => q#Фернанду-ди-Норонья вӑхӑчӗ#,
				'standard' => q#Фернанду-ди-Норонья стандартлӑ вӑхӑчӗ#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Новосибирск ҫуллахи вӑхӑчӗ#,
				'generic' => q#Новосибирск вӑхӑчӗ#,
				'standard' => q#Новосибирск стандартлӑ вӑхӑчӗ#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Омск ҫуллахи вӑхӑчӗ#,
				'generic' => q#Омск вӑхӑчӗ#,
				'standard' => q#Омск стандартлӑ вӑхӑчӗ#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Апиа#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Окленд#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Бугенвиль#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Чатем#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Мӑнкун утравӗ#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Эфате#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Факаофо#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Фиджи#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Фунафути#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Галапагос утравӗсем#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Гамбье утравӗсем#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Гуадалканал#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Гуам#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Джонстон#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Кантон#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Киритимати#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Косрае#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Кваджалейн#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Маджуро#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Маркизас утравӗсем#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Мидуэй#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Науру#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Ниуэ#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Норфолк#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Нумеа#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Паго-Паго#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Палау#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Питкэрн#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Понпеи#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Порт-Морсби#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Раротонга#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Сайпан#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Таити#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Тарава#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Тонгатапу#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Трук#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Уэйк#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Уоллис#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Пакистан ҫуллахи вӑхӑчӗ#,
				'generic' => q#Пакистан вӑхӑчӗ#,
				'standard' => q#Пакистан стандартлӑ вӑхӑчӗ#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Палау вӑхӑчӗ#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Папуа — Ҫӗнӗ Гвиней вӑхӑчӗ#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Парагвай ҫуллахи вӑхӑчӗ#,
				'generic' => q#Парагвай вӑхӑчӗ#,
				'standard' => q#Парагвай стандартлӑ вӑхӑчӗ#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Перу ҫуллахи вӑхӑчӗ#,
				'generic' => q#Перу вӑхӑчӗ#,
				'standard' => q#Перу стандартлӑ вӑхӑчӗ#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Филиппинсем ҫуллахи вӑхӑчӗ#,
				'generic' => q#Филиппинсем вӑхӑчӗ#,
				'standard' => q#Филиппинсем стандартлӑ вӑхӑчӗ#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Феникс вӑхӑчӗ#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Сен-Пьер тата Микелон ҫуллахи вӑхӑчӗ#,
				'generic' => q#Сен-Пьер тата Микелон вӑхӑчӗ#,
				'standard' => q#Сен-Пьер тата Микелон стандартлӑ вӑхӑчӗ#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Питкэрн вӑхӑчӗ#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Понпеи вӑхӑчӗ#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Пхеньян#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Реюньон вӑхӑчӗ#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ротера вӑхӑчӗ#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Сахалин ҫуллахи вӑхӑчӗ#,
				'generic' => q#Сахалин вӑхӑчӗ#,
				'standard' => q#Сахалин стандартлӑ вӑхӑчӗ#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Самоа ҫуллахи вӑхӑчӗ#,
				'generic' => q#Самоа вӑхӑчӗ#,
				'standard' => q#Самоа стандартлӑ вӑхӑчӗ#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Сейшел утравӗсен вӑхӑчӗ#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Сингапур вӑхӑчӗ#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Соломон вӑхӑчӗ#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Кӑнтӑр Георги вӑхӑчӗ#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Суринам вӑхӑчӗ#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Сёва вӑхӑчӗ#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Таити вӑхӑчӗ#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Тайпей ҫуллахи вӑхӑчӗ#,
				'generic' => q#Тайпей вӑхӑчӗ#,
				'standard' => q#Тайпей стандартлӑ вӑхӑчӗ#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Таджикистан вӑхӑчӗ#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Токелау вӑхӑчӗ#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Тонга ҫуллахи вӑхӑчӗ#,
				'generic' => q#Тонга вӑхӑчӗ#,
				'standard' => q#Тонга стандартлӑ вӑхӑчӗ#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Трук вӑхӑчӗ#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Туркменистан ҫуллахи вӑхӑчӗ#,
				'generic' => q#Туркменистан вӑхӑчӗ#,
				'standard' => q#Туркменистан стандартлӑ вӑхӑчӗ#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Тувалу вӑхӑчӗ#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Уругвай ҫуллахи вӑхӑчӗ#,
				'generic' => q#Уругвай вӑхӑчӗ#,
				'standard' => q#Уругвай стандартлӑ вӑхӑчӗ#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Узбекистан ҫуллахи вӑхӑчӗ#,
				'generic' => q#Узбекистан вӑхӑчӗ#,
				'standard' => q#Узбекистан стандартлӑ вӑхӑчӗ#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Вануату ҫуллахи вӑхӑчӗ#,
				'generic' => q#Вануату вӑхӑчӗ#,
				'standard' => q#Вануату стандартлӑ вӑхӑчӗ#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Венесуэла вӑхӑчӗ#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Владивосток ҫуллахи вӑхӑчӗ#,
				'generic' => q#Владивосток вӑхӑчӗ#,
				'standard' => q#Владивосток стандартлӑ вӑхӑчӗ#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Волгоград ҫуллахи вӑхӑчӗ#,
				'generic' => q#Волгоград вӑхӑчӗ#,
				'standard' => q#Волгоград стандартлӑ вӑхӑчӗ#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Восток вӑхӑчӗ#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Уэйк вӑхӑчӗ#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Уоллис тата Футуна вӑхӑчӗ#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Якутск ҫуллахи вӑхӑчӗ#,
				'generic' => q#Якутск вӑхӑчӗ#,
				'standard' => q#Якутск стандартлӑ вӑхӑчӗ#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Екатеринбург ҫуллахи вӑхӑчӗ#,
				'generic' => q#Екатеринбург вӑхӑчӗ#,
				'standard' => q#Екатеринбург стандартлӑ вӑхӑчӗ#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Юкон вӑхӑчӗ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
