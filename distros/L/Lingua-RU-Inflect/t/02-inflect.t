#!perl -T

use utf8;
use Test::More 'no_plan';

use Lingua::RU::Inflect ':all';

*f = \&Lingua::RU::Inflect::inflect_given_name;

# Masculine names
ok( join(' ', f( NOMINATIVE, 'Пупкин', 'Василий', 'Алибабаевич' ))
    eq 'Пупкин Василий Алибабаевич',
    'Nominative of any name must be same as name' );
ok( join(' ', f( GENITIVE, 'Иванов', 'Сергей', 'Михайлович' ))
    eq 'Иванова Сергея Михайловича',
    'Genitive of usual russian masculine name: Sergey Mikhailovich Ivanov' );
ok( join(' ', f( DATIVE, 'Ильин', 'Роман' ))
    eq 'Ильину Роману ',
    'Dative of usual russian masculine name without patronym: Roman Ilyin' );

ok( join(' ', f( DATIVE, 'Ильиных', 'Роман' ))
    eq 'Ильиных Роману ',
    'Dative of russian masculine name with undeclinable lastname and without patronym: Roman Ilyinykh' );
ok( join(' ', f( DATIVE, 'Бултых', 'Борис' ))
    eq 'Бултыху Борису ',
    'Dative of russian masculine lastname with -ykh: Boris Byltykh' );
ok( join(' ', f( DATIVE, 'Отдых', 'Отто' ))
    eq 'Отдыху Отто ',
    'Dative of russian masculine lastname with -ykh: Otto Otdykh' );
ok( join(' ', f( DATIVE, 'Пых', 'Винстон' ))
    eq 'Пыху Винстону ',
    'Dative of russian masculine lastname with -ykh: Winston Pykh' );
ok( join(' ', f( DATIVE, 'Жмых', 'Жора' ))
    eq 'Жмыху Жоре ',
    'Dative of russian masculine lastname with -ykh: Zhora Zhmykh' );
ok( join(' ', f( DATIVE, 'Карих', 'Карл' ))
    eq 'Карих Карлу ',
    'Dative of russian masculine name with undeclinable lastname: Karl Karikh' );
ok( join(' ', f( DATIVE, 'Сизых', 'Семён' ))
    eq 'Сизых Семёну ',
    'Dative of russian masculine name with undeclinable lastname: Semyon Sizykh' );
ok( join(' ', f( DATIVE, 'Синих', 'Семён' ))
    eq 'Синих Семёну ',
    'Dative of russian masculine name with undeclinable lastname: Semyon Sinikh' );
ok( join(' ', f( DATIVE, 'Падших', 'Павел' ))
    eq 'Падших Павлу ',
    'Dative of russian masculine name with undeclinable lastname: Pavel Padshikh' );
ok( join(' ', f( DATIVE, 'Шуршащих', 'Шломо' ))
    eq 'Шуршащих Шломо ',
    'Dative of russian masculine name with undeclinable lastname: Shlomo Shurshashchikh' );
ok( join(' ', f( DATIVE, 'Козьих', 'Коля' ))
    eq 'Козьих Коле ',
    'Dative of russian masculine name with undeclinable lastname: Kolya Kozyikh' );
# German lastnames with -kh (-ch)
ok( join(' ', f( GENITIVE, 'Дитрих', 'Дитер' ))
    eq 'Дитриха Дитера ',
    'Genitive of last name ends with Kh: Dieter Dietrich' );
ok( join(' ', f( GENITIVE, 'Дидерих', 'Дитер' ))
    eq 'Дидериха Дитера ',
    'Genitive of last name ends with Kh: Dieter Diederich' );
ok( join(' ', f( GENITIVE, 'Диммих', 'Дитер' ))
    eq 'Диммиха Дитера ',
    'Genitive of last name ends with Kh: Dieter Dimmich' );
ok( join(' ', f( GENITIVE, 'Эрлих', 'Эдуард' ))
    eq 'Эрлиха Эдуарда ',
    'Genitive of last name ends with Kh: Edward Ehrlich' );
ok( join(' ', f( GENITIVE, 'Эвих', 'Эдуард' ))
    eq 'Эвиха Эдуарда ',
    'Genitive of last name ends with Kh: Edward Ewich' );
ok( join(' ', f( GENITIVE, 'Фрейндлих', 'Бруно' ))
    eq 'Фрейндлиха Бруно ',
    'Genitive of last name ends with Kh: Bruno Freundlich' );
ok( join(' ', f( GENITIVE, 'Фрейдлих', 'Франц' ))
    eq 'Фрейдлиха Франца ',
    'Genitive of last name ends with Kh: Franz Freudlich' );
ok( join(' ', f( GENITIVE, 'Фрайдих', 'Фриц' ))
    eq 'Фрайдиха Фрица ',
    'Genitive of last name ends with Kh: Fritz Freidich' );
ok( join(' ', f( GENITIVE, 'Миних', 'Макс' ))
    eq 'Миниха Макса ',
    'Genitive of last name ends with Kh: Max Minikh' );
ok( join(' ', f( GENITIVE, 'Мёглих', 'Макс' ))
    eq 'Мёглиха Макса ',
    'Genitive of last name ends with Kh: Max Moeglich' );
ok( join(' ', f( DATIVE, 'Рерих', 'Николай' ))
    eq 'Рериху Николаю ',
    'Dative of masculine lastname ends with -kh: Nickolas Roerich' );
ok( join(' ', f( DATIVE, 'Рёрих', 'Николай' ))
    eq 'Рёриху Николаю ',
    'Dative of masculine lastname ends with -kh: Nickolas Roerich (with yo)' );
ok( join(' ', f( DATIVE, 'Пих', 'Пауль' ))
    eq 'Пиху Паулю ',
    'Dative of masculine lastname ends with -kh: Paul Pich' );

ok( join(' ', f( DATIVE, 'Кох', 'Роман' ))
    eq 'Коху Роману ',
    'Dative of russian masculine name with declinable foreign lastname and without patronym: Roman Koch' );
ok( join(' ', f( ACCUSATIVE, undef, undef, 'Михалыч' ))
    eq '  Михалыча',
    'Accusative of vulgar form of russian patronym: Mikhalych' );
ok( join(' ', f( INSTRUMENTAL, 'Пушкин', undef, 'Сергеич' ))
    eq 'Пушкиным  Сергеичем',
    'Instrumental case of lastname with vulgar form of patronym: Pushkin Sergeich' );
ok( join(' ', f( INSTRUMENTAL, 'Чайковский', 'Пётр', 'Ильич' ))
    eq 'Чайковским Петром Ильичом',
    'Instrumental case of special firstname (yo -> e) and patronym: Tchaikovsky Pyotr Ilyich' );
ok( join(' ', f( PREPOSITIONAL, 'Репка', 'Илья' ))
    eq 'Репке Илье ',
    'Prepositional case of masculine name ends to vowels without patronym: Ilya Repka' );
ok( join(' ', f( GENITIVE, 'Водка', 'Кузьма' ))
    eq 'Водки Кузьмы ',
    'Genitive case of masculine name ends to vowels without patronym: Kuzma Vodka' );
ok( join(' ', f( DATIVE, 'Стремя', 'Имя', 'Петрович' ))
    eq 'Стремени Имени Петровичу',
    'Dative case of common nouns ends to -mya with masculine patronym: Imya Petrovich Stremya' );
ok( join(' ', f( GENITIVE, 'Ушко', 'Микола' ))
    eq 'Ушко Миколы ',
    'Genitive of ukrainian masculine name ends to vowels without patronym: Mykola Ushko' );
ok( join(' ', f( DATIVE, 'Косой', 'Вася' ))
    eq 'Косому Васе ',
    'Dative of name of boy ends to vowels without patronym: Vasya Kosoy' );
ok( join(' ', f( ACCUSATIVE, 'Балаганов', 'Шура' ))
    eq 'Балаганова Шуру ',
    'Accusative of ambiguous name, whose gender detected by lastname: Shura Balaganov' );
ok( join(' ', f( INSTRUMENTAL, 'Уолл', 'Ларри' ))
    eq 'Уоллом Ларри ',
    'Instrumental case of english masculine name: Larry Wall' );
ok( join(' ', f( DATIVE, 'Христос', 'Иисус' ))
    eq 'Христу Иисусу ',
    'Dative case of exception: Jesus Christ' );

# Fluent vowels: Pavel → Pavla, Lev → Lva, Konets → Kontsa etc
ok( join(' ', f( GENITIVE, 'Конец', 'Павел' ))
    eq 'Конца Павла ',
    'Genitive case of names with fluent vowels: Pavel Konets' );
ok( join(' ', f( GENITIVE, 'Конец', 'Яна' ))
    eq 'Конец Яны ',
    'Genitive case of feminine names with fluent vowels: Yana Konets' );
ok( join(' ', f( GENITIVE, 'Жнец', 'Павел' ))
    eq 'Жнеца Павла ',
    'Genitive case of names with fluent vowels: Pavel Zhnets' );
ok( join(' ', f( GENITIVE, 'Игрец', 'Павел' ))
    eq 'Игреца Павла ',
    'Genitive case of names with fluent vowels: Pavel Igrets' );
ok( join(' ', f( GENITIVE, 'Огурец', 'Павел' ))
    eq 'Огурца Павла ',
    'Genitive case of names with fluent vowels: Pavel Ogurets' );
ok( join(' ', f( GENITIVE, 'Молодец', 'Павел' ))
    eq 'Молодца Павла ',
    'Genitive case of names with fluent vowels: Pavel Molodets' );
ok( join(' ', f( GENITIVE, 'Индеец', 'Павел' ))
    eq 'Индейца Павла ',
    'Genitive case of names with fluent vowels: Pavel Indeyets' );
ok( join(' ', f( GENITIVE, 'Индиец', 'Павел' ))
    eq 'Индийца Павла ',
    'Genitive case of names with fluent vowels: Pavel Indiyets' );
ok( join(' ', f( GENITIVE, 'Палец', 'Павел' ))
    eq 'Пальца Павла ',
    'Genitive case of names with fluent vowels: Pavel Palets' );
ok( join(' ', f( GENITIVE, 'Боец', 'Павел' ))
    eq 'Бойца Павла ',
    'Genitive case of names with fluent vowels: Pavel Boyets' );
ok( join(' ', f( GENITIVE, 'Отец', 'Павел' ))
    eq 'Отца Павла ',
    'Genitive case of names with fluent vowels: Pavel Otets' );
ok( join(' ', f( GENITIVE, 'Заяц', 'Лев' ))
    eq 'Зайца Льва ',
    'Genitive of given name with fluent vowel: Lev Zayats' );

ok( join(' ', f( GENITIVE, 'Читая', 'Вано' ))
    eq 'Читая Вано ',
    'Genitive of georgian indeclinable names: Vano Chitaya' );
ok( join(' ', f( GENITIVE, 'Окуджава', 'Шалва' ))
    eq 'Окуджавы Шалвы ',
    'Genitive of georgian masculine names: Shalva Okudjava' );
ok( join(' ', f( GENITIVE, 'Графин', 'Татьяна' ))
    eq 'Графин Татьяны ',
    'Genitive of feminine lastname similar to masculine possessive last name: Tatyana Grafin' );

# Too complex. Wait for next version.
# ok( join(' ', f( PREPOSITIONAL, 'Бах', 'Иоганн Себастьян' ))
#     eq 'Бахе Иоганне Себастьяне ',
#     'Prepositional case of german masculine name: Johann Sebastian Bach' );
# ok( join(' ', f( GENITIVE, 'фон Вебер', 'Карл Мария' ))
#     eq 'фон Вебера Карла Марии ',
#     'Genitive of german mixed name with prefix: Carl Maria von Weber' );
# ok( join(' ', f( DATIVE, 'Руссо', 'Жан-Жак' ))
#     eq 'Руссо Жан-Жаку ',
#     'Dative of masculine name with hyphen: Jean-Jacques Rousseau' );

# Feminine names
ok( join(' ', f( ACCUSATIVE, 'Волкова', 'Анна', 'Павловна' ))
    eq 'Волкову Анну Павловну',
    'Accusative of usual russian feminine name: Anna Pavlovna Volkova' );
ok( join(' ', f( INSTRUMENTAL, 'Соколова', 'Инна' ))
    eq 'Соколовой Инной ',
    'Instrumental case of russian feminine name without patronym: Inna Sokolova' );
ok( join(' ', f( PREPOSITIONAL,  undef, 'Маргарита', 'Пална' ))
    eq ' Маргарите Палне',
    'Prepositional case of russian feminine firstname with vulgar form of patronym: Margarita Palna' );
ok( join(' ', f( GENITIVE,  'Иванова', 'Ольга' ))
    eq 'Ивановой Ольги ',
    'Genitive of russian feminine name ends to [G Zh J K Kh Ch Sh Shch] with A: Olga Ivanova' );
ok( join(' ', f( GENITIVE,  'Петрова', 'Лена' ))
    eq 'Петровой Лены ',
    'Genitive of russian feminine name ends to [other consonant] with A: Lena Petrova' );
ok( join(' ', f( GENITIVE,  'Шевчук', 'Любовь' ))
    eq 'Шевчук Любови ',
    'Genitive of russian feminine name ends to consonants: Lyubov Shevchuk' );
ok( join(' ', f( DATIVE, 'Купер', 'Элис' ))
    eq 'Купер Элис ',
    'Dative of english feminine name ends to consonants: Alice Cooper' );
ok( join(' ', f( ACCUSATIVE, 'Петрова', 'Женя' ))
    eq 'Петрову Женю ',
    'Accusative of ambiguous name, detect by lastname: Zhenya Petrova' );
# Too complex. Wait for next version.
# ok( join(' ', f( INSTRUMENTAL, 'Фишер', 'Анна-Мария' ))
#     eq 'Фишер Анну-Марию ',
#     'Instrumental case of feminine name with hyphen: Anna-Maria Fisher' );

# Ambigous names
# How to decline?
ok( join(' ', f( PREPOSITIONAL, 'Кац', 'Саша' ))
    eq 'Кац Саше ',
    'Prepositional of ambiguous name: Sasha Katz' );
