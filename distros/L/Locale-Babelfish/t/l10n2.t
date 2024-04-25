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
is $items_ru[0], undef, 'Undefined list item return as is';
is $items_ru[1], 'Элемент списка 1: content', 'Fisrt list item is correct in ru locale';
is $items_ru[2], 'Элемент списка 2: content', 'Second list item is correct in ru locale';

# Вложенные в списки словари
my @nested_items = @{ $l10n->t('test.nested.users' ) };
is scalar( @nested_items ), 2;
is_deeply $nested_items[0], { name => 'Ivan' , surname => 'Petrov' }, 'nested hash w/o params';
is_deeply $nested_items[1], { name => 'Sergey' , surname => 'Ivanov' }, 'nested hash w/o params';

# Вложенные в списки словари с параметрами
my @nested_items_with_params = @{ $l10n->t( 'test.nested.users_with_params', { user_id => 26532 } ) };
is scalar( @nested_items_with_params ), 2;
is_deeply $nested_items_with_params[0], { username => 'Ivan Petrov #26532' }, 'nested hash with params';
is_deeply $nested_items_with_params[1], { username => 'Sergey Ivanov #26532' }, 'nested hash with params';

# Вложенные в списки словари с вложенными словарями
my @nested_items_with_hash = @{ $l10n->t('test.nested.users_with_address' ) };
is scalar( @nested_items_with_hash ), 2;
is_deeply $nested_items_with_hash[0], { 'surname' => 'Петров', 'name' => 'Иван', 'address' => { 'country' => 'Россия' , 'city' => 'Москва' } }, 'nested list with nested hash w/o params';
is_deeply $nested_items_with_hash[1], { 'surname' => 'Иванov', 'name' => 'Сергей', 'address' => { 'country' => 'РФ' , 'city' => 'Санкт-Петербург', } }, 'nested list with nested hash w/o params';

# Вложенные в списки словари с вложенными словарями с параметрами
my @nested_items_with_hash_params = @{ $l10n->t( 'test.nested.users_with_address_params', { building_num => 7, age => 36 } ) };
is scalar( @nested_items_with_hash_params ), 2;
is_deeply $nested_items_with_hash_params[0], { 'name' => 'Иван', 'surname' => 'Петров', 'age' => '36', 'address' => { 'country' => 'Россия', 'city' => 'Москва', 'street' => 'Тверская', 'building' => '7' } }, 'nested list with nested hash with params';
is_deeply $nested_items_with_hash_params[1], { 'name' => 'Сергей', 'surname' => 'Иванov', 'age' => '36', 'address' => { 'country' => 'РФ', 'city' => 'Санкт-Петербург', 'street' => 'Садовая', 'building' => '7' } }, 'nested list with nested hash with params';

# Вложенные в списки словари с вложенными словарями с параметрами, проверяем вложенный хэш
my @nested_items_with_hash_combine_params = @{ $l10n->t( 'test.nested.users_with_address_combine_params', { building => { first => {num => 5}, second => {num => 7} } } ) };
is scalar( @nested_items_with_hash_combine_params ), 2;
is_deeply $nested_items_with_hash_combine_params[0], { 'name' => 'Иван', 'surname' => 'Петров', 'address' => { 'country' => 'Россия', 'city' => 'Москва', 'street' => 'Тверская', 'building' => '5' } }, 'nested list with nested hash with combine params';
is_deeply $nested_items_with_hash_combine_params[1], { 'name' => 'Сергей', 'surname' => 'Иванov', 'address' => { 'country' => 'РФ', 'city' => 'Санкт-Петербург', 'street' => 'Садовая', 'building' => '7' } }, 'nested list with nested hash with combine params';

# Вложенные в списки словари с вложенными словарями с параметрами, множественные формы
my @address_with_counted_buildings = @{ $l10n->t( 'test.nested.address_with_counted_buildings', { test => 2 } ) };
is scalar( @address_with_counted_buildings ), 2;
is_deeply $address_with_counted_buildings[0], { 'country' => 'Россия', 'city' => 'Москва', 'address' => { 'street' => 'Тверская', 'building' => 'На этой улице 2 дома пройдено' } }, 'nested list with nested hash with multiform params';
is_deeply $address_with_counted_buildings[1], { 'country' => 'РФ', 'city' => 'Санкт-Петербург', 'address' => { 'street' => 'Садовая', 'building' => 'На этой улице 2 дома пройдено'  } }, 'nested list with nested hash with multiform params';

# Вложенные в списки словари с вложенными списками
my @nested_items_with_list = @{ $l10n->t('test.nested.users_with_children' ) };
is scalar( @nested_items_with_list  ), 1;
is_deeply $nested_items_with_list [0], { name=> 'Иван', surname => 'Петров', 'children' => [ { 'name' => 'Кирилл', 'age' => '12' }, { 'name' => 'Ольга', 'age' => '8' } ] }, 'nested list with nested list w/o params';

# Вложенные в списки словари с вложенными словарями с параметрами
my @nested_items_with_list_params = @{ $l10n->t( 'test.nested.users_with_children_params', { role => 'отец', relative => 'дочь' } ) };
is scalar( @nested_items_with_list_params ), 1;
is_deeply $nested_items_with_list_params[0], { 'name' => 'Иван', 'surname' => 'Петров', 'role' => 'отец', 'children' => [ { 'name' => 'Ольга', 'age' => '12', 'relative' => 'дочь' }, { 'name' => 'Ирина', 'age' => '8', 'relative' => 'дочь' } ] }, 'nested list with nested list with params';

# Вложенные в списки словари с вложенными словарями с параметрами, проверяем вложенный хэш
my @nested_items_with_list_combine_params = @{ $l10n->t( 'test.nested.users_with_children_combine_params', { child => { first => {age => 11}, second => {age => 9} } } ) };
is scalar( @nested_items_with_list_combine_params ), 1;
is_deeply $nested_items_with_list_combine_params[0], { 'name' => 'Иван', 'surname' => 'Петров', 'children' => [ { 'name' => 'Ольга', 'age' => '11' }, { 'name' => 'Ирина', 'age' => '9' } ] }, 'nested list with nested list with combine params';

# Вложенные в списки словари с вложенными словарями с параметрами, множественные формы
my @nested_items_with_list_multiform_params = @{ $l10n->t( 'test.nested.users_with_children_class_params', { test => 4 } ) };
is scalar( @nested_items_with_list_multiform_params ), 1;
is_deeply $nested_items_with_list_multiform_params[0],  { 'name' => 'Иван', 'surname' => 'Петров', 'children' => [ { 'name' => 'Ольга', 'school' => 'В школе окончила 4 класса, хорошистка' }, { 'name' => 'Ирина', 'school' => 'В школе окончила 4 класса, отличница' } ] }, 'nested list with nested hash with multiform params';

# Несколько уровней вложенности
my @users_with_nested_level_params = @{ $l10n->t( 'test.nested.users_with_nested_level_params', { age => 12, experience1 => 2, experience2 => 3, place1 => 'Спартак', place2 => 'Динамо' }) };
is scalar( @users_with_nested_level_params ), 1;
is_deeply $users_with_nested_level_params[0],  { 'name' => 'Иван', 'surname' => 'Петров', 'children' => [ { 'name' => 'Ольга', 'age' => '12', 'hobby' => [ { 'what' => 'коньки', 'experience' => '2' }, { 'what' => 'лыжи', 'experience' => '3', 'coaches' => [ { 'coach' => 'Сидоров', 'jobs' => [ { 'place' => 'Спартак' }, { 'place' => 'Динамо' } ] } ] } ] } ] } , 'nested list with multiple levels of nesting';

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
is $items_en[0], undef, 'Undefined list item return as is';
is $items_en[1], 'List Item 1: content', 'First list item is correct in en locale';
is $items_en[2], 'List Item 2: content', 'Second list item is correct in en locale';

# Вложенные в списки словари
my @nested_items_en = @{ $l10n->t('test.nested.users' ) };
is scalar( @nested_items_en ), 2;
is_deeply $nested_items_en[0], { name => 'Ivan' , surname => 'Petrov' }, 'nested hash w/o params';
is_deeply $nested_items_en[1], { name => 'Sergey' , surname => 'Ivanov' }, 'nested hash w/o params';

# Вложенные в списки словари с параметрами
my @nested_items_with_params_en = @{ $l10n->t( 'test.nested.users_with_params', { user_id => 26532 } ) };
is scalar( @nested_items_with_params_en ), 2;
is_deeply $nested_items_with_params_en[0], { username => 'Ivan Petrov #26532' }, 'nested hash with params';
is_deeply $nested_items_with_params_en[1], { username => 'Sergey Ivanov #26532' }, 'nested hash with params';

# Вложенные в списки словари с вложенными словарями
my @nested_items_with_hash_en = @{ $l10n->t('test.nested.users_with_address' ) };
is scalar( @nested_items_with_hash_en ), 2;
is_deeply $nested_items_with_hash_en[0], { 'surname' => 'Petrov', 'name' => 'Ivan', 'address' => { 'country' => 'Russia' , 'city' => 'Moscow' } }, 'nested list with nested hash w/o params';
is_deeply $nested_items_with_hash_en[1], { 'surname' => 'Ivanov', 'name' => 'Sergey', 'address' => { 'country' => 'RF' , 'city' => 'Saint-Petersburg', } }, 'nested list with nested hash w/o params';

# Вложенные в списки словари с вложенными словарями с параметрами
my @nested_items_with_hash_params_en = @{ $l10n->t( 'test.nested.users_with_address_params', { building_num => 7, age => 36 } ) };
is scalar( @nested_items_with_hash_params_en ), 2;
is_deeply $nested_items_with_hash_params_en[0], { 'name' => 'Ivan', 'surname' => 'Petrov', 'age' => '36', 'address' => { 'country' => 'Russia', 'city' => 'Moscow', 'street' => 'Tverskaya', 'building' => '7' } }, 'nested list with nested hash with params';
is_deeply $nested_items_with_hash_params_en[1], { 'name' => 'Sergey', 'surname' => 'Ivanov', 'age' => '36', 'address' => { 'country' => 'RF', 'city' => 'Saint-Petersburg', 'street' => 'Sadovaya', 'building' => '7' } }, 'nested list with nested hash with params';

# Вложенные в списки словари с вложенными словарями с параметрами, проверяем вложенный хэш
my @nested_items_with_hash_combine_params_en = @{ $l10n->t( 'test.nested.users_with_address_combine_params',  { building => { first => {num => 5}, second => {num => 7} } } ) };
is scalar( @nested_items_with_hash_combine_params_en ), 2;
is_deeply $nested_items_with_hash_combine_params_en[0], { 'name' => 'Ivan', 'surname' => 'Petrov', 'address' => { 'country' => 'Russia', 'city' => 'Moscow', 'street' => 'Tverskaya', 'building' => '5' } }, 'nested list with nested hash with combine params';
is_deeply $nested_items_with_hash_combine_params_en[1], { 'name' => 'Sergey', 'surname' => 'Ivanov', 'address' => { 'country' => 'RF', 'city' => 'Saint-Petersburg', 'street' => 'Sadovaya', 'building' => '7' } }, 'nested list with nested hash with combine params';

# Вложенные в списки словари с вложенными словарями с параметрами, множественные формы
my @address_with_counted_buildings_en = @{ $l10n->t( 'test.nested.address_with_counted_buildings', { test => 1 } ) };
is scalar( @address_with_counted_buildings_en ), 2;
is_deeply $address_with_counted_buildings_en[0], { 'country' => 'Russia', 'city' => 'Moscow', 'address' => { 'street' => 'Tverskaya', 'building' => 'On this street 1 house has been passed' } }, 'nested list with nested hash with multiform params';
is_deeply $address_with_counted_buildings_en[1], { 'country' => 'RF', 'city' => 'Saint-Petersburg', 'address' => { 'street' => 'Sadovaya', 'building' => 'On this street 1 house has been passed'  } }, 'nested list with nested hash with multiform params';

# Вложенные в списки словари с вложенными списками
my @nested_items_with_list_en = @{ $l10n->t('test.nested.users_with_children' ) };
is scalar( @nested_items_with_list_en  ), 1;
is_deeply $nested_items_with_list_en [0], { name=> 'Ivan', surname => 'Petrov', 'children' => [ { 'name' => 'Kirill', 'age' => '12' }, { 'name' => 'Olga', 'age' => '8' } ] }, 'nested list with nested list w/o params';

# Вложенные в списки словари с вложенными словарями с параметрами
my @nested_items_with_list_params_en = @{ $l10n->t( 'test.nested.users_with_children_params', { role => 'father', relative => 'daughter' } ) };
is scalar( @nested_items_with_list_params_en ), 1;
is_deeply $nested_items_with_list_params_en[0], { 'name' => 'Ivan', 'surname' => 'Petrov', 'role' => 'father', 'children' => [ { 'name' => 'Olga', 'age' => '12', 'relative' => 'daughter' }, { 'name' => 'Irina', 'age' => '8', 'relative' => 'daughter' } ] }, 'nested list with nested list with params';

# Вложенные в списки словари с вложенными словарями с параметрами, проверяем вложенный хэш
my @nested_items_with_list_combine_params_en = @{ $l10n->t( 'test.nested.users_with_children_combine_params', { child => { first => {age => 11}, second => {age => 9} } } ) };
is scalar( @nested_items_with_list_combine_params_en ), 1;
is_deeply $nested_items_with_list_combine_params_en[0], { 'name' => 'Ivan', 'surname' => 'Petrov', 'children' => [ { 'name' => 'Olga', 'age' => '11' }, { 'name' => 'Irina', 'age' => '9' } ] }, 'nested list with nested list with combine params';

# Вложенные в списки словари с вложенными словарями с параметрами, множественные формы
my @nested_items_with_list_multiform_params_en = @{ $l10n->t( 'test.nested.users_with_children_class_params', { test => 4 } ) };
is scalar( @nested_items_with_list_multiform_params_en ), 1;
is_deeply $nested_items_with_list_multiform_params_en[0],  { 'name' => 'Ivan', 'surname' => 'Petrov', 'children' => [ { 'name' => 'Olga', 'school' => 'Finished 4 classes at school, is a good girl' }, { 'name' => 'Irina', 'school' => 'Finished 4 classes at school, excellent student' } ] }, 'nested list with nested hash with multiform params';

# Несколько уровней вложенности
my @users_with_nested_level_params_en = @{ $l10n->t( 'test.nested.users_with_nested_level_params', { age => 12, experience1 => 2, experience2 => 3, place1 => 'Spartak', place2 => 'Dinamo' }) };
is scalar( @users_with_nested_level_params_en ), 1;
is_deeply $users_with_nested_level_params_en[0],  {  'name' => 'Ivan', 'surname' => 'Petrov', 'children' => [ { 'name' => 'Olga', 'age' => '12', 'hobby' => [ { 'what' => 'skates', 'experience' => '2' }, { 'what' => 'ski', 'experience' => '3', 'coaches' => [ { 'coach' => 'Sidorov', 'jobs' => [ { 'place' => 'Spartak' }, { 'place' => 'Dinamo' } ] } ] } ] } ] } , 'nested list with multiple levels of nesting';

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
