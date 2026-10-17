use strict;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('MPGA::Trace') };

my @trace_log;
my $tracer = sub {
    my ($msg, $args, $flow) = @_;
    push @trace_log, { msg => $msg, args => $args ? [@$args] : undef, flow => [@$flow] };
};

# 1. flow_trace базовый
@trace_log = ();
my $flow = [ 10, \&fun_add ];
flow_trace($flow, undef, 0, $tracer);

is(scalar @trace_log, 2, 'flow_trace: 2 лога (ВЫЗОВ и ПОСЛЕ ВЫЗОВА)');
like($trace_log[0]{msg}, qr/ВЫЗОВ: .*fun_add/, 'flow_trace: ВЫЗОВ логирован правильно');
is_deeply($trace_log[0]{args}, [10], 'flow_trace: аргументы логированы');
is_deeply($trace_log[1]{flow}, [], 'flow_trace: состояние потока ПОСЛЕ ВЫЗОВА логировано');

# 2. flow_trace без опциональных аргументов (работа pop)
@trace_log = ();
$flow = [ 5, \&fun_add ];
flow_trace($flow, $tracer);
is(scalar @trace_log, 2, 'flow_trace(flow, tracer) через pop работает');

# 3. flow_ctx_trace
@trace_log = ();
my $ctx = { val => 1 };
$flow = [ $ctx, \&fun_ctx ];
flow_ctx_trace($flow, $tracer);
is(scalar @trace_log, 2, 'flow_ctx_trace работает');
is($ctx->{visited}, 1, 'flow_ctx_trace: ctx передан корректно');

# 4. flow_trace пустого потока (или только с данными)
@trace_log = ();
$flow = [ 1, 2, 3 ];
flow_trace($flow, $tracer);
is(scalar @trace_log, 1, 'flow_trace с данными: 1 лог ПОСЛЕ ВЫЗОВА');
is($trace_log[0]{msg}, 'ПОСЛЕ ВЫЗОВА', 'flow_trace с данными: логируется только после шага');
is_deeply($trace_log[0]{flow}, [], 'flow_trace с данными: данные поглощены');

# 5. Ошибочный вызов трассировщика
@trace_log = ();
$flow = [ 1 ];
flow_trace($flow, 'not_a_code');
is(scalar @trace_log, 0, 'flow_trace прерывается если tracer не CODE');

# 6. flow_ctx_trace пограничные случаи
flow_ctx_trace([], $tracer);
is(scalar @trace_log, 0, 'flow_ctx_trace: пустой массив ничего не делает');
flow_ctx_trace(undef, $tracer);
is(scalar @trace_log, 0, 'flow_ctx_trace: undef ничего не делает');

sub fun_add : MPGAargsNum(1) {
    my ($self, $args, $flow, $ctx) = @_;
    return;
}
sub fun_ctx : MPGAargsNum(0) {
    my ($self, $args, $flow, $ctx) = @_;
    $ctx->{visited} = 1;
    return;
}
