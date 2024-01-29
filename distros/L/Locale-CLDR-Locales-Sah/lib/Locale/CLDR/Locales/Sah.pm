=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sah - Package for language Sakha

=cut

package Locale::CLDR::Locales::Sah;
# This file auto generated from Data\common\main\sah.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
				'ab' => 'Абхаастыы',
 				'af' => 'Аппырыкааныстыы',
 				'ale' => 'Алеуттуу',
 				'am' => 'Амхаардыы',
 				'ar' => 'Араабтыы',
 				'ast' => 'Астуурдуу',
 				'av' => 'Аваардыы',
 				'az' => 'Адьырбайдьаанныы',
 				'be' => 'Бөлөрүүстүү',
 				'bg' => 'Булҕаардыы',
 				'bn' => 'Бенгаллыы',
 				'bo' => 'Тибиэттии',
 				'bs' => 'Босныйалыы',
 				'ca' => 'Каталаанныы',
 				'ce' => 'Чэчиэннии',
 				'ckb' => 'Киин куурдуу',
 				'cs' => 'Чиэхтии',
 				'da' => 'Даатскайдыы',
 				'de' => 'Ниэмэстии',
 				'el' => 'Гириэктии',
 				'en' => 'Ааҥыллыы',
 				'es' => 'Ыспаанныы',
 				'et' => 'Эстиэнийэлии',
 				'fa' => 'Пиэристии',
 				'fi' => 'Пииннии',
 				'fil' => 'Пилипииннии',
 				'fr' => 'Боронсуустуу',
 				'hu' => 'Бэҥгиэрдии',
 				'hy' => 'Эрмээннии',
 				'it' => 'Ытаалыйалыы',
 				'ja' => 'Дьоппуоннуу',
 				'ka' => 'Курусууннуу',
 				'kk' => 'Хаһаахтыы',
 				'ko' => 'Кэриэйдии',
 				'ky' => 'Кыргыстыы',
 				'la' => 'Латыынныы',
 				'mn' => 'Моҕуоллуу',
 				'ms' => 'Малаайдыы',
 				'ne' => 'Ньыпааллыы',
 				'nog' => 'Нагаайдыы',
 				'pa' => 'Пандьаабтыы',
 				'pt' => 'Португааллыы',
 				'ro' => 'Румыынныы',
 				'ru' => 'Нууччалыы',
 				'sah' => 'саха тыла',
 				'sk' => 'Словаактыы',
 				'sq' => 'Албаанныы',
 				'ta' => 'Тамыллыы',
 				'te' => 'Төлүгүлүү',
 				'tg' => 'Тадьыыктыы',
 				'tt' => 'Татаардыы',
 				'ug' => 'Уйгуурдуу',
 				'uk' => 'Украйыыньыстыы',
 				'uz' => 'Үзбиэктии',
 				'zh' => 'Кытайдыы',
 				'zu' => 'Зуулулуу',

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
			'Arab' => 'Арааптыы',
 			'Armn' => 'Эрмээннии',
 			'Cyrl' => 'Нууччалыы',
 			'Grek' => 'Гириэктии',
 			'Jpan' => 'Дьоппуоннуу',
 			'Kore' => 'Кэриэйдии',
 			'Latn' => 'Латыынныы',
 			'Mong' => 'Моҕуоллуу',
 			'Thai' => 'Таайдыы',
 			'Zxxx' => 'Суруллубатах',
 			'Zzzz' => 'Биллибэт сурук',

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
			'001' => 'Аан дойду',
 			'002' => 'Аапырыка',
 			'003' => 'Хотугу Эмиэрикэ',
 			'005' => 'Соҕуруу Эмиэрикэ',
 			'BR' => 'Бразилия',
 			'CA' => 'Канаада',
 			'CL' => 'Чиили',
 			'CN' => 'Кытай',
 			'CU' => 'Кууба',
 			'EE' => 'Эстония',
 			'FI' => 'Финляндия',
 			'GB' => 'Улуу Британия',
 			'IE' => 'Ирландия',
 			'IM' => 'Мэн арыы',
 			'IS' => 'Исландия',
 			'JM' => 'Дьамаайка',
 			'LT' => 'Литва',
 			'LV' => 'Латвия',
 			'LY' => 'Лиибийэ',
 			'MX' => 'Миэксикэ',
 			'NO' => 'Норвегия',
 			'RU' => 'Арассыыйа',
 			'SD' => 'Судаан',
 			'SE' => 'Швеция',
 			'US' => 'Америка Холбоһуктаах Штааттара',
 			'US@alt=short' => 'АХШ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Халандаар',
 			'currency' => 'Уларытыы',

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
 				'buddhist' => q{Буудда халандаара},
 				'chinese' => q{Кытай халандаара},
 				'hebrew' => q{Дьэбириэй халандаара},
 				'islamic' => q{Ислаам халандаара},
 				'japanese' => q{Дьоппуон халандаара},
 			},
 			'hc' => {
 				'h11' => q{12 чаастаах тиһик (0–11)},
 				'h12' => q{12 чаастаах тиһик (0–12)},
 				'h23' => q{24 чаастаах тиһик (0–23)},
 				'h24' => q{24 чаастаах тиһик (0–24)},
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
			'metric' => q{Мэтриичэскэй},
 			'UK' => q{Ааҥыллыы},
 			'US' => q{Эмиэрикэлии},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Тыл: {0}',
 			'script' => 'Сурук: {0}',
 			'region' => 'Сир: {0}',

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
			auxiliary => qr{[в е ё ж з ф ц ш щ ъ ь ю я]},
			index => ['А', 'Б', 'Г', 'Ҕ', 'Д', '{Дь}', 'И', 'Й', 'К', 'Л', 'М', 'Н', '{Нь}', 'Ҥ', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Х', 'Һ', 'Ч', 'Ы', 'Э'],
			main => qr{[а б г ҕ д {дь} и й к л м н {нь} ҥ о ө п р с т у ү х һ ч ы э]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\:]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'Г', 'Ҕ', 'Д', '{Дь}', 'И', 'Й', 'К', 'Л', 'М', 'Н', '{Нь}', 'Ҥ', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Х', 'Һ', 'Ч', 'Ы', 'Э'], };
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
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
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

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(кыраадыс),
						'other' => q({0} кыраадыс),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(кыраадыс),
						'other' => q({0} кыраадыс),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(гектаар),
						'other' => q({0} гектаар),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(гектаар),
						'other' => q({0} гектаар),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(кыбатыраатынай сэнтимиэтир),
						'other' => q({0} кыбатыраатынай сэнтимиэтир),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(кыбатыраатынай сэнтимиэтир),
						'other' => q({0} кыбатыраатынай сэнтимиэтир),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(караат),
						'other' => q({0} караат),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(караат),
						'other' => q({0} караат),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(биит),
						'other' => q({0} биит),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(биит),
						'other' => q({0} биит),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(баайт),
						'other' => q({0} баайт),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(баайт),
						'other' => q({0} баайт),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(гигабиит),
						'other' => q({0} гигабиит),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(гигабиит),
						'other' => q({0} гигабиит),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(ГБаайт),
						'other' => q({0} ГБаайт),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(ГБаайт),
						'other' => q({0} ГБаайт),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(килобиит),
						'other' => q({0} килобиит),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(килобиит),
						'other' => q({0} килобиит),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(килобаайт),
						'other' => q({0} килобаайт),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(килобаайт),
						'other' => q({0} килобаайт),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(мегабиит),
						'other' => q({0} мегабиит),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(мегабиит),
						'other' => q({0} мегабиит),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(мегабаайт),
						'other' => q({0} мегабаайт),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(мегабаайт),
						'other' => q({0} мегабаайт),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Тбит),
						'other' => q({0} Тбит),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Тбит),
						'other' => q({0} Тбит),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(терабаайт),
						'other' => q({0} терабаайт),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(терабаайт),
						'other' => q({0} терабаайт),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(үйэлэр),
						'other' => q({0} үйэ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(үйэлэр),
						'other' => q({0} үйэ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(күн),
						'other' => q({0} күн),
						'per' => q(күҥҥэ {0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(күн),
						'other' => q({0} күн),
						'per' => q(күҥҥэ {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(чаас),
						'other' => q({0} чаас),
						'per' => q(чааска {0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(чаас),
						'other' => q({0} чаас),
						'per' => q(чааска {0}),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(микросөкүүндэлэр),
						'other' => q({0} микросөкүүндэ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(микросөкүүндэлэр),
						'other' => q({0} микросөкүүндэ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(миллисөкүүндэлэр),
						'other' => q({0} миллисөкүүндэ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(миллисөкүүндэлэр),
						'other' => q({0} миллисөкүүндэ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(мүнүүтэ),
						'other' => q({0} мүнүүтэ),
						'per' => q(мүнүүтэҕэ {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(мүнүүтэ),
						'other' => q({0} мүнүүтэ),
						'per' => q(мүнүүтэҕэ {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ый),
						'other' => q({0} ый),
						'per' => q(ыйга {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ый),
						'other' => q({0} ый),
						'per' => q(ыйга {0}),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(наносөкүүндэлэр),
						'other' => q({0} наносөкүүндэ),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(наносөкүүндэлэр),
						'other' => q({0} наносөкүүндэ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(сөкүүндэ),
						'other' => q({0} сөкүүндэ),
						'per' => q(сөкүүндэҕэ {0}),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(сөкүүндэ),
						'other' => q({0} сөкүүндэ),
						'per' => q(сөкүүндэҕэ {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(нэдиэлэ),
						'other' => q({0} нэдиэлэ),
						'per' => q(нэдиэлэҕэ {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(нэдиэлэ),
						'other' => q({0} нэдиэлэ),
						'per' => q(нэдиэлэҕэ {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(сыл),
						'other' => q({0} сыл),
						'per' => q(сылга {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(сыл),
						'other' => q({0} сыл),
						'per' => q(сылга {0}),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ампер),
						'other' => q({0} ампер),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ампер),
						'other' => q({0} ампер),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(миллиампер),
						'other' => q({0} миллиампер),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(миллиампер),
						'other' => q({0} миллиампер),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(вольт),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(вольт),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(калорий),
						'other' => q({0} калорий),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(калорий),
						'other' => q({0} калорий),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Калорий),
						'other' => q({0} Калорий),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Калорий),
						'other' => q({0} Калорий),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(джоуль),
						'other' => q({0} джоуль),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(джоуль),
						'other' => q({0} джоуль),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(килоджоуль),
						'other' => q({0} килоджоуль),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(килоджоуль),
						'other' => q({0} килоджоуль),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(киловатт-чаас),
						'other' => q({0} киловатт-чаас),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(киловатт-чаас),
						'other' => q({0} киловатт-чаас),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(герц),
						'other' => q({0} герц),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(герц),
						'other' => q({0} герц),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(километрдар),
						'other' => q({0} километр),
						'per' => q(километрга {0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(километрдар),
						'other' => q({0} километр),
						'per' => q(километрга {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(миэтэрэ),
						'other' => q({0} миэтэрэ),
						'per' => q(миэтиргэ {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(миэтэрэ),
						'other' => q({0} миэтэрэ),
						'per' => q(миэтиргэ {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(миилэ),
						'other' => q({0} миилэ),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(миилэ),
						'other' => q({0} миилэ),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(люкс),
						'other' => q({0} люкс),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(люкс),
						'other' => q({0} люкс),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(караат),
						'other' => q({0} караат),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(караат),
						'other' => q({0} караат),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(кыраам),
						'other' => q({0} кыраам),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(кыраам),
						'other' => q({0} кыраам),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(киилэ),
						'other' => q({0} киилэ),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(киилэ),
						'other' => q({0} киилэ),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(кВт),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(кВт),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Сиэлсий кыраадыһа),
						'other' => q({0} Сиэлсий кыраадыһа),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Сиэлсий кыраадыһа),
						'other' => q({0} Сиэлсий кыраадыһа),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Фаренгейт кыраадыһа),
						'other' => q({0} Фаренгейт кыраадыһа),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Фаренгейт кыраадыһа),
						'other' => q({0} Фаренгейт кыраадыһа),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(кельвин кыраадыһа),
						'other' => q({0} кельвин),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(кельвин кыраадыһа),
						'other' => q({0} кельвин),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(лиитирэ),
						'other' => q({0} лиитирэ),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(лиитирэ),
						'other' => q({0} лиитирэ),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0} к.),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0} к.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} ч),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} ч),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(мс),
						'other' => q({0} мс),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(мс),
						'other' => q({0} мс),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0} мүн),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0} мүн),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ый),
						'other' => q({0} ый),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ый),
						'other' => q({0} ый),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0} с),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0} с),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} н.),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} н.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} с.),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} с.),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(см),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(см),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(км),
						'other' => q({0} км),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(км),
						'other' => q({0} км),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(миэтэрэ),
						'other' => q({0} м),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(миэтэрэ),
						'other' => q({0} м),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(мм),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(мм),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(кыраам),
						'other' => q({0} г),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(кыраам),
						'other' => q({0} г),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(кг),
						'other' => q({0} кг),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(кг),
						'other' => q({0} кг),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(лиитирэ),
						'other' => q({0}л),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(лиитирэ),
						'other' => q({0}л),
					},
				},
				'short' => {
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(кыраадыс),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(кыраадыс),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(гаа),
						'other' => q({0} гаа),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(гаа),
						'other' => q({0} гаа),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(см²),
						'other' => q({0} см²),
						'per' => q({0}/см²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(см²),
						'other' => q({0} см²),
						'per' => q({0}/см²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(караат),
						'other' => q({0} кар.),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(караат),
						'other' => q({0} кар.),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(бит),
						'other' => q({0} бит),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(бит),
						'other' => q({0} бит),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(байт),
						'other' => q({0} байт),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(байт),
						'other' => q({0} байт),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(кб),
						'other' => q({0} кб),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(кб),
						'other' => q({0} кб),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(кБайт),
						'other' => q({0} кБ),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(кБайт),
						'other' => q({0} кБ),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Мбит),
						'other' => q({0} Мбит),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Мбит),
						'other' => q({0} Мбит),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(МБ),
						'other' => q({0} МБ),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(МБ),
						'other' => q({0} МБ),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ТБаайт),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ТБаайт),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ү.),
						'other' => q({0} ү.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ү.),
						'other' => q({0} ү.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(күн),
						'other' => q({0} күн),
						'per' => q({0}/күн),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(күн),
						'other' => q({0} күн),
						'per' => q({0}/күн),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(чаас),
						'other' => q({0} ч),
						'per' => q({0}/ч),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(чаас),
						'other' => q({0} ч),
						'per' => q({0}/ч),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(мкс),
						'other' => q({0} мкс),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(мкс),
						'other' => q({0} мкс),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(мс),
						'other' => q({0} мс),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(мс),
						'other' => q({0} мс),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(мүнүүтэ),
						'other' => q({0} мүн),
						'per' => q({0}/мүн),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(мүнүүтэ),
						'other' => q({0} мүн),
						'per' => q({0}/мүн),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ый),
						'other' => q({0} ый),
						'per' => q({0}/ый),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ый),
						'other' => q({0} ый),
						'per' => q({0}/ый),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(нс),
						'other' => q({0} нс),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(нс),
						'other' => q({0} нс),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(сөкүүндэ),
						'other' => q({0} сөк),
						'per' => q({0}/сөк),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(сөкүүндэ),
						'other' => q({0} сөк),
						'per' => q({0}/сөк),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(нэдиэлэ),
						'other' => q({0} нэд.),
						'per' => q({0}/нэд),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(нэдиэлэ),
						'other' => q({0} нэд.),
						'per' => q({0}/нэд),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(сыл),
						'other' => q({0} с.),
						'per' => q({0}/с),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(сыл),
						'other' => q({0} с.),
						'per' => q({0}/с),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'other' => q({0} А),
					},
					# Core Unit Identifier
					'ampere' => {
						'other' => q({0} А),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'other' => q({0} мА),
					},
					# Core Unit Identifier
					'milliampere' => {
						'other' => q({0} мА),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(кал),
						'other' => q({0} кал),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(кал),
						'other' => q({0} кал),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Кал),
						'other' => q({0} Кал),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Кал),
						'other' => q({0} Кал),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(дж),
						'other' => q({0} дж),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(дж),
						'other' => q({0} дж),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(ккал),
						'other' => q({0} ккал),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(ккал),
						'other' => q({0} ккал),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(кдж),
						'other' => q({0} кдж),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(кдж),
						'other' => q({0} кдж),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'other' => q({0} кВт/ч),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'other' => q({0} кВт/ч),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Гц),
						'other' => q({0} Гц),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Гц),
						'other' => q({0} Гц),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(см),
						'other' => q({0} см),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(см),
						'other' => q({0} см),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(км),
						'other' => q({0} км),
						'per' => q({0}/км),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(км),
						'other' => q({0} км),
						'per' => q({0}/км),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(миэтэрэ),
						'other' => q({0} м),
						'per' => q({0}/м),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(миэтэрэ),
						'other' => q({0} м),
						'per' => q({0}/м),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(миилэ),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(миилэ),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(мм),
						'other' => q({0} мм),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(мм),
						'other' => q({0} мм),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(люкс),
						'other' => q({0} лк),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(люкс),
						'other' => q({0} лк),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(караат),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(караат),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(кыраам),
						'other' => q({0} г),
						'per' => q({0}/г),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(кыраам),
						'other' => q({0} г),
						'per' => q({0}/г),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(кг),
						'other' => q({0} кг),
						'per' => q({0}/кг),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(кг),
						'other' => q({0} кг),
						'per' => q({0}/кг),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(т),
						'other' => q({0} т),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(т),
						'other' => q({0} т),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(мг),
						'other' => q({0} мг),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(мг),
						'other' => q({0} мг),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(кыр. С),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(кыр. С),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(см³),
						'other' => q({0} см³),
						'per' => q({0}/см³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(см³),
						'other' => q({0} см³),
						'per' => q({0}/см³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(км³),
						'other' => q({0} км³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(км³),
						'other' => q({0} км³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(м³),
						'other' => q({0} м³),
						'per' => q({0}/м³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(м³),
						'other' => q({0} м³),
						'per' => q({0}/м³),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(лиитирэ),
						'other' => q({0} л),
						'per' => q({0}/л),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(лиитирэ),
						'other' => q({0} л),
						'per' => q({0}/л),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:сөп|с|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:суох|х|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} уонна {1}),
				2 => q({0}, {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
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
			'minusSign' => q(-),
			'nan' => q(чыыһыла буотах),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
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
				'1000' => {
					'other' => '0 тыһ'.'',
				},
				'10000' => {
					'other' => '00 тыһ'.'',
				},
				'100000' => {
					'other' => '000 тыһ'.'',
				},
				'1000000' => {
					'other' => '0 мөл',
				},
				'10000000' => {
					'other' => '00 мөл',
				},
				'100000000' => {
					'other' => '000 мөл',
				},
				'1000000000' => {
					'other' => '0 млрд',
				},
				'10000000000' => {
					'other' => '00 млрд',
				},
				'100000000000' => {
					'other' => '000 млрд',
				},
				'1000000000000' => {
					'other' => '0 трлн',
				},
				'10000000000000' => {
					'other' => '00 трлн',
				},
				'100000000000000' => {
					'other' => '000 трлн',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'other' => '0 тыһыынча',
				},
				'10000' => {
					'other' => '00 тыһыынча',
				},
				'100000' => {
					'other' => '000 тыһыынча',
				},
				'1000000' => {
					'other' => '0 мөлүйүөн',
				},
				'10000000' => {
					'other' => '00 мөлүйүөн',
				},
				'100000000' => {
					'other' => '000 мөлүйүөн',
				},
				'1000000000' => {
					'other' => '0 миллиард',
				},
				'10000000000' => {
					'other' => '00 миллиард',
				},
				'100000000000' => {
					'other' => '000 миллиард',
				},
				'1000000000000' => {
					'other' => '0 триллион',
				},
				'10000000000000' => {
					'other' => '00 триллион',
				},
				'100000000000000' => {
					'other' => '000 триллион',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0 тыһ'.'',
				},
				'10000' => {
					'other' => '00 тыһ'.'',
				},
				'100000' => {
					'other' => '000 тыһ'.'',
				},
				'1000000' => {
					'other' => '0 мөл',
				},
				'10000000' => {
					'other' => '00 мөл',
				},
				'100000000' => {
					'other' => '000 мөл',
				},
				'1000000000' => {
					'other' => '0 млрд',
				},
				'10000000000' => {
					'other' => '00 млрд',
				},
				'100000000000' => {
					'other' => '000 млрд',
				},
				'1000000000000' => {
					'other' => '0 трлн',
				},
				'10000000000000' => {
					'other' => '00 трлн',
				},
				'100000000000000' => {
					'other' => '000 трлн',
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
					'accounting' => {
						'positive' => '#,##0.00 ¤',
					},
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
		'AWG' => {
			symbol => 'AWG',
		},
		'BMD' => {
			symbol => 'BMD',
		},
		'BZD' => {
			symbol => 'BZD',
		},
		'CAD' => {
			symbol => 'CA$',
		},
		'CRC' => {
			symbol => 'CRC',
		},
		'GTQ' => {
			symbol => 'GTQ',
		},
		'HNL' => {
			symbol => 'HNL',
		},
		'MXN' => {
			symbol => 'MX$',
		},
		'NIO' => {
			symbol => 'NIO',
		},
		'PAB' => {
			symbol => 'PAB',
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(Арассыыйа солкуобайа),
				'other' => q(Арассыыйа солкуобайа),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(АХШ дуоллара),
				'other' => q(АХШ дуоллара),
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
							'Тохс',
							'Олун',
							'Клн',
							'Мсу',
							'Ыам',
							'Бэс',
							'Отй',
							'Атр',
							'Блҕ',
							'Алт',
							'Сэт',
							'Ахс'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Т',
							'О',
							'К',
							'М',
							'Ы',
							'Б',
							'О',
							'А',
							'Б',
							'А',
							'С',
							'А'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Тохсунньу',
							'Олунньу',
							'Кулун тутар',
							'Муус устар',
							'Ыам ыйын',
							'Бэс ыйын',
							'От ыйын',
							'Атырдьых ыйын',
							'Балаҕан ыйын',
							'Алтынньы',
							'Сэтинньи',
							'ахсынньы'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Тохс',
							'Олун',
							'Клн',
							'Мсу',
							'Ыам',
							'Бэс',
							'Отй',
							'Атр',
							'Блҕ',
							'Алт',
							'Сэт',
							'Ахс'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Т',
							'О',
							'К',
							'М',
							'Ы',
							'Б',
							'О',
							'А',
							'Б',
							'А',
							'С',
							'А'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'тохсунньу',
							'олунньу',
							'кулун тутар',
							'муус устар',
							'ыам ыйа',
							'бэс ыйа',
							'от ыйа',
							'атырдьых ыйа',
							'балаҕан ыйа',
							'алтынньы',
							'сэтинньи',
							'ахсынньы'
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
						mon => 'бн',
						tue => 'оп',
						wed => 'сэ',
						thu => 'чп',
						fri => 'бэ',
						sat => 'сб',
						sun => 'бс'
					},
					narrow => {
						mon => 'Б',
						tue => 'О',
						wed => 'С',
						thu => 'Ч',
						fri => 'Б',
						sat => 'С',
						sun => 'Б'
					},
					short => {
						mon => 'бн',
						tue => 'оп',
						wed => 'сэ',
						thu => 'чп',
						fri => 'бэ',
						sat => 'сб',
						sun => 'бс'
					},
					wide => {
						mon => 'бэнидиэнньик',
						tue => 'оптуорунньук',
						wed => 'сэрэдэ',
						thu => 'чэппиэр',
						fri => 'Бээтиҥсэ',
						sat => 'субуота',
						sun => 'баскыһыанньа'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'бн',
						tue => 'оп',
						wed => 'сэ',
						thu => 'чп',
						fri => 'бэ',
						sat => 'сб',
						sun => 'бс'
					},
					narrow => {
						mon => 'Б',
						tue => 'О',
						wed => 'С',
						thu => 'Ч',
						fri => 'Б',
						sat => 'С',
						sun => 'Б'
					},
					short => {
						mon => 'бн',
						tue => 'оп',
						wed => 'сэ',
						thu => 'чп',
						fri => 'бэ',
						sat => 'сб',
						sun => 'бс'
					},
					wide => {
						mon => 'бэнидиэнньик',
						tue => 'оптуорунньук',
						wed => 'сэрэдэ',
						thu => 'чэппиэр',
						fri => 'Бээтиҥсэ',
						sat => 'субуота',
						sun => 'баскыһыанньа'
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
					abbreviated => {0 => '1-кы кб',
						1 => '2-с кб',
						2 => '3-с кб',
						3 => '4-с кб'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-кы кыбаартал',
						1 => '2-с кыбаартал',
						2 => '3-с кыбаартал',
						3 => '4-с кыбаартал'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1-кы кб',
						1 => '2-с кб',
						2 => '3-с кб',
						3 => '4-с кб'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-кы кыбаартал',
						1 => '2-с кыбаартал',
						2 => '3-с кыбаартал',
						3 => '4-с кыбаартал'
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
					'am' => q{ЭИ},
					'pm' => q{ЭК},
				},
				'narrow' => {
					'am' => q{ЭИ},
					'pm' => q{ЭК},
				},
				'wide' => {
					'am' => q{ЭИ},
					'pm' => q{ЭК},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ЭИ},
					'pm' => q{ЭК},
				},
				'narrow' => {
					'am' => q{ЭИ},
					'pm' => q{ЭК},
				},
				'wide' => {
					'am' => q{ЭИ},
					'pm' => q{ЭК},
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
				'0' => 'б. э. и.',
				'1' => 'б. э'
			},
			wide => {
				'0' => 'б. э. и.',
				'1' => 'б. э'
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
			'full' => q{G y 'сыл' MMMM d 'күнэ', EEEE},
			'long' => q{G y, MMMM d},
			'medium' => q{G y, MMM d},
			'short' => q{GGGGG yy/M/d},
		},
		'gregorian' => {
			'full' => q{y 'сыл' MMMM d 'күнэ', EEEE},
			'long' => q{y, MMMM d},
			'medium' => q{y, MMM d},
			'short' => q{yy/M/d},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			E => q{ccc},
			Ed => q{d, E},
			Gy => q{G y},
			d => q{d},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y 'с'. G},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMW => q{MMMM W 'нэдиэлэтэ'},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{y-MM-dd, E},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{y MMMM},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{Y 'сыл' w 'нэдиэлэтэ'},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			fallback => '{0} – {1}',
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
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
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{dd.MM.y – dd.MM.y},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Arabian' => {
			long => {
				'daylight' => q#Арааб сайыҥҥы кэмэ#,
				'generic' => q#Арааб кэмэ#,
				'standard' => q#Арааб сүрүн кэмэ#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Эрмээн сайыҥҥы кэмэ#,
				'generic' => q#Эрмээн кэмэ#,
				'standard' => q#Эрмээн сүрүн кэмэ#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Алматы#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Анаадыр#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Асхабаат#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Багдаад#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Бакуу#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Барнаул#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Читаа#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Чойбалсан#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Коломбо#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Дамаас#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Дубаай#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Иркутскай#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Кабуул#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Камчаатка#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Хаандыга#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Красноярскай#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Магадаан#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Новосибирскай#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Омскай#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Хо Ши Минь#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Сахалиин#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Самаркаан#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Орто Халыма#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Улан Баатар#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Урумчу#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Уус Ньара#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Дьокуускай#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Екатеринбуур#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Киин Австралия сайыҥҥы кэмэ#,
				'generic' => q#Киин Австралия кэмэ#,
				'standard' => q#Киин Австралия сүрүн кэмэ#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Илин Австралия сайыҥҥы кэмэ#,
				'generic' => q#Илин Австралия кэмэ#,
				'standard' => q#Илин Австралия сүрүн кэмэ#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Арҕаа Австралия сайыҥҥы кэмэ#,
				'generic' => q#Арҕаа Австралия кэмэ#,
				'standard' => q#Арҕаа Австралия сүрүн кэмэ#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Кытай сайыҥҥы кэмэ#,
				'generic' => q#Кытай кэмэ#,
				'standard' => q#Кытай сүрүн кэмэ#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Чойбалсан сайыҥҥы кэмэ#,
				'generic' => q#Чойбалсан кэмэ#,
				'standard' => q#Чойбалсан сүрүн кэмэ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Биллибэт#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Аастрахан#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Стамбуул#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Калининград#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Москуба#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Самаара#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Симферополь#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ульяновскай#,
		},
		'Georgia' => {
			long => {
				'daylight' => q#Курусуун сайыҥҥы кэмэ#,
				'generic' => q#Курусуун кэмэ#,
				'standard' => q#Курусуун сүрүн кэмэ#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ииндийэ сүрүн кэмэ#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Ыраан сайыҥҥы кэмэ#,
				'generic' => q#Ираан кэмэ#,
				'standard' => q#Ираан сүрүн кэмэ#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Дьоппуон сайыҥҥы кэмэ#,
				'generic' => q#Дьоппуон кэмэ#,
				'standard' => q#Дьоппуон сүрүн кэмэ#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Илин Казахстаан кэмэ#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Арҕаа Казахстаан кэмэ#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Кэриэй сайыҥҥы кэмэ#,
				'generic' => q#Кэриэй кэмэ#,
				'standard' => q#Кэриэй сүрүн кэмэ#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Красноярскай сайыҥҥы кэмэ#,
				'generic' => q#Красноярскай кэмэ#,
				'standard' => q#Красноярскай сүрүн кэмэ#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Кыргыстаан кэмэ#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Магадаан сайыҥҥы кэмэ#,
				'generic' => q#Магадаан кэмэ#,
				'standard' => q#Магадаан сүрүн кэмэ#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Улан Баатар сайыҥҥы кэмэ#,
				'generic' => q#Улан Баатар кэмэ#,
				'standard' => q#Улан Баатар сүрүн кэмэ#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Москуба сайыҥҥы кэмэ#,
				'generic' => q#Москуба кэмэ#,
				'standard' => q#Москуба сүрүн кэмэ#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Саҥа Сэйлэнд сайыҥҥы кэмэ#,
				'generic' => q#Саҥа Зеландия кэмэ#,
				'standard' => q#Саҥа Сэйлэнд сүрүн кэмэ#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Новосибирскай сайыҥҥы кэмэ#,
				'generic' => q#Новосибирскай кэмэ#,
				'standard' => q#Новосибирскай сүрүн кэмэ#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Омскай сайыҥҥы кэмэ#,
				'generic' => q#Омскай кэмэ#,
				'standard' => q#Омскай сүрүн кэмэ#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Пакистаан сайыҥҥы кэмэ#,
				'generic' => q#Пакистаан кэмэ#,
				'standard' => q#Пакистаан сүрүн кэмэ#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Сахалыын сайыҥҥы кэмэ#,
				'generic' => q#Сахалиин кэмэ#,
				'standard' => q#Сахалыын сүрүн кэмэ#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Быладьыбастыак сайыҥҥы кэмэ#,
				'generic' => q#Владивосток кэмэ#,
				'standard' => q#Быладьыбастыак сүрүн кэмэ#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Волгоград сайыҥҥы кэмэ#,
				'generic' => q#Волгоград кэмэ#,
				'standard' => q#Волгоград сүрүн кэмэ#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Дьокуускай сайыҥҥы кэмэ#,
				'generic' => q#Дьокуускай кэмэ#,
				'standard' => q#Дьокуускай сүрүн кэмэ#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Екатеринбуур сайыҥҥы кэмэ#,
				'generic' => q#Екатеринбург кэмэ#,
				'standard' => q#Екатеринбуур сүрүн кэмэ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
