=head1 stable test

ok

=cut

use strict;
use warnings;
use utf8;

use Test::Deep;
use Test::More;
use Test::More::UTF8;
use lib::abs ();
use Data::Dumper;

use_ok( 'Locale::Babelfish' ) or exit;

my $dir = lib::abs::path('locales');

my $cfg = {
    dirs         => [ $dir ],
    default_lang => 'ru_RU',
    langs        => [ 'ru_RU', 'en_US', ],
    langs_short  => {
        RU => 'ru_RU',
        EN => 'en_US',
    },
};

my $l10n = Locale::Babelfish->new( $cfg );

is(
    $l10n->set_fallback( 'ru_RU', 'en_US' ),
    1,
    'set_fallback',
);

my $t;
$t = $l10n->t('test1.developers.some.test');
$l10n->locale('ru');


# проверяем что будет если не правильный словарь
is( $t, '[test1.developers.some.test]', "Got [\$key] on absent dictionary" );

is(
    $l10n->t('test.simple.plural.nails_count', 10),
    'I have 10 nails',
    'fallback from ru_RU to en_US',
);

# Проверяем что будет если ввести не существующий параметр
cmp_ok( $l10n->t('test.simple.whoareyou', { dummy => ' programmer ' } ) ,
        'eq', 'Я ' , 'dummy_parameter'
 );

# Проверяем что будет если ввести не существующий ключ
cmp_ok( $l10n->t('test.dummy_key', { who => ' programmer ' } ) ,
        'eq', '[test.dummy_key]' , 'dummy_key'
 );

# Проверяем что будет если пропустить нужный ключ
cmp_ok( $l10n->t('test.simple.whoareyou',) ,
          'eq', 'Я ' , 'need_var'
 );


# Проверяем подстановку переменной, без множественных форм
cmp_ok( $l10n->t('test.simple.whoareyou', { who => 'programmer' } ) ,
        'eq', 'Я programmer' , 'simple_var'
 );

# обычный вызов, параметры идут хэшем, проверяем вложенный хэш
cmp_ok( $l10n->t('test.simple.some.combine', { single => { test => { deep => 'примера'} } , count => 10 , test => 2 } ) ,
        'eq' , 'У меня есть  10 гвоздей  для примера 2 тестов', 'check2' );

# тестируем множественное число 1
cmp_ok( $l10n->t('test.simple.plural.nails', { test => 10 } ) ,
        'eq', 'У меня 10 гвоздей' , 'plural1'
 );

# тестируем множественные формы 2
cmp_ok( $l10n->t('test.simple.plural.nails', { test => 3 } ) ,
        'eq', 'У меня 3 гвоздя' , 'plural2'
 );

# тестируем множественные формы 3
cmp_ok( $l10n->t('test.simple.plural.nails3', { test => 1 } ) ,
        'eq', '1 у меня гвоздь' , 'plural3'
 );

# тестируем множественные формы упрощенная запись
cmp_ok( $l10n->t('test.simple.plural.nails2', { count => 1 } ) ,
        'eq', 'У меня гвоздь упрощенная форма записи' , 'plural_simple'
 );

# тестируем повторное использование фраз
cmp_ok( $l10n->t('test.simple.plural.nails4', { test => 1, test2 => 20 } ) ,
        'eq', 'Берём 1 гвоздь для 20 досок и вбиваем 1 гвоздь в 20 досок' , 'repeat_twice'
 );

# функция проверяет есть такой ключ в словаре
cmp_ok( $l10n->has_any_value('test.simple.plural.nails2' ) ,
        '==', 1 , 'has_any_value'
 );


# функция проверяет есть такой ключ в словаре
cmp_ok($l10n->t('test.markdown' , {  link => 1 }  ) ,
        'eq', 'воспользоваться [предыдущей версией](1)' , 'markdown'
);

is $l10n->t('test.zero_plural', 0), "у меня нет гвоздей", 'zero plural form';

my @items_ru = @{ $l10n->t('test.simple.list', { test => 'content' } ) };
is $items_ru[0], 'Элемент списка 1: content', 'Fisrt list item is correct in ru locale';
is $items_ru[1], 'Элемент списка 2: content', 'Second list item is correct in ru locale';

# Переключаем язык
$l10n->locale('en_US');

# Переключили локаль
cmp_ok( $l10n->t('test.simple.plural.nails2', { test => 1 } ) ,
        'eq', 'I have 1 nail simple using' , 'plural_simple_eng'
 );

# пробелы в плюралах
is $l10n->t('test.simple.plural.big_nails', { test => 2 } ) ,
        'I have 2 big nails with spaces' , 'plural_with_spaces';

# просто скаляр всемто хэша
is $l10n->t('test.simple.plural.nails_count', 7), 'I have 7 nails', 'params as scalar';

# вложенные словари
is $l10n->t('sub/test.a'), 'A', 'nested dictionary';
is $l10n->t('sub/sub2/sub3/test.b'), 'B', 'nested dictionary, 3rd level';
is $l10n->t('sub/sub1/sub3/test.b'), 'C', 'nested dictionary, 3rd level in another folder';

# эскапинг
is $l10n->t('test.simple.escapes', { who => 'Man', count => '1' }), 'I have #{who} na|il', 'escaping';

# списки
my @items_en = @{ $l10n->t('test.simple.list', { test => 'content' } ) };
is $items_en[0], 'List Item 1: content', 'Fisrt list item is correct in en locale';
is $items_en[1], 'List Item 2: content', 'Second list item is correct in en locale';

# передача невалидных данных должна давать warning.

{
    my $warns = 0;
    local $SIG{__WARN__} = sub {
        my ( $warn ) = @_;
        like $warn, qr<^'test' parameter is not numeric: test>, "Got warning";
        $warns++;
    };
    is $l10n->t('test.simple.plural.nails2', { test => 'test' }), "I have test nails simple using", "Last regular plural used";
    is $warns, 1, "One warning got";
}

done_testing;
