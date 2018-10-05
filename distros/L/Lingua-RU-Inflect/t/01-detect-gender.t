#!perl -T

use utf8;
use Test::More 'no_plan';

use Lingua::RU::Inflect;

my $M = Lingua::RU::Inflect::MASCULINE;
my $F = Lingua::RU::Inflect::FEMININE;
*f = \&Lingua::RU::Inflect::detect_gender_by_given_name;

# Masculine names
ok( $M == f( 'Иванов', 'Сергей', 'Михайлович' ),
    'usual russian masculine name: Sergey Mikhailovich Ivanov' );
ok( $M == f( 'Ильин', 'Роман' ),
    'usual russian masculine name without patronym: Roman Ilyin' );
ok( $M == f( undef, undef, 'Михалыч' ),
    'vulgar form of russian patronym: Mikhalych' );
ok( $M == f( 'Пушкин', undef, 'Сергеич' ),
    'lastname with vulgar form of patronym: Pushkin Sergeich' );

ok( $M == f( 'Репка', 'Илья' ),
    'russian masculine name ends to vowels without patronym: Ilya Repka' );
ok( $M == f( 'Ушко', 'Микола' ),
    'ukrainian masculine name ends to vowels without patronym: Mykola Ushko' );
ok( $M == f( 'Водка', 'Никола' ),
    'masculine name ends to vowels without patronym: Nikola Vodka' );
ok( $M == f( 'Саркози', 'Николя' ),
    'masculine name ends to vowels without patronym: Nikolya Sarkozi (Nicolas Sarkozy)' );
ok( $M == f( 'Косой', 'Вася' ),
    'name of boy ends to vowels without patronym: Vasya Kosoy' );
ok( $M == f( 'Балаганов', 'Шура' ),
    'ambiguous name, detect by lastname: Shura Balaganov' );
ok( $M == f( 'Уолл', 'Ларри' ),
    'english masculine name: Larry Wall' );
ok( $M == f( 'Лори', 'Хью' ),
    'english masculine name: Hugh Laurie' );
ok( $M == f( 'Бах', 'Иоганн Себастьян' ),
    'german masculine name: Johann Sebastian Bach' );
ok( $M == f( 'фон Вебер', 'Карл Мария' ),
    'german masculine name: Carl Maria von Weber' );
ok( $M == f( 'Руссо', 'Жан-Жак' ),
    'masculine name with hyphen: Jean-Jacques Rousseau' );
ok( $M == f( undef, undef, 'Айрат-улы' ),
    'tatar masculine patronym with hyphen: Airat-uly' );
ok( $M == f( undef, undef, 'Мустафа улы' ),
    'tatar masculine patronym with space: Mustafa uly' );
ok( $M == f( undef, undef, 'Ислам-оглы' ),
    'azerbaijani masculine patronym with hyphen: Islam-ogly' );
ok( $M == f( undef, undef, 'Ислам оглы' ),
    'azerbaijani masculine patronym with space: Islam ogly' );
ok( $M == f( undef, undef, 'Кызылбаевич' ),
    'masculine patronym with feminine marker inside: Kyzylbayevich' );
ok( $M == f( undef, 'Эрик', 'Эриксон' ),
    'icelandic masculine name: Eric Ericsson' );

# Feminine names
ok( $F == f( 'Волкова', 'Анна', 'Павловна' ),
    'usual russian feminine name: Anna Pavlovna Volkova' );
ok( $F == f( 'Соколова', 'Инна' ),
    'russian feminine name without patronym: Inna Sokolova' );
ok( $F == f( undef, 'Маргарита', 'Пална' ),
    'russian feminine firstname with vulgar form of patronym: Margarita Palna' );
ok( $F == f( 'Шевчук', 'Любовь' ),
    'russian feminine name ends to consonants: Lyubov Shevchuk' );
ok( $F == f( 'Купер', 'Элис' ),
    'english feminine name ends to consonants: Alice Cooper' );
ok( $F == f( 'Денёв', 'Катрин' ),
    'french feminine name ends to consonants: Catherine Deneuve' );
ok( $F == f( 'Полгар', 'Юдит' ),
    'hungarian feminine name ends to consonants: Judit Polgar' );
ok( $F == f( 'Пиаф', 'Эдит' ),
    'hungarian feminine name ends to consonants: Edith Piaf' );
ok( $F == f( 'Дитрих', 'Марлен' ),
    'german feminine name ends to consonants: Marlene Dietrich' );
ok( $F == f( 'Монро', 'Мерилин' ),
    'american feminine name ends to consonants: Marilyn Monroe' );
ok( $F == f( 'Хэпбёрн', 'Одри' ),
    'british feminine name ends to consonants: Audrey Hepburn' );
ok( $F == f( 'Тейлор', 'Элизабет' ),
    'british feminine name ends to consonants: Elizabeth Taylor' );
ok( $F == f( 'Петрова', 'Женя' ),
    'ambiguous name, detect by lastname: Zhenya Petrova' );
ok( $F == f( 'Фишер', 'Анна-Мария' ),
    'feminine name with hyphen: Anna-Maria Fisher' );
ok( $F == f( undef, undef, 'Ренат-кызы' ),
    'tatar feminine patronym with hyphen: Renat-kyzy' );
ok( $F == f( undef, undef, 'Ринат кызы' ),
    'tatar feminine patronym with space: Rinat kyzy' );
ok( $F == f( undef, undef, 'Улыбаевна' ),
    'feminine patronym with masculine marker inside: Ulybayevna' );
ok( $F == f( undef, 'Бьорк', 'Сигурддоттир' ),
    'icelandic feminine name: Bjork Sigurddottir' );

# Ambigous names
ok( !defined( f( 'Кац', 'Саша' ) ),
    'ambiguous name: Sasha Katz' );

# Wrong names
# Just for fun
# ok( !defined( f( 'Хренова', 'Гадя', 'Петрович' ) ),
#     'wrong name: Gadya Petrovich Khrenova' );
