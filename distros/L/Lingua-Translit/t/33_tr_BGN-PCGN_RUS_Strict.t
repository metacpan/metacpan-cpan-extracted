#  ===========================================================================
#    BGN/PCGN Romanization System for Russian (Strict Variant)
#    for Lingua::Translit Perl Module
#    https://github.com/ndlecic/bgn-pcgn_rus
#
#    Copyright 2017 Nikola D. Lečić <nikola.lecic@anthesphoria.net>
#  ===========================================================================
#
#  This implementation of BGN/PCGN romanization system comes in two
#  variants:
#    - strict
#    - standard
#  Please see respective XML files for explanations.

use strict;
use utf8;
use Test::More tests => 7;
use Lingua::Translit;

my $name        =   "BGN/PCGN RUS Strict";
my $reversible  =   0;

my $input       =   "Все люди рождаются свободными и равными в " .
                    "своём достоинстве и правах. Они наделены разумом и " .
                    "совестью и должны поступать в отношении друг " .
                    "друга в духе братства.";
my $output_ok   =   "Vse lyudi rozhdayut·sya svobodnymi i ravnymi v " .
                    "svoyëm dostoinstve i pravakh. Oni nadeleny razumom i " .
                    "sovest'yu i dolzhny postupat' v otnoshenii drug " .
                    "druga v dukhe brat·stva.";

my $context     =   "акце́нт, Елисеев, Алетейя, Мейер, Кайафа, " .
                    "Йадав, её; Её, подъём, Йэн, йэн, додекаэдр, " .
                    "ещё, чьё, интеръекционный, выудить, Майя, " .
                    "9-е мая, фойе, Фейербах, Чистые пруды, " .
                    "Достоевский, Толстой, Горкий, Аркадий, Белый, " .
                    "Юрий, Сергей, Хрущёв, Горбачёв";
my $context_ok  =   "aktsent, Yeliseyev, Aleteyya, Meyyer, Kay·afa, " .
                    "Y·adav, yeyë; Yeyë, pod''yëm, Y·en, y·en, dodekaedr, " .
                    "yeshchë, ch'yë, inter''yektsionnyy, vy·udit', Mayya, " .
                    "9-ye maya, foyye, Feyyerbakh, Chistyye prudy, " .
                    "Dostoyevskiy, Tolstoy, Gorkiy, Arkadiy, Belyy, " .
                    "Yuriy, Sergey, Khrushchëv, Gorbachëv";

my $abbr        =   "ВЦИОМ, РАНХиГС, НЭП, РОССПЭН, АЭС, РЖД, СПбГУ, " .
                    "ЮАР, ЮФУ, ЮУрГУ, РостГЭУ-РИНХ, " .
                    "Ю. Я. Щербаков и Е. Е. Ёлкина";
my $abbr_ok     =   "VTsIOM, RANKhiGS, N·EP, ROSSP·EN, AES, RZhD, SPbGU, " .
                    "YuAR, YuFU, YuUrGU, RostG·EU-RINKh, " .
                    "Yu. Ya. Shcherbakov i Ye. Ye. Yëlkina";

my $excl        =   "Ыыыыыы! ЫЫЫЫЫЫ! Ай-ай-ай. Ээээээххх... " .
                    "Жжжжжж! Йех-ай-яй! Ё-моё...";
my $excl_ok     =   "Y·y·y·y·y·y! Y·Y·Y·Y·Y·Y! Ay-ay-ay. Eeeeeekhkhkh... " .
                    "Zhzhzhzhzhzh! Yyekh-ay-yay! Yë-moyë...";

# Geographic names (geo and nonrusgeo tests) are taken from
# https://en.wikipedia.org/wiki/BGN/PCGN_romanization_of_Russian
# https://en.wikipedia.org/wiki/Wikipedia:Romanization_of_Russian
my $geo =           "Азов, Тамбов, Барнаул, Кубань, Владимир, " .
                    "Ульяновск, Грозный, Волгодонск, Дзержинский, " .
                    "Нелидово, Елизово, Чапаевск, Юрьев, Съезд, " .
                    "Белкин, Ёлкин, Остриё, Громадьё, Подъёмный, " .
                    "Озёрный, Жуков, Лужники, Звенигород, Вязьма, " .
                    "Иркутск, Апатиты, Бийск, Киров, Енисейск, " .
                    "Ломоносов, Нелидово, Менделеев, Каменка, " .
                    "Новосибирск, Кандалакша, Омск, Красноярск, " .
                    "Петрозаводск, Серпухов, Ростов, " .
                    "Северобайкальск, Сковородино, Чайковский, " .
                    "Тамбов, Мытищи, Углич, Дудинка, Фурманов, Уфа, " .
                    "Хабаровск, Прохладный, Цимлянск, Ельцин, " .
                    "Чебоксары, Печора, Шахтёрск, Мышкин, Щёлково, " .
                    "Ртищево, Тында, Тюмень, Электрогорск, " .
                    "Радиоэлектроника, Юбилейный, Ключевская, " .
                    "Якутск, Брянск, Набережные Челны";
my $geo_ok =        "Azov, Tambov, Barnaul, Kuban', Vladimir, " .
                    "Ul'yanovsk, Groznyy, Volgodonsk, Dzerzhinskiy, " .
                    "Nelidovo, Yelizovo, Chapayevsk, Yur'yev, " .
                    "S''yezd, Belkin, Yëlkin, Ostriyë, Gromad'yë, " .
                    "Pod''yëmnyy, Ozërnyy, Zhukov, Luzhniki, " .
                    "Zvenigorod, Vyaz'ma, Irkut·sk, Apatity, Biysk, " .
                    "Kirov, Yeniseysk, Lomonosov, Nelidovo, " .
                    "Mendeleyev, Kamenka, Novosibirsk, Kandalaksha, " .
                    "Omsk, Krasnoyarsk, Petrozavodsk, Serpukhov, " .
                    "Rostov, Severobaykal'sk, Skovorodino, " .
                    "Chaykovskiy, Tambov, Mytishchi, Uglich, " .
                    "Dudinka, Furmanov, Ufa, Khabarovsk, " .
                    "Prokhladnyy, Tsimlyansk, Yel'tsin, Cheboksary, " .
                    "Pechora, Shakhtërsk, Myshkin, Shchëlkovo, " .
                    "Rtishchevo, Tynda, Tyumen', Elektrogorsk, " .
                    "Radioelektronika, Yubileynyy, Klyuchevskaya, " .
                    "Yakut·sk, Bryansk, Naberezhnyye Chelny";

my $nonrusgeo   =   "Йёнчёпинг, Тыайа, Сайылык, Ойусардах, " .
                    "Йошкар-Ола, Ыгыатта, Тыэкан, Суык-Су, " .
                    "Куыркъявр, Иссык-Куль, Вяртсиля, " .
                    "Ташчишма, Улан-Удэ, Мусийкъонгийкоте, " .
                    "Рыркайпий, Йемен";
my $nonrusgeo_ok=   "Yyënchëping, Ty·ay·a, Say·ylyk, Oy·usardakh, " .
                    "Yoshkar-Ola, Ygy·atta, Ty·ekan, Su·yk-Su, " .
                    "Ku·yrk''yavr, Issyk-Kul', Vyart·silya, " .
                    "Tash·chishma, Ulan-Ud·e, Musiyk''ongiykote, " .
                    "Ryrkaypiy, Yyemen";

my $tr = new Lingua::Translit($name);

# 1
is($tr->can_reverse(), $reversible, "$name: Reversibility");

# 2
my $output = $tr->translit($input);
is($output, $output_ok, "$name: Universal declaration of human rights");

# 3
$output = $tr->translit($context);
is($output, $context_ok, "$name: Context-sensitive sequences and various name endings");

# 4
$output = $tr->translit($abbr);
is($output, $abbr_ok, "$name: Abbreviations");

# 5
$output = $tr->translit($excl);
is($output, $excl_ok, "$name: Various exclamations");

# 6
$output = $tr->translit($geo);
is($output, $geo_ok, "$name: Various geographic names");

# 7
$output = $tr->translit($nonrusgeo);
is($output, $nonrusgeo_ok, "$name: Complex names of non-Russian origin");

# vim: sts=4 sw=4 ai et
