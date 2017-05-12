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
ok( $M == f( 'Косой', 'Вася' ),
    'name of boy ends to vowels without patronym: Vasya Kosoy' );
ok( $M == f( 'Балаганов', 'Шура' ),
    'ambiguous name, detect by lastname: Shura Balaganov' );
ok( $M == f( 'Уолл', 'Ларри' ),
    'english masculine name: Larry Wall' );
ok( $M == f( 'Бах', 'Иоганн Себастьян' ),
    'german masculine name: Johann Sebastian Bach' );
ok( $M == f( 'фон Вебер', 'Карл Мария' ),
    'german masculine name: Carl Maria von Weber' );
ok( $M == f( 'Руссо', 'Жан-Жак' ),
    'masculine name with hyphen: Jean-Jacques Rousseau' );

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
ok( $F == f( 'Петрова', 'Женя' ),
    'ambiguous name, detect by lastname: Zhenya Petrova' );
ok( $F == f( 'Фишер', 'Анна-Мария' ),
    'feminine name with hyphen: Anna-Maria Fisher' );

# Ambigous names
ok( !defined( f( 'Кац', 'Саша' ) ),
    'ambiguous name: Sasha Katz' );

# Wrong names
# Just for fun
# ok( !defined( f( 'Хренова', 'Гадя', 'Петрович' ) ),
#     'wrong name: Gadya Petrovich Khrenova' );
