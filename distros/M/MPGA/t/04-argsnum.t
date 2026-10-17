use strict;
use warnings;

use Test::More tests => 16;
BEGIN { use_ok('MPGA') };


# --- Захват аргументов через переменную ---
my $captured;


# 1. MPGAargsNum(2): функция получает ровно 2 последних аргумента

my $flow = ['transit', 2, 3, \&fun2];
step($flow);
is_deeply($captured, [2, 3],      'MPGAargsNum(2): получены 2 правильных аргумента');
is_deeply($flow,     ['transit'], 'MPGAargsNum(2): транзитный арг возвращён в поток');


# 2. MPGAargsNum(0): функция получает пустой массив,
#    все аргументы становятся транзитными

$flow = ['a', 'b', \&fun0];
step($flow);
is_deeply($captured, [],           'MPGAargsNum(0): получен пустой массив аргументов');
is_deeply($flow,     ['a', 'b'],  'MPGAargsNum(0): все аргументы вернулись в поток как транзитные');


# 3. MPGAargsNum(1): функция получает 1 последний аргумент

$flow = ['a', 'b', \&fun1];
step($flow);
is_deeply($captured, ['b'], 'MPGAargsNum(1): получен 1 правильный аргумент');
is_deeply($flow,     ['a'], 'MPGAargsNum(1): транзитный арг возвращён');


# 4. MPGAargsNum(2) + возврат массива: транзитный ПЕРЕД результатом в потоке

$flow = ['transit', 2, 3, \&fun2_returns];
step($flow);
is_deeply($flow, ['transit', 'result'], 'MPGAargsNum(2)+return: порядок transit→result верен');


# 5. MPGAargsNum + $ctx: контекст передаётся в функцию

my $ctx = {};
$flow = [10, 20, \&fun2_with_ctx];
step($flow, $ctx);
is($ctx->{sum}, 30, 'MPGAargsNum(2)+ctx: ctx передан и заполнен');


# 6. MPGAargsNum(3) при нехватке аргументов:
#    функция получает то, что есть; поток не рушится

$flow = [1, \&fun3];
step($flow);
is_deeply($captured, [1], 'MPGAargsNum(3) с 1 арг: получает что есть');
is_deeply($flow,     [],  'MPGAargsNum(3) с 1 арг: поток не рушится');


# 7. MPGAargsNum + возврат скаляра
$flow = ['transit', 1, 2, \&fun_ret_scalar];
step($flow);
is_deeply($flow, ['transit', 'scalar_val'], 'MPGAargsNum + return scalar');

# 8. MPGAargsNum + возврат хэш-рефа
$flow = ['transit', 1, 2, \&fun_ret_hashref];
step($flow);
is_deeply($flow, ['transit', { key => 'val' }], 'MPGAargsNum + return hashref');

# 9. MPGAargsNum + модификация flow
$flow = ['transit', 1, 2, \&fun_mod_flow, 'tail'];
step($flow);
is_deeply($flow, ['transit', 'new_flow_1', 'new_flow_2'], 'MPGAargsNum + flow modification');


# 10. MPGAargsNum(3) при полном отсутствии аргументов (args = undef)
#     Не должно быть Fatal Error "Can't use an undefined value as an ARRAY reference"
$flow = [\&fun3];
step($flow);
is_deeply($captured, [], 'MPGAargsNum(3) при undef args: получает пустой массив и не падает');
is_deeply($flow, [], 'MPGAargsNum(3) при undef args: поток опустошается нормально');




sub fun0 : MPGAargsNum(0) {
    my ($self, $args, $flow, $ctx) = @_;
    $captured = [@$args];
    return;
}

sub fun1 : MPGAargsNum(1) {
    my ($self, $args, $flow, $ctx) = @_;
    $captured = [@$args];
    return;
}

sub fun2 : MPGAargsNum(2) {
    my ($self, $args, $flow, $ctx) = @_;
    $captured = [@$args];
    return;
}

sub fun2_returns : MPGAargsNum(2) {
    my ($self, $args, $flow, $ctx) = @_;
    return ['result'];
}

sub fun2_with_ctx : MPGAargsNum(2) {
    my ($self, $args, $flow, $ctx) = @_;
    my ($a, $b) = @$args;
    $ctx->{sum} = $a + $b;
    return;
}

sub fun3 : MPGAargsNum(3) {
    my ($self, $args, $flow, $ctx) = @_;
    $captured = [@$args];
    return;
}

sub fun_ret_scalar : MPGAargsNum(2) {
    my ($self, $args, $flow, $ctx) = @_;
    return 'scalar_val';
}

sub fun_ret_hashref : MPGAargsNum(2) {
    my ($self, $args, $flow, $ctx) = @_;
    return { key => 'val' };
}

sub fun_mod_flow : MPGAargsNum(2) {
    my ($self, $args, $flow, $ctx) = @_;
    @$flow = ('new_flow_1', 'new_flow_2');
    return;
}
