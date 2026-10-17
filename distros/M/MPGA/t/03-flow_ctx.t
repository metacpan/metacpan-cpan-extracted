use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('MPGA') };


# --- Граничные случаи ---

is_deeply( [ flow_ctx() ], [], 'test flow_ctx()' );

my $flow = undef;
is_deeply( [ flow_ctx($flow) ], [], 'test flow_ctx( undef )' );

$flow = 'aaa';
flow_ctx($flow);
is_deeply( [ $flow ], ['aaa'], 'test flow_ctx( scalar )' );

$flow = [];
flow_ctx($flow);
is_deeply( $flow, [], 'test flow_ctx( [] ) — пустой массив' );

$flow = [ { only => 'ctx' } ];
flow_ctx($flow);
is_deeply( $flow, [], 'test flow_ctx: only ctx, no functions' );


# --- Контекст передаётся в функцию ---

my $ctx = {};
$flow = [ $ctx, \&fun_check_ctx ];
flow_ctx($flow);
ok( eq_hash($ctx, { visited => 1 }), 'test flow_ctx: ctx передан в функцию' );


# --- Один и тот же $ctx передаётся во все функции цепочки ---

$ctx = { counter => 0 };
$flow = [ $ctx, \&fun_increment, \&fun_increment, \&fun_increment ];
flow_ctx($flow);
is( $ctx->{counter}, 3, 'test flow_ctx: ctx передан во все функции' );


# --- Аргументы + контекст ---

$ctx = {};
$flow = [ $ctx, 'hello', \&fun_store_arg ];
flow_ctx($flow);
is( $ctx->{stored}, 'hello', 'test flow_ctx: аргументы + ctx' );


# --- flow_ctx не ломает поток, он опустошается ---

$ctx = {};
$flow = [ $ctx, 'x', 'y', \&fun_store_arg ];
flow_ctx($flow);
is_deeply( $flow, [], 'test flow_ctx: поток опустошён после выполнения' );


# --- Функция с MPGAargsNum получает правильный ctx ---

$ctx = { result => 0 };
$flow = [ $ctx, 10, 20, \&fun_sum_with_ctx ];
flow_ctx($flow);
is( $ctx->{result}, 30, 'test flow_ctx: MPGAargsNum + ctx' );


# --- Функция возвращает данные обратно в поток, следующая их получает ---

$ctx = {};
$flow = [ $ctx, \&fun_produce, \&fun_consume ];
flow_ctx($flow);
ok( eq_hash($ctx, { produced => 1, consumed => 1 }), 'test flow_ctx: данные через поток между функциями' );



sub fun_check_ctx {
    my ($self, $args, $flow, $ctx) = @_;
    $ctx->{visited} = 1;
    return;
}

sub fun_increment {
    my ($self, $args, $flow, $ctx) = @_;
    $ctx->{counter}++;
    return;
}

sub fun_store_arg {
    my ($self, $args, $flow, $ctx) = @_;
    my $arg = pop @$args;
    $ctx->{stored} = $arg;
    return;
}

sub fun_sum_with_ctx : MPGAargsNum(2) {
    my ($self, $args, $flow, $ctx) = @_;
    my ($a, $b) = @$args;
    $ctx->{result} = $a + $b;
    return;
}

sub fun_produce {
    my ($self, $args, $flow, $ctx) = @_;
    $ctx->{produced} = 1;
    return ['token'];   # вставляет 'token' в начало потока
}

sub fun_consume {
    my ($self, $args, $flow, $ctx) = @_;
    my $arg = pop @$args;   # 'token' от fun_produce
    $ctx->{consumed} = 1 if defined $arg && $arg eq 'token';
    return;
}
