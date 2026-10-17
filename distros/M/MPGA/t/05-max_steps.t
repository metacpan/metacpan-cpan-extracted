use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('MPGA') };


our $step_count = 0;
our $loop_count = 0;


# 1. max_steps=1: останавливается после 1 шага

my $flow = [1, \&fun_count, 2, \&fun_count, 3, \&fun_count];
$step_count = 0;
flow($flow, undef, 1);
is($step_count, 1,                                     'max_steps=1: выполнен 1 шаг');
is_deeply($flow, [2, \&fun_count, 3, \&fun_count],    'max_steps=1: остаток потока верен');


# 2. max_steps=2: останавливается после 2 шагов

$flow = [1, \&fun_count, 2, \&fun_count, 3, \&fun_count];
$step_count = 0;
flow($flow, undef, 2);
is($step_count, 2,                  'max_steps=2: выполнено 2 шага');
is_deeply($flow, [3, \&fun_count],  'max_steps=2: остаток потока верен');


# 3. max_steps=0: без ограничений, весь поток исполняется

$flow = [1, \&fun_count, 2, \&fun_count, 3, \&fun_count];
$step_count = 0;
flow($flow, undef, 0);
is($step_count, 3,   'max_steps=0: выполнены все 3 шага (без ограничения)');
is_deeply($flow, [], 'max_steps=0: поток опустошён');


# 4. max_steps > реального числа шагов: поток опустошается нормально

$flow = [1, \&fun_count];
flow($flow, undef, 999);
is_deeply($flow, [], 'max_steps=999 при 1 шаге: поток опустошён');


# 5. Защита от бесконечного цикла: функция возвращает саму себя в поток

$loop_count = 0;
$flow = [\&fun_self_loop];
flow($flow, undef, 5);
is($loop_count, 5, 'max_steps=5 останавливает бесконечный цикл');




# Потребляет 1 аргумент, считает вызовы
sub fun_count : MPGAargsNum(1) {
    my ($self, $args, $flow, $ctx) = @_;
    $step_count++;
    return;
}

# Возвращает саму себя в поток (бесконечный цикл без max_steps)
sub fun_self_loop : MPGAargsNum(0) {
    my ($self, $args, $flow, $ctx) = @_;
    $loop_count++;
    return [$self];
}
