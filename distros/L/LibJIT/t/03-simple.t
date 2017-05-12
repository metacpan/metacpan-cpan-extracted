use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok("LibJIT", ":all");
}

my $ctx = jit_context_create;

sub make_int_mul {
    jit_context_build_start $ctx;

    my $params = [ jit_type_int, jit_type_int ];
    my $sig = jit_type_create_signature jit_abi_cdecl, jit_type_nint, $params, 1;
    my $fun = jit_function_create $ctx, $sig;

    my ($i, $j) = map jit_value_get_param($fun, $_), 0 .. 1;

    my $prod = jit_insn_mul $fun, $i, $j;
    jit_insn_return $fun, $prod;

    jit_function_compile $fun;

    jit_context_build_end $ctx;

    return $fun;
}

my $fun = make_int_mul($ctx);

my $x = pack "q", 6;
my $y = pack "q", 7;
my $res;

my $rv = jit_function_apply $fun, [ $x, $y ], $res;
is $rv, 1;

my $val = unpack "q", $res;

is $val, 42;

done_testing;
