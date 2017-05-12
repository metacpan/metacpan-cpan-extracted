use strict;
use warnings;

use Test::More;
use FFI::Raw;

BEGIN {
    use_ok("GCCJIT", ":all");
}

my $ctx = gcc_jit_context_acquire;
my $int = gcc_jit_context_get_type $ctx, GCC_JIT_TYPE_INT;
my $arg = gcc_jit_context_new_param $ctx, undef, $int, "i";
my $fun = gcc_jit_context_new_function $ctx, undef, GCC_JIT_FUNCTION_EXPORTED, $int, "square", [ $arg ], 0;
my $blk = gcc_jit_function_new_block $fun, "entry";
my $rvl = gcc_jit_param_as_rvalue $arg;
my $tmp = gcc_jit_context_new_binary_op $ctx, undef, GCC_JIT_BINARY_OP_MULT, $int, $rvl, $rvl;
gcc_jit_block_end_with_return $blk, undef, $tmp;

my $res = gcc_jit_context_compile $ctx;
my $ptr = gcc_jit_result_get_code $res, "square";

my $ffi = FFI::Raw->new_from_ptr($ptr, FFI::Raw::int, FFI::Raw::int);

is $ffi->(4), 16;
is $ffi->(6), 36;
is $ffi->(-2), 4;

done_testing;
