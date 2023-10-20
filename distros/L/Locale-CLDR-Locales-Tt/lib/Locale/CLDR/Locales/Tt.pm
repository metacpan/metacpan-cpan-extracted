=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tt - Package for language Tatar

=cut

package Locale::CLDR::Locales::Tt;
# This file auto generated from Data\common\main\tt.xml
#	on Fri 13 Oct  9:46:28 am GMT

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
				'af' => 'африкаанс',
 				'am' => 'амхар',
 				'ar' => 'гарәп',
 				'arn' => 'мапуче',
 				'as' => 'ассам',
 				'az' => 'әзәрбайҗан',
 				'ba' => 'башкорт',
 				'ban' => 'бали',
 				'be' => 'белорус',
 				'bem' => 'бемба',
 				'bg' => 'болгар',
 				'bn' => 'бенгали',
 				'bo' => 'тибет',
 				'br' => 'бретон',
 				'bs' => 'босния',
 				'ca' => 'каталан',
 				'ceb' => 'себуано',
 				'chm' => 'мари',
 				'chr' => 'чероки',
 				'ckb' => 'үзәк көрд',
 				'co' => 'корсика',
 				'cs' => 'чех',
 				'cy' => 'уэльс',
 				'da' => 'дания',
 				'de' => 'алман',
 				'de_CH' => 'югары алман (Швейцария)',
 				'dsb' => 'түбән сорб',
 				'dv' => 'мальдив',
 				'dz' => 'дзонг-кха',
 				'el' => 'грек',
 				'en' => 'инглиз',
 				'eo' => 'эсперанто',
 				'es' => 'испан',
 				'es_419' => 'испан (Латин Америкасы)',
 				'es_ES' => 'испан (Европа)',
 				'et' => 'эстон',
 				'eu' => 'баск',
 				'fa' => 'фарсы',
 				'ff' => 'фула',
 				'fi' => 'фин',
 				'fil' => 'филиппин',
 				'fo' => 'фарер',
 				'fr' => 'француз',
 				'ga' => 'ирланд',
 				'gd' => 'шотланд гэль',
 				'gl' => 'галисия',
 				'gn' => 'гуарани',
 				'gu' => 'гуҗарати',
 				'ha' => 'хауса',
 				'haw' => 'гавайи',
 				'he' => 'яһүд',
 				'hi' => 'һинд',
 				'hil' => 'хилигайнон',
 				'hr' => 'хорват',
 				'hsb' => 'югары сорб',
 				'ht' => 'гаити креол',
 				'hu' => 'венгр',
 				'hy' => 'әрмән',
 				'hz' => 'гереро',
 				'ibb' => 'ибибио',
 				'id' => 'индонезия',
 				'ig' => 'игбо',
 				'is' => 'исланд',
 				'it' => 'итальян',
 				'iu' => 'инуктикут',
 				'ja' => 'япон',
 				'ka' => 'грузин',
 				'kk' => 'казакъ',
 				'km' => 'кхмер',
 				'kn' => 'каннада',
 				'ko' => 'корея',
 				'kok' => 'конкани',
 				'kr' => 'канури',
 				'kru' => 'курух',
 				'ks' => 'кашмири',
 				'ku' => 'көрд',
 				'ky' => 'кыргыз',
 				'la' => 'латин',
 				'lb' => 'люксембург',
 				'lo' => 'лаос',
 				'lt' => 'литва',
 				'lv' => 'латыш',
 				'men' => 'менде',
 				'mg' => 'малагаси',
 				'mi' => 'маори',
 				'mk' => 'македон',
 				'ml' => 'малаялам',
 				'mn' => 'монгол',
 				'mni' => 'манипури',
 				'moh' => 'могаук',
 				'mr' => 'маратхи',
 				'ms' => 'малай',
 				'mt' => 'мальта',
 				'my' => 'бирма',
 				'ne' => 'непали',
 				'niu' => 'ниуэ',
 				'nl' => 'голланд',
 				'ny' => 'ньянҗа',
 				'oc' => 'окситан',
 				'om' => 'оромо',
 				'or' => 'ория',
 				'pa' => 'пәнҗаби',
 				'pap' => 'папьяменто',
 				'pl' => 'поляк',
 				'ps' => 'пушту',
 				'pt' => 'португал',
 				'pt_PT' => 'португал (Европа)',
 				'qu' => 'кечуа',
 				'quc' => 'киче',
 				'rm' => 'ретороман',
 				'ro' => 'румын',
 				'ru' => 'рус',
 				'rw' => 'руанда',
 				'sa' => 'санскрит',
 				'sah' => 'саха',
 				'sat' => 'сантали',
 				'sd' => 'синдһи',
 				'se' => 'төньяк саам',
 				'si' => 'сингал',
 				'sk' => 'словак',
 				'sl' => 'словен',
 				'sma' => 'көньяк саам',
 				'smj' => 'луле-саам',
 				'smn' => 'инари-саам',
 				'sms' => 'колтта-саам',
 				'so' => 'сомали',
 				'sq' => 'албан',
 				'sr' => 'серб',
 				'sv' => 'швед',
 				'syr' => 'сүрия',
 				'ta' => 'тамил',
 				'te' => 'телугу',
 				'tg' => 'таҗик',
 				'th' => 'тай',
 				'ti' => 'тигринья',
 				'tk' => 'төрекмән',
 				'to' => 'тонга',
 				'tr' => 'төрек',
 				'tt' => 'татар',
 				'tzm' => 'үзәк атлас тамазигт',
 				'ug' => 'уйгыр',
 				'uk' => 'украин',
 				'und' => 'билгесез тел',
 				'ur' => 'урду',
 				'uz' => 'үзбәк',
 				've' => 'венда',
 				'vi' => 'вьетнам',
 				'wo' => 'волоф',
 				'yi' => 'идиш',
 				'yo' => 'йоруба',
 				'zh' => 'кытай',
 				'zh_Hans' => 'гадиләштерелгән кытай',
 				'zh_Hant' => 'традицион кытай',

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
			'Arab' => 'гарәп',
 			'Cyrl' => 'кирилл',
 			'Hans' => 'гадиләштерелгән',
 			'Hans@alt=stand-alone' => 'гадиләштерелгән кытай',
 			'Hant' => 'традицион',
 			'Hant@alt=stand-alone' => 'традицион кытай',
 			'Latn' => 'латин',
 			'Zxxx' => 'язусыз',
 			'Zzzz' => 'билгесез язу',

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
			'AD' => 'Андорра',
 			'AE' => 'Берләшкән Гарәп Әмирлекләре',
 			'AF' => 'Әфганстан',
 			'AG' => 'Антигуа һәм Барбуда',
 			'AI' => 'Ангилья',
 			'AL' => 'Албания',
 			'AM' => 'Әрмәнстан',
 			'AO' => 'Ангола',
 			'AQ' => 'Антарктика',
 			'AR' => 'Аргентина',
 			'AS' => 'Америка Самоасы',
 			'AT' => 'Австрия',
 			'AU' => 'Австралия',
 			'AW' => 'Аруба',
 			'AX' => 'Аланд утраулары',
 			'AZ' => 'Әзәрбайҗан',
 			'BA' => 'Босния һәм Герцеговина',
 			'BB' => 'Барбадос',
 			'BD' => 'Бангладеш',
 			'BE' => 'Бельгия',
 			'BF' => 'Буркина-Фасо',
 			'BG' => 'Болгария',
 			'BH' => 'Бәхрәйн',
 			'BI' => 'Бурунди',
 			'BJ' => 'Бенин',
 			'BL' => 'Сен-Бартельми',
 			'BM' => 'Бермуд утраулары',
 			'BN' => 'Бруней',
 			'BO' => 'Боливия',
 			'BR' => 'Бразилия',
 			'BS' => 'Багам утраулары',
 			'BT' => 'Бутан',
 			'BV' => 'Буве утравы',
 			'BW' => 'Ботсвана',
 			'BY' => 'Беларусь',
 			'BZ' => 'Белиз',
 			'CA' => 'Канада',
 			'CC' => 'Кокос (Килинг) утраулары',
 			'CD@alt=variant' => 'Конго (КДР)',
 			'CF' => 'Үзәк Африка Республикасы',
 			'CH' => 'Швейцария',
 			'CI' => 'Кот-д’Ивуар',
 			'CK' => 'Кук утраулары',
 			'CL' => 'Чили',
 			'CM' => 'Камерун',
 			'CN' => 'Кытай',
 			'CO' => 'Колумбия',
 			'CR' => 'Коста-Рика',
 			'CU' => 'Куба',
 			'CV' => 'Кабо-Верде',
 			'CW' => 'Кюрасао',
 			'CX' => 'Раштуа утравы',
 			'CY' => 'Кипр',
 			'CZ' => 'Чехия Республикасы',
 			'DE' => 'Германия',
 			'DJ' => 'Җибүти',
 			'DK' => 'Дания',
 			'DM' => 'Доминика',
 			'DO' => 'Доминикана Республикасы',
 			'DZ' => 'Алжир',
 			'EC' => 'Эквадор',
 			'EE' => 'Эстония',
 			'EG' => 'Мисыр',
 			'ER' => 'Эритрея',
 			'ES' => 'Испания',
 			'ET' => 'Эфиопия',
 			'FI' => 'Финляндия',
 			'FJ' => 'Фиджи',
 			'FK' => 'Фолкленд утраулары',
 			'FM' => 'Микронезия',
 			'FO' => 'Фарер утраулары',
 			'FR' => 'Франция',
 			'GA' => 'Габон',
 			'GB' => 'Бөекбритания',
 			'GD' => 'Гренада',
 			'GE' => 'Грузия',
 			'GF' => 'Француз Гвианасы',
 			'GG' => 'Гернси',
 			'GH' => 'Гана',
 			'GI' => 'Гибралтар',
 			'GL' => 'Гренландия',
 			'GM' => 'Гамбия',
 			'GN' => 'Гвинея',
 			'GP' => 'Гваделупа',
 			'GQ' => 'Экваториаль Гвинея',
 			'GR' => 'Греция',
 			'GS' => 'Көньяк Георгия һәм Көньяк Сандвич утраулары',
 			'GT' => 'Гватемала',
 			'GU' => 'Гуам',
 			'GW' => 'Гвинея-Бисау',
 			'GY' => 'Гайана',
 			'HK' => 'Гонконг Махсус Идарәле Төбәге',
 			'HK@alt=short' => 'Гонконг',
 			'HM' => 'Херд утравы һәм Макдональд утраулары',
 			'HN' => 'Гондурас',
 			'HR' => 'Хорватия',
 			'HT' => 'Гаити',
 			'HU' => 'Венгрия',
 			'ID' => 'Индонезия',
 			'IE' => 'Ирландия',
 			'IL' => 'Израиль',
 			'IM' => 'Мэн утравы',
 			'IN' => 'Индия',
 			'IO' => 'Британиянең Һинд Океанындагы Территориясе',
 			'IQ' => 'Гыйрак',
 			'IR' => 'Иран',
 			'IS' => 'Исландия',
 			'IT' => 'Италия',
 			'JE' => 'Джерси',
 			'JM' => 'Ямайка',
 			'JO' => 'Иордания',
 			'JP' => 'Япония',
 			'KE' => 'Кения',
 			'KG' => 'Кыргызстан',
 			'KH' => 'Камбоджа',
 			'KI' => 'Кирибати',
 			'KM' => 'Комор утраулары',
 			'KN' => 'Сент-Китс һәм Невис',
 			'KP' => 'Төньяк Корея',
 			'KW' => 'Күвәйт',
 			'KY' => 'Кайман утраулары',
 			'KZ' => 'Казахстан',
 			'LA' => 'Лаос',
 			'LB' => 'Ливан',
 			'LC' => 'Сент-Люсия',
 			'LI' => 'Лихтенштейн',
 			'LK' => 'Шри-Ланка',
 			'LR' => 'Либерия',
 			'LS' => 'Лесото',
 			'LT' => 'Литва',
 			'LU' => 'Люксембург',
 			'LV' => 'Латвия',
 			'LY' => 'Ливия',
 			'MA' => 'Марокко',
 			'MC' => 'Монако',
 			'MD' => 'Молдова',
 			'ME' => 'Черногория',
 			'MF' => 'Сент-Мартин',
 			'MG' => 'Мадагаскар',
 			'MH' => 'Маршалл утраулары',
 			'MK@alt=variant' => 'Македония (Македония Элекке Югославия Республикасы)',
 			'ML' => 'Мали',
 			'MN' => 'Монголия',
 			'MO' => 'Макао Махсус Идарәле Төбәге',
 			'MO@alt=short' => 'Макао',
 			'MP' => 'Төньяк Мариана утраулары',
 			'MQ' => 'Мартиника',
 			'MR' => 'Мавритания',
 			'MS' => 'Монтсеррат',
 			'MT' => 'Мальта',
 			'MU' => 'Маврикий',
 			'MV' => 'Мальдив утраулары',
 			'MW' => 'Малави',
 			'MX' => 'Мексика',
 			'MY' => 'Малайзия',
 			'MZ' => 'Мозамбик',
 			'NA' => 'Намибия',
 			'NC' => 'Яңа Каледония',
 			'NE' => 'Нигер',
 			'NF' => 'Норфолк утравы',
 			'NG' => 'Нигерия',
 			'NI' => 'Никарагуа',
 			'NL' => 'Нидерланд',
 			'NO' => 'Норвегия',
 			'NP' => 'Непал',
 			'NR' => 'Науру',
 			'NU' => 'Ниуэ',
 			'NZ' => 'Яңа Зеландия',
 			'OM' => 'Оман',
 			'PA' => 'Панама',
 			'PE' => 'Перу',
 			'PF' => 'Француз Полинезиясе',
 			'PG' => 'Папуа - Яңа Гвинея',
 			'PH' => 'Филиппин',
 			'PK' => 'Пакистан',
 			'PL' => 'Польша',
 			'PM' => 'Сен-Пьер һәм Микелон',
 			'PN' => 'Питкэрн утраулары',
 			'PR' => 'Пуэрто-Рико',
 			'PT' => 'Португалия',
 			'PW' => 'Палау',
 			'PY' => 'Парагвай',
 			'QA' => 'Катар',
 			'RE' => 'Реюньон',
 			'RO' => 'Румыния',
 			'RS' => 'Сербия',
 			'RU' => 'Россия',
 			'RW' => 'Руанда',
 			'SA' => 'Согуд Гарәбстаны',
 			'SB' => 'Сөләйман утраулары',
 			'SC' => 'Сейшел утраулары',
 			'SD' => 'Судан',
 			'SE' => 'Швеция',
 			'SG' => 'Сингапур',
 			'SI' => 'Словения',
 			'SJ' => 'Шпицберген һәм Ян-Майен',
 			'SK' => 'Словакия',
 			'SL' => 'Сьерра-Леоне',
 			'SM' => 'Сан-Марино',
 			'SN' => 'Сенегал',
 			'SO' => 'Сомали',
 			'SR' => 'Суринам',
 			'SS' => 'Көньяк Судан',
 			'ST' => 'Сан-Томе һәм Принсипи',
 			'SV' => 'Сальвадор',
 			'SX' => 'Синт-Мартен',
 			'SY' => 'Сүрия',
 			'SZ' => 'Свазиленд',
 			'TC' => 'Теркс һәм Кайкос утраулары',
 			'TD' => 'Чад',
 			'TF' => 'Франциянең Көньяк Территорияләре',
 			'TG' => 'Того',
 			'TH' => 'Тайланд',
 			'TJ' => 'Таҗикстан',
 			'TK' => 'Токелау',
 			'TL' => 'Тимор-Лесте',
 			'TM' => 'Төркмәнстан',
 			'TN' => 'Тунис',
 			'TO' => 'Тонга',
 			'TR' => 'Төркия',
 			'TT' => 'Тринидад һәм Тобаго',
 			'TV' => 'Тувалу',
 			'TW' => 'Тайвань',
 			'TZ' => 'Танзания',
 			'UA' => 'Украина',
 			'UG' => 'Уганда',
 			'UM' => 'АКШ Кече Читтәге утраулары',
 			'US' => 'АКШ',
 			'UY' => 'Уругвай',
 			'UZ' => 'Үзбәкстан',
 			'VC' => 'Сент-Винсент һәм Гренадин',
 			'VE' => 'Венесуэла',
 			'VG' => 'Британия Виргин утраулары',
 			'VI' => 'АКШ Виргин утраулары',
 			'VN' => 'Вьетнам',
 			'VU' => 'Вануату',
 			'WF' => 'Уоллис һәм Футуна',
 			'WS' => 'Самоа',
 			'XK' => 'Косово',
 			'YE' => 'Йәмән',
 			'YT' => 'Майотта',
 			'ZA' => 'Көньяк Африка',
 			'ZM' => 'Замбия',
 			'ZW' => 'Зимбабве',
 			'ZZ' => 'билгесез төбәк',

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
 				'gregorian' => q{григориан ел исәбе},
 			},
 			'collation' => {
 				'standard' => q{гадәти тәртипләү ысулы},
 			},
 			'numbers' => {
 				'latn' => q{көнбатыш цифрлары},
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
			'metric' => q{метрик},
 			'UK' => q{Бөекбритания},
 			'US' => q{АКШ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Тел: {0}',
 			'script' => 'Язу: {0}',
 			'region' => 'Төбәк: {0}',

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
			auxiliary => qr{[ғ қ ӯ]},
			index => ['А', 'Ә', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'Җ', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'Ң', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Һ', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'],
			main => qr{[а ә б в г д е ё ж җ з и й к л м н ң о ө п р с т у ү ф х һ ц ч ш щ ъ ы ь э ю я]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Ә', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'Җ', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'Ң', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Һ', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
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
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:әйе|әйе|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:юк|юк|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} һәм {1}),
				2 => q({0} һәм {1}),
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
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
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
					'default' => '#,##0 %',
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
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Бразилия реалы),
				'other' => q(Бразилия реалы),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Кытай юане),
				'other' => q(юань),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(евро),
				'other' => q(евро),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(фунт стерлинг),
				'other' => q(фунт стерлинг),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Индия рупиясе),
				'other' => q(Индия рупиясе),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Япония иенасы),
				'other' => q(иена),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(Россия сумы),
				'other' => q(сум),
			},
		},
		'RUR' => {
			symbol => 'р.',
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(АКШ доллары),
				'other' => q(АКШ доллары),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(билгесез валюта),
				'other' => q(\(билгесез валюта\)),
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
							'гыйн.',
							'фев.',
							'мар.',
							'апр.',
							'май',
							'июнь',
							'июль',
							'авг.',
							'сент.',
							'окт.',
							'нояб.',
							'дек.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'гыйнвар',
							'февраль',
							'март',
							'апрель',
							'май',
							'июнь',
							'июль',
							'август',
							'сентябрь',
							'октябрь',
							'ноябрь',
							'декабрь'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'гыйн.',
							'фев.',
							'мар.',
							'апр.',
							'май',
							'июнь',
							'июль',
							'авг.',
							'сент.',
							'окт.',
							'нояб.',
							'дек.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'гыйнвар',
							'февраль',
							'март',
							'апрель',
							'май',
							'июнь',
							'июль',
							'август',
							'сентябрь',
							'октябрь',
							'ноябрь',
							'декабрь'
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
						mon => 'дүш.',
						tue => 'сиш.',
						wed => 'чәр.',
						thu => 'пәнҗ.',
						fri => 'җом.',
						sat => 'шим.',
						sun => 'якш.'
					},
					narrow => {
						mon => 'Д',
						tue => 'С',
						wed => 'Ч',
						thu => 'П',
						fri => 'Җ',
						sat => 'Ш',
						sun => 'Я'
					},
					short => {
						mon => 'дүш.',
						tue => 'сиш.',
						wed => 'чәр.',
						thu => 'пәнҗ.',
						fri => 'җом.',
						sat => 'шим.',
						sun => 'якш.'
					},
					wide => {
						mon => 'дүшәмбе',
						tue => 'сишәмбе',
						wed => 'чәршәмбе',
						thu => 'пәнҗешәмбе',
						fri => 'җомга',
						sat => 'шимбә',
						sun => 'якшәмбе'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'дүш.',
						tue => 'сиш.',
						wed => 'чәр.',
						thu => 'пәнҗ.',
						fri => 'җом.',
						sat => 'шим.',
						sun => 'якш.'
					},
					narrow => {
						mon => 'Д',
						tue => 'С',
						wed => 'Ч',
						thu => 'П',
						fri => 'Җ',
						sat => 'Ш',
						sun => 'Я'
					},
					short => {
						mon => 'дүш.',
						tue => 'сиш.',
						wed => 'чәр.',
						thu => 'пәнҗ.',
						fri => 'җом.',
						sat => 'шим.',
						sun => 'якш.'
					},
					wide => {
						mon => 'дүшәмбе',
						tue => 'сишәмбе',
						wed => 'чәршәмбе',
						thu => 'пәнҗешәмбе',
						fri => 'җомга',
						sat => 'шимбә',
						sun => 'якшәмбе'
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
					abbreviated => {0 => '1 нче кв.',
						1 => '2 нче кв.',
						2 => '3 нче кв.',
						3 => '4 нче кв.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1 нче квартал',
						1 => '2 нче квартал',
						2 => '3 нче квартал',
						3 => '4 нче квартал'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1 нче кв.',
						1 => '2 нче кв.',
						2 => '3 нче кв.',
						3 => '4 нче кв.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1 нче квартал',
						1 => '2 нче квартал',
						2 => '3 нче квартал',
						3 => '4 нче квартал'
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
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
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
				'0' => 'б.э.к.',
				'1' => 'б.э.'
			},
			wide => {
				'0' => 'безнең эрага кадәр',
				'1' => 'безнең эра'
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
			'full' => q{d MMMM, y 'ел' (G), EEEE},
			'long' => q{d MMMM, y 'ел' (G)},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.y GGGGG},
		},
		'gregorian' => {
			'full' => q{d MMMM, y 'ел', EEEE},
			'long' => q{d MMMM, y 'ел'},
			'medium' => q{d MMM, y 'ел'},
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
			'full' => q{H:mm:ss zzzz},
			'long' => q{H:mm:ss z},
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Gy => q{G y 'ел'},
			GyMMM => q{G y 'ел', MMM},
			GyMMMEd => q{E, G d MMM y 'ел'},
			GyMMMd => q{G d MMM y 'ел'},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{MMMM 'аеның' W 'атнасы'},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM.y},
			yMEd => q{E, dd.MM.y},
			yMMM => q{MMM, y 'ел'},
			yMMMEd => q{E, d MMM, y 'ел'},
			yMMMM => q{MMMM, y 'ел'},
			yMMMd => q{d MMM, y 'ел'},
			yMd => q{dd.MM.y},
			yQQQ => q{QQQ, y 'ел'},
			yQQQQ => q{QQQQ, y 'ел'},
			yw => q{Y 'елның' w 'атнасы'},
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
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
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
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM – MMM, y 'ел'},
				y => q{MMM, y 'ел' - MMM, y 'ел'},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y 'ел'},
				d => q{E, d MMM – E, d MMM, y 'ел'},
				y => q{E, d MMM, y 'ел' – E, d MMM, y 'ел'},
			},
			yMMMM => {
				M => q{MMMM – MMMM, y 'ел'},
				y => q{MMMM, y 'ел' – MMMM, y 'ел'},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y 'ел'},
				d => q{d–d MMM, y 'ел'},
				y => q{d MMM, y 'ел' – d MMM, y 'ел'},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
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
		regionFormat => q({0} вакыты),
		regionFormat => q({0} җәйге вакыты),
		regionFormat => q({0} гадәти вакыты),
		fallbackFormat => q({1} ({0})),
		'America_Central' => {
			long => {
				'daylight' => q#Төньяк Америка җәйге үзәк вакыты#,
				'generic' => q#Төньяк Америка үзәк вакыты#,
				'standard' => q#Төньяк Америка гадәти үзәк вакыты#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Төньяк Америка җәйге көнчыгыш вакыты#,
				'generic' => q#Төньяк Америка көнчыгыш вакыты#,
				'standard' => q#Төньяк Америка гадәти көнчыгыш вакыты#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Төньяк Америка җәйге тау вакыты#,
				'generic' => q#Төньяк Америка тау вакыты#,
				'standard' => q#Төньяк Америка гадәти тау вакыты#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Төньяк Америка җәйге Тын океан вакыты#,
				'generic' => q#Төньяк Америка Тын океан вакыты#,
				'standard' => q#Төньяк Америка гадәти Тын океан вакыты#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Төньяк Америка җәйге атлантик вакыты#,
				'generic' => q#Төньяк Америка атлантик вакыты#,
				'standard' => q#Төньяк Америка гадәти атлантик вакыты#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Бөтендөнья килештерелгән вакыты#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#билгесез шәһәр#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#җәйге Үзәк Европа вакыты#,
				'generic' => q#Үзәк Европа вакыты#,
				'standard' => q#гадәти Үзәк Европа вакыты#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#җәйге Көнчыгыш Европа вакыты#,
				'generic' => q#Көнчыгыш Европа вакыты#,
				'standard' => q#гадәти Көнчыгыш Европа вакыты#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#җәйге Көнбатыш Европа вакыты#,
				'generic' => q#Көнбатыш Европа вакыты#,
				'standard' => q#гадәти Көнбатыш Европа вакыты#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Гринвич уртача вакыты#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
