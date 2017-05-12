use strict;
use warnings;

use Test::More;
use FFI::Raw;

BEGIN {
    use_ok("GCCJIT", ":all");
}

my $ctx = gcc_jit_context_acquire;
my $int = gcc_jit_context_get_type $ctx, GCC_JIT_TYPE_INT;
my ($u, $v) = my @arg = map gcc_jit_context_new_param($ctx, undef, $int, $_), qw/u v/;
my $fun = gcc_jit_context_new_function $ctx, undef, GCC_JIT_FUNCTION_EXPORTED, $int, "gcd", \@arg, 0;

my %b = map { $_ => gcc_jit_function_new_block($fun, $_) } qw/init cond loop loop_end ret retneg/;

my $t = gcc_jit_function_new_local $fun, undef, $int, "t";
my $z = gcc_jit_context_zero $ctx, $int;
gcc_jit_block_end_with_jump $b{init}, undef, $b{cond};

my $vz = gcc_jit_context_new_comparison $ctx, undef, GCC_JIT_COMPARISON_GT, gcc_jit_param_as_rvalue($v), $z;
gcc_jit_block_end_with_conditional $b{cond}, undef, $vz, $b{loop}, $b{loop_end};

gcc_jit_block_add_assignment $b{loop}, undef, $t, gcc_jit_param_as_rvalue($u);
gcc_jit_block_add_assignment $b{loop}, undef, gcc_jit_param_as_lvalue($u), gcc_jit_param_as_rvalue($v);

my $r = gcc_jit_context_new_binary_op $ctx, undef, GCC_JIT_BINARY_OP_MODULO, $int, gcc_jit_lvalue_as_rvalue($t), gcc_jit_param_as_rvalue($v);
gcc_jit_block_add_assignment $b{loop}, undef, gcc_jit_param_as_lvalue($v), $r;
gcc_jit_block_end_with_jump $b{loop}, undef, $b{cond};

my $uz = gcc_jit_context_new_comparison $ctx, undef, GCC_JIT_COMPARISON_GT, gcc_jit_param_as_rvalue($u), $z;
gcc_jit_block_end_with_conditional $b{loop_end}, undef, $uz, $b{ret}, $b{retneg};

gcc_jit_block_end_with_return $b{ret}, undef, gcc_jit_param_as_rvalue($u);

gcc_jit_block_end_with_return $b{retneg}, undef,
    gcc_jit_context_new_unary_op $ctx, undef, GCC_JIT_UNARY_OP_MINUS, $int, gcc_jit_param_as_rvalue($u);

my $res = gcc_jit_context_compile $ctx;
my $ptr = gcc_jit_result_get_code $res, "gcd";
my $ffi = FFI::Raw->new_from_ptr($ptr, FFI::Raw::int, FFI::Raw::int, FFI::Raw::int);

is $ffi->(8, 12), 4;

done_testing;
