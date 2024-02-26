=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tg - Package for language Tajik

=cut

package Locale::CLDR::Locales::Tg;
# This file auto generated from Data\common\main\tg.xml
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
 				'cgg' => 'Чига',
 				'chm' => 'марӣ',
 				'chr' => 'черокӣ',
 				'ckb' => 'курдии марказӣ',
 				'co' => 'корсиканӣ',
 				'cs' => 'чехӣ',
 				'cy' => 'валлӣ',
 				'da' => 'даниягӣ',
 				'de' => 'немисӣ',
 				'de_AT' => 'немисии австриягӣ',
 				'de_CH' => 'немисии швейсарии болоӣ',
 				'dsb' => 'сербии поёнӣ',
 				'dv' => 'дивеҳӣ',
 				'dz' => 'дзонгха',
 				'el' => 'юнонӣ',
 				'en' => 'Англисӣ',
 				'en_AU' => 'англисии австралиягӣ',
 				'en_CA' => 'англисии канадагӣ',
 				'en_GB' => 'англисии британӣ',
 				'en_GB@alt=short' => 'англисӣ (ШМ)',
 				'en_US' => 'англисии америкоӣ',
 				'en_US@alt=short' => 'англисӣ (ИМ)',
 				'eo' => 'эсперанто',
 				'es' => 'испанӣ',
 				'es_419' => 'испании америкоии лотинӣ',
 				'es_ES' => 'испании аврупоӣ',
 				'es_MX' => 'испании мексикоӣ',
 				'et' => 'эстонӣ',
 				'eu' => 'баскӣ',
 				'fa' => 'форсӣ',
 				'ff' => 'фулаҳ',
 				'fi' => 'финӣ',
 				'fil' => 'филиппинӣ',
 				'fo' => 'фарерӣ',
 				'fr' => 'франсузӣ',
 				'fr_CA' => 'франсузии канадагӣ',
 				'fr_CH' => 'франсузии швейсарӣ',
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
 				'pt_BR' => 'португалии бразилиягӣ',
 				'pt_PT' => 'португалии аврупоӣ',
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
 				'tzm' => 'тамазайти Атласи Марказӣ',
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
 				'zh@alt=menu' => 'хитоӣ, мандаринӣ',
 				'zh_Hans' => 'хитоии осонфаҳм',
 				'zh_Hans@alt=long' => 'хитоии мандаринии осонфаҳм',
 				'zh_Hant' => 'хитоии анъанавӣ',
 				'zh_Hant@alt=long' => 'хитоии мандаринии анъанавӣ',
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
			'Adlm' => 'Адламӣ',
 			'Aghb' => 'Албани Қафқозӣ',
 			'Ahom' => 'Ахомӣ',
 			'Arab' => 'Арабӣ',
 			'Aran' => 'Насталиқӣ',
 			'Armi' => 'Арамейкии Империалӣ',
 			'Armn' => 'Арманӣ',
 			'Avst' => 'Авестоӣ',
 			'Bali' => 'Балинесӣ',
 			'Bamu' => 'Бамумӣ',
 			'Bass' => 'Басса Вахӣ',
 			'Batk' => 'Батакӣ',
 			'Beng' => 'Бангладешӣ',
 			'Bhks' => 'Бхайксукӣ',
 			'Bopo' => 'Бопомофоӣ',
 			'Brah' => 'Брахмӣ',
 			'Brai' => 'Брайл',
 			'Bugi' => 'Бугинӣ',
 			'Buhd' => 'Бухидӣ',
 			'Cakm' => 'Чакама',
 			'Cans' => 'Низоми ягонаи ҳиҷои аборигении каннадӣ',
 			'Cari' => 'Карианӣ',
 			'Cham' => 'Чамӣ',
 			'Cher' => 'Черокӣ',
 			'Chrs' => 'Хоразмиёнӣ',
 			'Copt' => 'Коптӣ',
 			'Cpmn' => 'Кипро-Миноанӣ',
 			'Cprt' => 'Кипрӣ',
 			'Cyrl' => 'Кириллӣ',
 			'Deva' => 'Деванагарӣ',
 			'Diak' => 'Дивс Акуру',
 			'Dogr' => 'Догра',
 			'Dsrt' => 'Дезерет',
 			'Dupl' => 'Стенографияи Дуплоянӣ',
 			'Egyp' => 'Иероглифҳои Мисрӣ',
 			'Elba' => 'Элбасан',
 			'Elym' => 'Элимайӣ',
 			'Ethi' => 'Эфиопӣ',
 			'Geor' => 'Гурҷӣ',
 			'Glag' => 'Глаголитикӣ',
 			'Gong' => 'Гунҷала Гондӣ',
 			'Gonm' => 'Масарам Гондӣ',
 			'Goth' => 'Готика',
 			'Gran' => 'Гранта',
 			'Grek' => 'Юнонӣ',
 			'Gujr' => 'Гуҷаротӣ',
 			'Guru' => 'Гумрухӣ',
 			'Hanb' => 'Хан бо Бопомофо',
 			'Hang' => 'Ҳангул',
 			'Hani' => 'Хан',
 			'Hano' => 'Хануну',
 			'Hans' => 'Осонфаҳм',
 			'Hans@alt=stand-alone' => 'Хани осонфаҳм',
 			'Hant' => 'Анъанавӣ',
 			'Hant@alt=stand-alone' => 'Хани анъанавӣ',
 			'Hatr' => 'Хатран',
 			'Hebr' => 'Яҳудӣ',
 			'Hira' => 'Хирагана',
 			'Hluw' => 'Иероглифҳои Анатолӣ',
 			'Hmng' => 'Пахах Хмонг',
 			'Hmnp' => 'Някенг Пуачэ Хмонг',
 			'Hrkt' => 'Ҳиҷоҳои ҷопонӣ',
 			'Hung' => 'Венгерии Куҳна',
 			'Ital' => 'Курсиви Куҳна',
 			'Jamo' => 'Ҷамо',
 			'Java' => 'Ҷаванесӣ',
 			'Jpan' => 'Ҷопонӣ',
 			'Kali' => 'Кайя Ли',
 			'Kana' => 'Катакана',
 			'Kawi' => 'Кавӣ',
 			'Khar' => 'Хароштӣ',
 			'Khmr' => 'Хмерӣ',
 			'Khoj' => 'Хочки',
 			'Kits' => 'Хатти хурди Китонӣ',
 			'Knda' => 'Каннада',
 			'Kore' => 'Кореягӣ',
 			'Kthi' => 'Кайтӣ',
 			'Lana' => 'Ланна',
 			'Laoo' => 'Лао',
 			'Latn' => 'Лотинӣ',
 			'Lepc' => 'Лепча',
 			'Limb' => 'Лимбу',
 			'Lina' => 'Хати А',
 			'Linb' => 'Хати Б',
 			'Lisu' => 'Фрейзер',
 			'Lyci' => 'Ликия',
 			'Lydi' => 'Лидия',
 			'Mahj' => 'Махаҷанӣ',
 			'Maka' => 'Макасарӣ',
 			'Mand' => 'Мандаеан',
 			'Mani' => 'Манихейӣ',
 			'Marc' => 'Маршенӣ',
 			'Medf' => 'Медефаидринӣ',
 			'Mend' => 'Менде',
 			'Merc' => 'Курсиви Мероитӣ',
 			'Mero' => 'Мероитӣ',
 			'Mlym' => 'Малаяламӣ',
 			'Modi' => 'Модӣ',
 			'Mong' => 'Муғулӣ',
 			'Mroo' => 'Мро',
 			'Mtei' => 'Мейтеи Майек',
 			'Mult' => 'Мултанӣ',
 			'Mymr' => 'Мянмар',
 			'Nagm' => 'Наг Мундарӣ',
 			'Nand' => 'Нандинагарӣ',
 			'Narb' => 'Арабии Шимолии Куҳна',
 			'Nbat' => 'Набатаинӣ',
 			'Newa' => 'Нева',
 			'Nkoo' => 'Н’Ко',
 			'Nshu' => 'Нушу',
 			'Ogam' => 'Огам',
 			'Olck' => 'Ол Чикӣ',
 			'Orkh' => 'Оркон',
 			'Orya' => 'Одия',
 			'Osge' => 'Осейҷӣ',
 			'Osma' => 'Османияӣ',
 			'Ougr' => 'Уйғури Куҳна',
 			'Palm' => 'Палмирена',
 			'Pauc' => 'Пау Син Хау',
 			'Perm' => 'Пермикии Куҳна',
 			'Phag' => 'Фагс-па',
 			'Phli' => 'Паҳлавии Хаттӣ',
 			'Phlp' => 'Паҳлавии Псалтирӣ',
 			'Phnx' => 'Финикӣ',
 			'Plrd' => 'Овоии поллардӣ',
 			'Prti' => 'Парфияи Хаттӣ',
 			'Qaag' => 'Завгӯйӣ',
 			'Rjng' => 'Реҷанг',
 			'Rohg' => 'Ханифӣ',
 			'Runr' => 'Руникӣ',
 			'Samr' => 'Самаританӣ',
 			'Sarb' => 'Арабии Ҷанубии Куҳна',
 			'Saur' => 'Саураштра',
 			'Sgnw' => 'Аломатнависӣ',
 			'Shaw' => 'Шавианӣ',
 			'Shrd' => 'Шарада',
 			'Sidd' => 'Сиддам',
 			'Sind' => 'Худовадӣ',
 			'Sinh' => 'Синхала',
 			'Sogd' => 'Суғдӣ',
 			'Sogo' => 'Суғдии Куҳна',
 			'Sora' => 'Сора Сомпенг',
 			'Soyo' => 'Соёмбо',
 			'Sund' => 'Сунданезӣ',
 			'Sylo' => 'Силоти Нагрӣ',
 			'Syrc' => 'Сурёнӣ',
 			'Tagb' => 'Тагбанва',
 			'Takr' => 'Такрӣ',
 			'Tale' => 'Тай Ле',
 			'Talu' => 'Тай Леи Нав',
 			'Taml' => 'Тамилӣ',
 			'Tang' => 'Тангут',
 			'Tavt' => 'Ветнамии Тайӣ',
 			'Telu' => 'Телугу',
 			'Tfng' => 'Тифинаг',
 			'Tglg' => 'Тагалогӣ',
 			'Thaa' => 'Таана',
 			'Thai' => 'Тайӣ',
 			'Tibt' => 'Тибетӣ',
 			'Tirh' => 'Тирхута',
 			'Tnsa' => 'Тангса',
 			'Toto' => 'Тото',
 			'Ugar' => 'Угаритӣ',
 			'Vaii' => 'Вайӣ',
 			'Vith' => 'Виткукӣ',
 			'Wara' => 'Варанг Кшитӣ',
 			'Wcho' => 'Ванчо',
 			'Xpeo' => 'Форсии Куҳна',
 			'Xsux' => 'Хати Сумеро-Аккадӣ',
 			'Yezi' => 'Язидӣ',
 			'Yiii' => 'Юйӣ',
 			'Zanb' => 'Майдони Занабазорӣ',
 			'Zinh' => 'Мерос',
 			'Zmth' => 'Аломати риёзӣ',
 			'Zsye' => 'Эмоҷи',
 			'Zsym' => 'Аломатҳо',
 			'Zxxx' => 'Нонавишта',
 			'Zyyy' => 'Умумӣ',
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
 			'CD' => 'Конго (ҶДК)',
 			'CF' => 'Ҷумҳурии Африқои Марказӣ',
 			'CG' => 'Конго',
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
 			'FR' => 'Фаронса',
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
 			'MK' => 'Македонияи Шимолӣ',
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
			'language' => 'Забон: {0}',
 			'script' => 'Скрипт: {0}',
 			'region' => 'Минтақа: {0}',

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
			index => ['А', 'Б', 'В', 'Г', 'Ғ', 'Д', 'ЕЁ', 'Ж', 'З', 'ИӢ', 'Й', 'К', 'Қ', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'УӮ', 'Ф', 'Х', 'Ҳ', 'Ч', 'Ҷ', 'Ш', 'Ъ', 'Э', 'Ю', 'Я'],
			main => qr{[а б в г ғ д её ж з иӣ й к қ л м н о п р с т уӯ ф х ҳ ч ҷ ш ъ э ю я]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” » ( ) \[ \] § @ * / \& # † ‡ ′ {″«}]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'В', 'Г', 'Ғ', 'Д', 'ЕЁ', 'Ж', 'З', 'ИӢ', 'Й', 'К', 'Қ', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'УӮ', 'Ф', 'Х', 'Ҳ', 'Ч', 'Ҷ', 'Ш', 'Ъ', 'Э', 'Ю', 'Я'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
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
		decimalFormat => {
			'long' => {
				'1000' => {
					'other' => '0 ҳазор',
				},
				'10000' => {
					'other' => '00 ҳазор',
				},
				'100000' => {
					'other' => '000 ҳазор',
				},
				'1000000' => {
					'other' => '0 миллион',
				},
				'10000000' => {
					'other' => '00 миллион',
				},
				'100000000' => {
					'other' => '000 миллион',
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
					'other' => '0 ҳзр'.'',
				},
				'10000' => {
					'other' => '00 ҳзр'.'',
				},
				'100000' => {
					'other' => '000 ҳзр'.'',
				},
				'1000000' => {
					'other' => '0 млн'.'',
				},
				'10000000' => {
					'other' => '00 млн'.'',
				},
				'100000000' => {
					'other' => '000 млн'.'',
				},
				'1000000000' => {
					'other' => '0 млрд'.'',
				},
				'10000000000' => {
					'other' => '00 млрд'.'',
				},
				'100000000000' => {
					'other' => '000 млрд'.'',
				},
				'1000000000000' => {
					'other' => '0 трлн'.'',
				},
				'10000000000000' => {
					'other' => '00 трлн'.'',
				},
				'100000000000000' => {
					'other' => '000 трлн'.'',
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
		'BRL' => {
			display_name => {
				'currency' => q(Реали бразилиягӣ),
				'other' => q(реали бразилиягӣ),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Иенаи хитоӣ),
				'other' => q(иенаи хитоӣ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Евро),
				'other' => q(евро),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Фунт стерлинги британӣ),
				'other' => q(фунт стерлинги британӣ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Рупияи ҳиндустонӣ),
				'other' => q(рупияи ҳиндустонӣ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Иенаи японӣ),
				'other' => q(иенаи японӣ),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Рубли русӣ),
				'other' => q(рубли русӣ),
			},
		},
		'TJS' => {
			symbol => 'сом.',
			display_name => {
				'currency' => q(Сомонӣ),
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
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Муҳ.',
							'Саф.',
							'Раб. I',
							'Раб. II',
							'Ҷум. I',
							'Ҷум. II',
							'Раҷ.',
							'Ша.',
							'Рам.',
							'Шав.',
							'Дхул-Қ.',
							'Дхул-Ҳ.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'муҳаррам',
							'сафар',
							'Рабеъ I',
							'Рабеъ II',
							'ҷимоди-ул-уло',
							'ҷимоди-ул-сони',
							'раҷаб',
							'Шабан',
							'Рамадан',
							'Шаввал',
							'Дхут-Қидаҳ',
							'Дхут-Ҳиҷҷаҳ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'муҳаррам',
							'сафар',
							'Рабеъ I',
							'Рабеъ II',
							'ҷимоди-ул-уло',
							'ҷимоди-ул-сони',
							'раҷаб',
							'Шабан',
							'Рамадан',
							'Шаввал',
							'Дхул-Қидаҳ',
							'Дхул-Ҳиҷҷаҳ'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					wide => {
						nonleap => [
							'фарвардин',
							'урдибиҳишт',
							'хурдод',
							'тир',
							'мурдод',
							'шаҳривар',
							'меҳр',
							'обон',
							'озар',
							'дей',
							'баҳман',
							'исфанд'
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
					narrow => {
						mon => 'Д',
						tue => 'С',
						wed => 'Ч',
						thu => 'П',
						fri => 'Ҷ',
						sat => 'Ш',
						sun => 'Я'
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
					wide => {0 => 'Ч1',
						1 => 'Ч2',
						2 => 'Ч3',
						3 => 'Ч4'
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
				'1' => 'Пас аз милод'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'САНА'
			},
		},
		'persian' => {
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
		'islamic' => {
			'full' => q{EEEE, d MMMM'и' y G},
			'long' => q{d MMMM'и' y G},
			'medium' => q{d MMM y G},
			'short' => q{M/d/y GGGGG},
		},
		'persian' => {
			'full' => q{EEEE, d MMMM'и' y G},
			'long' => q{d MMMM'и' y G},
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
		'islamic' => {
		},
		'persian' => {
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
		'islamic' => {
		},
		'persian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
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
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMM},
			MMMMW => q{'ҳафтаи' W, MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM-y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM, y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'ҳафтаи' w, Y},
		},
		'islamic' => {
			Ed => q{d E},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
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
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM'и' y G},
				y => q{MMMM'и' y – MMMM'и' y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				y => q{MMMM'и' y – MMMM'и' y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtZeroFormat => q(Вақти GMT),
		regionFormat => q(Вақти {0}),
		regionFormat => q(Вақти рӯзонаи {0}),
		regionFormat => q(Вақти стандартии {0}),
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
				'generic' => q#Вақти Уқёнуси Ором#,
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
				'standard' => q#Вақти миёнаи Гринвич#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
