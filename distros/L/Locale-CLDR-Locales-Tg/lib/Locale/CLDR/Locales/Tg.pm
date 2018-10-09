=encoding utf8

=head1

Locale::CLDR::Locales::Tg - Package for language Tajik

=cut

package Locale::CLDR::Locales::Tg;
# This file auto generated from Data\common\main\tg.xml
#	on Sun  7 Oct 11:01:46 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
 				'am' => 'амҳарӣ',
 				'ar' => 'арабӣ',
 				'as' => 'ассомӣ',
 				'az' => 'озарбойҷонӣ',
 				'ba' => 'бошқирдӣ',
 				'ban' => 'балинӣ',
 				'be' => 'белорусӣ',
 				'bem' => 'бемба',
 				'bg' => 'булғорӣ',
 				'bn' => 'бинғолӣ',
 				'bo' => 'тибетӣ',
 				'br' => 'бретонӣ',
 				'bs' => 'босниягӣ',
 				'ca' => 'каталонӣ',
 				'ceb' => 'себуано',
 				'chm' => 'марӣ',
 				'chr' => 'черокӣ',
 				'ckb' => 'курдии марказӣ',
 				'co' => 'корсиканӣ',
 				'cs' => 'чехӣ',
 				'cy' => 'валлӣ',
 				'da' => 'даниягӣ',
 				'de' => 'немисӣ',
 				'dsb' => 'сербии поёнӣ',
 				'dv' => 'дивеҳӣ',
 				'dz' => 'дзонгха',
 				'el' => 'юнонӣ',
 				'en' => 'англисӣ',
 				'en_GB@alt=short' => 'англисӣ (ШМ)',
 				'en_US@alt=short' => 'англисӣ (ИМ)',
 				'eo' => 'эсперанто',
 				'es' => 'испанӣ',
 				'es_419' => 'испанӣ (Америкаи Лотинӣ)',
 				'et' => 'эстонӣ',
 				'eu' => 'баскӣ',
 				'fa' => 'форсӣ',
 				'ff' => 'фулаҳ',
 				'fi' => 'финӣ',
 				'fil' => 'филиппинӣ',
 				'fo' => 'фарерӣ',
 				'fr' => 'франсузӣ',
 				'fy' => 'фризии ғарбӣ',
 				'ga' => 'ирландӣ',
 				'gd' => 'шотландии гэлӣ',
 				'gl' => 'галисиягӣ',
 				'gn' => 'гуаранӣ',
 				'gu' => 'гуҷаротӣ',
 				'ha' => 'ҳауса',
 				'haw' => 'ҳавайӣ',
 				'he' => 'ибронӣ',
 				'hi' => 'ҳиндӣ',
 				'hil' => 'ҳилигайнон',
 				'hr' => 'хорватӣ',
 				'hsb' => 'сербии болоӣ',
 				'ht' => 'гаитии креолӣ',
 				'hu' => 'маҷорӣ',
 				'hy' => 'арманӣ',
 				'hz' => 'ҳереро',
 				'ia' => 'Байни забонӣ',
 				'ibb' => 'ибибио',
 				'id' => 'индонезӣ',
 				'ig' => 'игбо',
 				'is' => 'исландӣ',
 				'it' => 'италиявӣ',
 				'iu' => 'инуктитутӣ',
 				'ja' => 'японӣ',
 				'jv' => 'Ҷаванизӣ',
 				'ka' => 'гурҷӣ',
 				'kk' => 'қазоқӣ',
 				'km' => 'кхмерӣ',
 				'kn' => 'каннада',
 				'ko' => 'кореягӣ',
 				'kok' => 'конканӣ',
 				'kr' => 'канурӣ',
 				'kru' => 'курукс',
 				'ks' => 'кашмирӣ',
 				'ku' => 'курдӣ',
 				'ky' => 'қирғизӣ',
 				'la' => 'лотинӣ',
 				'lb' => 'люксембургӣ',
 				'lo' => 'лаосӣ',
 				'lt' => 'литвонӣ',
 				'lv' => 'латишӣ',
 				'men' => 'менде',
 				'mg' => 'малагасӣ',
 				'mi' => 'маорӣ',
 				'mk' => 'мақдунӣ',
 				'ml' => 'малаяламӣ',
 				'mn' => 'муғулӣ',
 				'mni' => 'манипурӣ',
 				'moh' => 'моҳок',
 				'mr' => 'маратҳӣ',
 				'ms' => 'малайӣ',
 				'mt' => 'малтӣ',
 				'my' => 'бирманӣ',
 				'ne' => 'непалӣ',
 				'niu' => 'ниуэӣ',
 				'nl' => 'голландӣ',
 				'no' => 'норвегӣ',
 				'ny' => 'нянҷа',
 				'oc' => 'окситанӣ',
 				'om' => 'оромо',
 				'or' => 'одия',
 				'pa' => 'панҷобӣ',
 				'pap' => 'папиаменто',
 				'pl' => 'лаҳистонӣ',
 				'ps' => 'пушту',
 				'pt' => 'португалӣ',
 				'qu' => 'кечуа',
 				'quc' => 'киче',
 				'rm' => 'ретороманӣ',
 				'ro' => 'руминӣ',
 				'ru' => 'русӣ',
 				'rw' => 'киняруанда',
 				'sa' => 'санскрит',
 				'sah' => 'саха',
 				'sat' => 'санталӣ',
 				'sd' => 'синдӣ',
 				'se' => 'самии шимолӣ',
 				'si' => 'сингалӣ',
 				'sk' => 'словакӣ',
 				'sl' => 'словенӣ',
 				'sma' => 'самии ҷанубӣ',
 				'smj' => 'луле самӣ',
 				'smn' => 'инари самӣ',
 				'sms' => 'сколти самӣ',
 				'so' => 'сомалӣ',
 				'sq' => 'албанӣ',
 				'sr' => 'сербӣ',
 				'sv' => 'шведӣ',
 				'syr' => 'суриёнӣ',
 				'ta' => 'тамилӣ',
 				'te' => 'телугу',
 				'tg' => 'тоҷикӣ',
 				'th' => 'тайӣ',
 				'ti' => 'тигриня',
 				'tk' => 'туркманӣ',
 				'to' => 'тонганӣ',
 				'tr' => 'туркӣ',
 				'tt' => 'тоторӣ',
 				'tzm' => 'тамазайти атласи марказӣ',
 				'ug' => 'ӯйғурӣ',
 				'uk' => 'украинӣ',
 				'und' => 'забони номаълум',
 				'ur' => 'урду',
 				'uz' => 'ӯзбекӣ',
 				've' => 'венда',
 				'vi' => 'ветнамӣ',
 				'wo' => 'волоф',
 				'yi' => 'идиш',
 				'yo' => 'йоруба',
 				'zh' => 'хитоӣ',
 				'zh_Hans' => 'хитоии осонфаҳм',
 				'zh_Hant' => 'хитоии анъанавӣ',
 				'zu' => 'Зулу',

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
			'Arab' => 'Арабӣ',
 			'Cyrl' => 'Кириллӣ',
 			'Hans' => 'Осонфаҳм',
 			'Hans@alt=stand-alone' => 'Хани осонфаҳм',
 			'Hant' => 'Анъанавӣ',
 			'Hant@alt=stand-alone' => 'Хани анъанавӣ',
 			'Latn' => 'Лотинӣ',
 			'Zxxx' => 'Нонавишта',
 			'Zzzz' => 'Скрипти номаълум',

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
			'AC' => 'Асунсон',
 			'AD' => 'Андорра',
 			'AE' => 'Аморатҳои Муттаҳидаи Араб',
 			'AF' => 'Афғонистон',
 			'AG' => 'Антигуа ва Барбуда',
 			'AI' => 'Ангилия',
 			'AL' => 'Албания',
 			'AM' => 'Арманистон',
 			'AO' => 'Ангола',
 			'AQ' => 'Антарктида',
 			'AR' => 'Аргентина',
 			'AS' => 'Самоаи Америка',
 			'AT' => 'Австрия',
 			'AU' => 'Австралия',
 			'AW' => 'Аруба',
 			'AX' => 'Ҷазираҳои Аланд',
 			'AZ' => 'Озарбойҷон',
 			'BA' => 'Босния ва Ҳерсеговина',
 			'BB' => 'Барбадос',
 			'BD' => 'Бангладеш',
 			'BE' => 'Белгия',
 			'BF' => 'Буркина-Фасо',
 			'BG' => 'Булғория',
 			'BH' => 'Баҳрайн',
 			'BI' => 'Бурунди',
 			'BJ' => 'Бенин',
 			'BL' => 'Сент-Бартелми',
 			'BM' => 'Бермуда',
 			'BN' => 'Бруней',
 			'BO' => 'Боливия',
 			'BR' => 'Бразилия',
 			'BS' => 'Багам',
 			'BT' => 'Бутон',
 			'BV' => 'Ҷазираи Буве',
 			'BW' => 'Ботсвана',
 			'BY' => 'Белорус',
 			'BZ' => 'Белиз',
 			'CA' => 'Канада',
 			'CC' => 'Ҷазираҳои Кокос (Килинг)',
 			'CD@alt=variant' => 'Конго (ҶДК)',
 			'CF' => 'Ҷумҳурии Африқои Марказӣ',
 			'CG@alt=variant' => 'Конго',
 			'CH' => 'Швейтсария',
 			'CI' => 'Кот-д’Ивуар',
 			'CK' => 'Ҷазираҳои Кук',
 			'CL' => 'Чили',
 			'CM' => 'Камерун',
 			'CN' => 'Хитой',
 			'CO' => 'Колумбия',
 			'CR' => 'Коста-Рика',
 			'CU' => 'Куба',
 			'CV' => 'Кабо-Верде',
 			'CW' => 'Кюрасао',
 			'CX' => 'Ҷазираи Крисмас',
 			'CY' => 'Кипр',
 			'CZ' => 'Ҷумҳурии Чех',
 			'DE' => 'Германия',
 			'DJ' => 'Ҷибути',
 			'DK' => 'Дания',
 			'DM' => 'Доминика',
 			'DO' => 'Ҷумҳурии Доминикан',
 			'DZ' => 'Алҷазоир',
 			'EC' => 'Эквадор',
 			'EE' => 'Эстония',
 			'EG' => 'Миср',
 			'ER' => 'Эритрея',
 			'ES' => 'Испания',
 			'ET' => 'Эфиопия',
 			'FI' => 'Финляндия',
 			'FJ' => 'Фиҷи',
 			'FK' => 'Ҷазираҳои Фолкленд',
 			'FM' => 'Штатҳои Федеративии Микронезия',
 			'FO' => 'Ҷазираҳои Фарер',
 			'FR' => 'Франсия',
 			'GA' => 'Габон',
 			'GB' => 'Шоҳигарии Муттаҳида',
 			'GD' => 'Гренада',
 			'GE' => 'Гурҷистон',
 			'GF' => 'Гвианаи Фаронса',
 			'GG' => 'Гернси',
 			'GH' => 'Гана',
 			'GI' => 'Гибралтар',
 			'GL' => 'Гренландия',
 			'GM' => 'Гамбия',
 			'GN' => 'Гвинея',
 			'GP' => 'Гваделупа',
 			'GQ' => 'Гвинеяи Экваторӣ',
 			'GR' => 'Юнон',
 			'GS' => 'Ҷорҷияи Ҷанубӣ ва Ҷазираҳои Сандвич',
 			'GT' => 'Гватемала',
 			'GU' => 'Гуам',
 			'GW' => 'Гвинея-Бисау',
 			'GY' => 'Гайана',
 			'HK' => 'Ҳонконг (МММ)',
 			'HK@alt=short' => 'Ҳонконг',
 			'HM' => 'Ҷазираи Ҳерд ва Ҷазираҳои Макдоналд',
 			'HN' => 'Гондурас',
 			'HR' => 'Хорватия',
 			'HT' => 'Гаити',
 			'HU' => 'Маҷористон',
 			'ID' => 'Индонезия',
 			'IE' => 'Ирландия',
 			'IL' => 'Исроил',
 			'IM' => 'Ҷазираи Мэн',
 			'IN' => 'Ҳиндустон',
 			'IO' => 'Қаламрави Британия дар уқёнуси Ҳинд',
 			'IQ' => 'Ироқ',
 			'IR' => 'Эрон',
 			'IS' => 'Исландия',
 			'IT' => 'Италия',
 			'JE' => 'Ҷерси',
 			'JM' => 'Ямайка',
 			'JO' => 'Урдун',
 			'JP' => 'Япония',
 			'KE' => 'Кения',
 			'KG' => 'Қирғизистон',
 			'KH' => 'Камбоҷа',
 			'KI' => 'Кирибати',
 			'KM' => 'Комор',
 			'KN' => 'Сент-Китс ва Невис',
 			'KP' => 'Кореяи Шимолӣ',
 			'KW' => 'Қувайт',
 			'KY' => 'Ҷазираҳои Кайман',
 			'KZ' => 'Қазоқистон',
 			'LA' => 'Лаос',
 			'LB' => 'Лубнон',
 			'LC' => 'Сент-Люсия',
 			'LI' => 'Лихтенштейн',
 			'LK' => 'Шри-Ланка',
 			'LR' => 'Либерия',
 			'LS' => 'Лесото',
 			'LT' => 'Литва',
 			'LU' => 'Люксембург',
 			'LV' => 'Латвия',
 			'LY' => 'Либия',
 			'MA' => 'Марокаш',
 			'MC' => 'Монако',
 			'MD' => 'Молдова',
 			'ME' => 'Черногория',
 			'MF' => 'Ҷазираи Сент-Мартин',
 			'MG' => 'Мадагаскар',
 			'MH' => 'Ҷазираҳои Маршалл',
 			'MK' => 'Мақдун',
 			'MK@alt=variant' => 'Мақдун (ҶСЮМ)',
 			'ML' => 'Мали',
 			'MM' => 'Мянма',
 			'MN' => 'Муғулистон',
 			'MO' => 'Макао (МММ)',
 			'MO@alt=short' => 'Макао',
 			'MP' => 'Ҷазираҳои Марианаи Шимолӣ',
 			'MQ' => 'Мартиника',
 			'MR' => 'Мавритания',
 			'MS' => 'Монтсеррат',
 			'MT' => 'Малта',
 			'MU' => 'Маврикий',
 			'MV' => 'Малдив',
 			'MW' => 'Малави',
 			'MX' => 'Мексика',
 			'MY' => 'Малайзия',
 			'MZ' => 'Мозамбик',
 			'NA' => 'Намибия',
 			'NC' => 'Каледонияи Нав',
 			'NE' => 'Нигер',
 			'NF' => 'Ҷазираи Норфолк',
 			'NG' => 'Нигерия',
 			'NI' => 'Никарагуа',
 			'NL' => 'Нидерландия',
 			'NO' => 'Норвегия',
 			'NP' => 'Непал',
 			'NR' => 'Науру',
 			'NU' => 'Ниуэ',
 			'NZ' => 'Зеландияи Нав',
 			'OM' => 'Умон',
 			'PA' => 'Панама',
 			'PE' => 'Перу',
 			'PF' => 'Полинезияи Фаронса',
 			'PG' => 'Папуа Гвинеяи Нав',
 			'PH' => 'Филиппин',
 			'PK' => 'Покистон',
 			'PL' => 'Лаҳистон',
 			'PM' => 'Сент-Пер ва Микелон',
 			'PN' => 'Ҷазираҳои Питкейрн',
 			'PR' => 'Пуэрто-Рико',
 			'PT' => 'Португалия',
 			'PW' => 'Палау',
 			'PY' => 'Парагвай',
 			'QA' => 'Қатар',
 			'RE' => 'Реюнион',
 			'RO' => 'Руминия',
 			'RS' => 'Сербия',
 			'RU' => 'Русия',
 			'RW' => 'Руанда',
 			'SA' => 'Арабистони Саудӣ',
 			'SB' => 'Ҷазираҳои Соломон',
 			'SC' => 'Сейшел',
 			'SD' => 'Судон',
 			'SE' => 'Шветсия',
 			'SG' => 'Сингапур',
 			'SH' => 'Сент Елена',
 			'SI' => 'Словения',
 			'SJ' => 'Шпитсберген ва Ян Майен',
 			'SK' => 'Словакия',
 			'SL' => 'Сиерра-Леоне',
 			'SM' => 'Сан-Марино',
 			'SN' => 'Сенегал',
 			'SO' => 'Сомалӣ',
 			'SR' => 'Суринам',
 			'SS' => 'Судони Ҷанубӣ',
 			'ST' => 'Сан Томе ва Принсипи',
 			'SV' => 'Эл-Салвадор',
 			'SX' => 'Синт-Маартен',
 			'SY' => 'Сурия',
 			'SZ' => 'Свазиленд',
 			'TA' => 'Тристан-да-Куня',
 			'TC' => 'Ҷазираҳои Теркс ва Кайкос',
 			'TD' => 'Чад',
 			'TF' => 'Минтақаҳои Ҷанубии Фаронса',
 			'TG' => 'Того',
 			'TH' => 'Таиланд',
 			'TJ' => 'Тоҷикистон',
 			'TK' => 'Токелау',
 			'TL' => 'Тимор-Лесте',
 			'TM' => 'Туркманистон',
 			'TN' => 'Тунис',
 			'TO' => 'Тонга',
 			'TR' => 'Туркия',
 			'TT' => 'Тринидад ва Тобаго',
 			'TV' => 'Тувалу',
 			'TW' => 'Тайван',
 			'TZ' => 'Танзания',
 			'UA' => 'Украина',
 			'UG' => 'Уганда',
 			'UM' => 'Ҷазираҳои Хурди Дурдасти ИМА',
 			'US' => 'Иёлоти Муттаҳида',
 			'US@alt=short' => 'ИМ',
 			'UY' => 'Уругвай',
 			'UZ' => 'Ӯзбекистон',
 			'VA' => 'Шаҳри Вотикон',
 			'VC' => 'Сент-Винсент ва Гренадина',
 			'VE' => 'Венесуэла',
 			'VG' => 'Ҷазираҳои Виргини Британия',
 			'VI' => 'Ҷазираҳои Виргини ИМА',
 			'VN' => 'Ветнам',
 			'VU' => 'Вануату',
 			'WF' => 'Уоллис ва Футуна',
 			'WS' => 'Самоа',
 			'XK' => 'Косово',
 			'YE' => 'Яман',
 			'YT' => 'Майотта',
 			'ZA' => 'Африкаи Ҷанубӣ',
 			'ZM' => 'Замбия',
 			'ZW' => 'Зимбабве',
 			'ZZ' => 'Минтақаи номаълум',

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
 				'gregorian' => q{Тақвими грегорианӣ},
 			},
 			'collation' => {
 				'standard' => q{Тартиби мураттабсозии стандартӣ},
 			},
 			'numbers' => {
 				'arab' => q{Рақамҳои ҳинду-арабӣ},
 				'latn' => q{Рақамҳои ғарбӣ},
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
			'metric' => q{Метрӣ},
 			'UK' => q{БК},
 			'US' => q{ИМА},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

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
			auxiliary => qr{[ц щ ы ь]},
			index => ['А', 'Б', 'В', 'Г', 'Ғ', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'К', 'Қ', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ҳ', 'Ч', 'Ҷ', 'Ш', 'Ъ', 'Э', 'Ю', 'Я'],
			main => qr{[а б в г ғ д е ё ж з и ӣ й к қ л м н о п р с т у ӯ ф х ҳ ч ҷ ш ъ э ю я]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'В', 'Г', 'Ғ', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'К', 'Қ', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ҳ', 'Ч', 'Ҷ', 'Ш', 'Ъ', 'Э', 'Ю', 'Я'], };
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
	default		=> qq{«},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
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
	default		=> sub { qr'^(?i:ҳа|ҳ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:не|н|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
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
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Реали бразилиягӣ),
				'other' => q(реали бразилиягӣ),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Иенаи хитоӣ),
				'other' => q(иенаи хитоӣ),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Евро),
				'other' => q(евро),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Фунт стерлинги британӣ),
				'other' => q(фунт стерлинги британӣ),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Рупияи ҳиндустонӣ),
				'other' => q(рупияи ҳиндустонӣ),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Иенаи японӣ),
				'other' => q(иенаи японӣ),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Рубли русӣ),
				'other' => q(рубли русӣ),
			},
		},
		'TJS' => {
			symbol => 'сом.',
			display_name => {
				'currency' => q(Сомонӣ),
				'other' => q(Сомонӣ),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Доллари ИМА),
				'other' => q(доллари ИМА),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Асъори номаълум),
				'other' => q(\(асъори номаълум\)),
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
							'Янв',
							'Фев',
							'Мар',
							'Апр',
							'Май',
							'Июн',
							'Июл',
							'Авг',
							'Сен',
							'Окт',
							'Ноя',
							'Дек'
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
							'Январ',
							'Феврал',
							'Март',
							'Апрел',
							'Май',
							'Июн',
							'Июл',
							'Август',
							'Сентябр',
							'Октябр',
							'Ноябр',
							'Декабр'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Янв',
							'Фев',
							'Мар',
							'Апр',
							'Май',
							'Июн',
							'Июл',
							'Авг',
							'Сен',
							'Окт',
							'Ноя',
							'Дек'
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
							'Январ',
							'Феврал',
							'Март',
							'Апрел',
							'Май',
							'Июн',
							'Июл',
							'Август',
							'Сентябр',
							'Октябр',
							'Ноябр',
							'Декабр'
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
						mon => 'Дшб',
						tue => 'Сшб',
						wed => 'Чшб',
						thu => 'Пшб',
						fri => 'Ҷмъ',
						sat => 'Шнб',
						sun => 'Яшб'
					},
					narrow => {
						mon => 'Д',
						tue => 'С',
						wed => 'Ч',
						thu => 'П',
						fri => 'Ҷ',
						sat => 'Ш',
						sun => 'Я'
					},
					short => {
						mon => 'Дшб',
						tue => 'Сшб',
						wed => 'Чшб',
						thu => 'Пшб',
						fri => 'Ҷмъ',
						sat => 'Шнб',
						sun => 'Яшб'
					},
					wide => {
						mon => 'Душанбе',
						tue => 'Сешанбе',
						wed => 'Чоршанбе',
						thu => 'Панҷшанбе',
						fri => 'Ҷумъа',
						sat => 'Шанбе',
						sun => 'Якшанбе'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Дшб',
						tue => 'Сшб',
						wed => 'Чшб',
						thu => 'Пшб',
						fri => 'Ҷмъ',
						sat => 'Шнб',
						sun => 'Яшб'
					},
					narrow => {
						mon => 'Д',
						tue => 'С',
						wed => 'Ч',
						thu => 'П',
						fri => 'Ҷ',
						sat => 'Ш',
						sun => 'Я'
					},
					short => {
						mon => 'Дшб',
						tue => 'Сшб',
						wed => 'Чшб',
						thu => 'Пшб',
						fri => 'Ҷмъ',
						sat => 'Шнб',
						sun => 'Яшб'
					},
					wide => {
						mon => 'Душанбе',
						tue => 'Сешанбе',
						wed => 'Чоршанбе',
						thu => 'Панҷшанбе',
						fri => 'Ҷумъа',
						sat => 'Шанбе',
						sun => 'Якшанбе'
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
					abbreviated => {0 => 'Ч1',
						1 => 'Ч2',
						2 => 'Ч3',
						3 => 'Ч4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Ч1',
						1 => 'Ч2',
						2 => 'Ч3',
						3 => 'Ч4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Ч1',
						1 => 'Ч2',
						2 => 'Ч3',
						3 => 'Ч4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Ч1',
						1 => 'Ч2',
						2 => 'Ч3',
						3 => 'Ч4'
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
					'am' => q{пе. чо.},
					'pm' => q{па. чо.},
				},
				'wide' => {
					'am' => q{пе. чо.},
					'pm' => q{па. чо.},
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
				'0' => 'ПеМ',
				'1' => 'ПаМ'
			},
			wide => {
				'0' => 'Пеш аз милод',
				'1' => 'ПаМ'
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
			'full' => q{EEEE, dd MMMM y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, dd MMMM y},
			'long' => q{dd MMMM y},
			'medium' => q{dd MMM y},
			'short' => q{dd/MM/yy},
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E, dd-MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM-y GGGGG},
			yyyyMEd => q{E, d-MM-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-MM-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, dd-MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{'ҳафтаи' W, MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM-y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM, y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'ҳафтаи' w, y},
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
			fallback => '{0} – {1}',
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
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'America_Central' => {
			long => {
				'daylight' => q#Вақти рӯзонаи марказӣ#,
				'generic' => q#Вақти марказӣ#,
				'standard' => q#Вақти стандартии марказӣ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Вақти рӯзонаи шарқӣ#,
				'generic' => q#Вақти шарқӣ#,
				'standard' => q#Вақти стандартии шарқӣ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Вақти рӯзонаи кӯҳӣ#,
				'generic' => q#Вақти кӯҳӣ#,
				'standard' => q#Вақти стандартии кӯҳӣ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Вақти рӯзонаи Уқёнуси Ором#,
				'generic' => q#Вақти Уёнуси Ором#,
				'standard' => q#Вақти стандартии Уқёнуси Ором#,
			},
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Душанбе#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Вақти рӯзонаи атлантикӣ#,
				'generic' => q#Вақти атлантикӣ#,
				'standard' => q#Вақти стандартии атлантикӣ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Вақти ҷаҳонии ҳамоҳангсозӣ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Шаҳри номаълум#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Вақти тобистонаи аврупоии марказӣ#,
				'generic' => q#Вақти аврупоии марказӣ#,
				'standard' => q#Вақти стандартии аврупоии марказӣ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Вақти тобистонаи аврупоии шарқӣ#,
				'generic' => q#Вақти аврупоии шарқӣ#,
				'standard' => q#Вақти стандартии аврупоии шарқӣ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Вақти тобистонаи аврупоии ғарбӣ#,
				'generic' => q#Вақти аврупоии ғарбӣ#,
				'standard' => q#Вақти стандартии аврупоии ғарбӣ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ба вақти Гринвич#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
