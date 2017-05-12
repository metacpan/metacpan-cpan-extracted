use strict;
use warnings;

use Test::More;
use FFI::Raw;

BEGIN {
    use_ok("GCCJIT", ":all");
    require_ok("GCCJIT::Context");
}

my $ctx = GCCJIT::Context->acquire();
my $int = $ctx->get_type(GCC_JIT_TYPE_INT);
my ($u, $v) = my @arg = map $ctx->new_param(undef, $int, $_), qw/u v/;
my $fun = $ctx->new_function(undef, GCC_JIT_FUNCTION_EXPORTED, $int, "gcd", \@arg, 0);

my %b = map { $_ => $fun->new_block($_) } qw/init cond loop loop_end ret retneg/;

my $t = $fun->new_local(undef, $int, "t");
my $z = $ctx->zero($int);
$b{init}->end_with_jump(undef, $b{cond});

my $vz = $ctx->new_comparison(undef, GCC_JIT_COMPARISON_GT, $v->as_rvalue(), $z);
$b{cond}->end_with_conditional(undef, $vz, $b{loop}, $b{loop_end});

$b{loop}->add_assignment(undef, $t, $u->as_rvalue());
$b{loop}->add_assignment(undef, $u->as_lvalue(), $v->as_rvalue());

my $r = $ctx->new_binary_op(undef, GCC_JIT_BINARY_OP_MODULO, $int, $t->as_rvalue(), $v->as_rvalue());
$b{loop}->add_assignment(undef, $v->as_lvalue(), $r);
$b{loop}->end_with_jump(undef, $b{cond});

my $uz = $ctx->new_comparison(undef, GCC_JIT_COMPARISON_GT, $u->as_rvalue(), $z);
$b{loop_end}->end_with_conditional(undef, $uz, $b{ret}, $b{retneg});

$b{ret}->end_with_return(undef, $u->as_rvalue());

$b{retneg}->end_with_return(undef, $ctx->new_unary_op(undef, GCC_JIT_UNARY_OP_MINUS, $int, $u->as_rvalue()));

my $res = $ctx->compile();
my $ptr = $res->get_code("gcd");
my $ffi = FFI::Raw->new_from_ptr($ptr, FFI::Raw::int, FFI::Raw::int, FFI::Raw::int);

is $ffi->(8, 12), 4;

done_testing;
