use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok("LibJIT", ":all");
}

my $ctx = jit_context_create;

# converted from code at http://eli.thegreenplace.net/2013/10/17/getting-started-with-libjit-part-1/ 
sub make_gcd {
    jit_context_build_start $ctx;

    my $params = [ jit_type_int, jit_type_int ];
    my $sig = jit_type_create_signature jit_abi_cdecl, jit_type_nint, $params, 1;
    my $fun = jit_function_create $ctx, $sig;

    my ($u, $v) = map jit_value_get_param($fun, $_), 0 .. 1;
    my $t = jit_value_create $fun, jit_type_int;
    my $z = jit_value_create_nint_constant $fun, jit_type_int, 0;

    my $l_while = jit_label_undefined;
    my $l_end = jit_label_undefined;

    jit_insn_label $fun, $l_while;
    my $vz = jit_insn_eq $fun, $v, $z;
    jit_insn_branch_if $fun, $vz, $l_end;

    jit_insn_store $fun, $t, $u;
    jit_insn_store $fun, $u, $v;

    my $rem = jit_insn_rem $fun, $t, $v;
    jit_insn_store $fun, $v, $rem;

    jit_insn_branch $fun, $l_while;
    jit_insn_label $fun, $l_end;

    my $l_pos = jit_label_undefined;
    my $uz = jit_insn_ge $fun, $u, $z;
    jit_insn_branch_if $fun, $uz, $l_pos;

    my $nu = jit_insn_neg $fun, $u;
    jit_insn_return $fun, $nu;

    jit_insn_label $fun, $l_pos;
    jit_insn_return $fun, $u;

    jit_function_compile $fun;

    jit_context_build_end $ctx;

    return $fun;
}

my $fun = make_gcd($ctx);

my $x = pack "q", 8;
my $y = pack "q", 12;
my $res;

my $rv = jit_function_apply $fun, [ $x, $y ], $res;
is $rv, 1;

my $val = unpack "q", $res;

is $val, 4;

done_testing;
