# Some very basic testing that, in places, does nothing (or little)
# more than test that a function of the given name is:
# 1) locatable;
# 2) does not crash.
# I might improve this as I get a better idea of what's involved.
# Requires mpc-1.3.0 or later.


use strict;
use warnings;
use Config;
use Math::MPC qw(:mpc);

use Test::More;

if(MPC_HEADER_V < 66304) {
  warn "\nRadius functions not implemented - needs mpc-1.3.0 but we have only mpc-", MPC_HEADER_V_STR, "\n";
  eval{Rmpcr_init();};
  like($@, qr/^Undefined subroutine &main::Rmpcr_init/, "Rmpcr_init() is unknown");

  eval{Math::MPC::Radius::Rmpcr_init();};
  like($@, qr/^Undefined subroutine &Math::MPC::Radius::Rmpcr_init/, "Math::MPC::Radius::Rmpcr_init() is unknown");

  done_testing();
  exit 0;
}

my $rop = Rmpcr_init();
my $chk = Rmpcr_init();
my $one = Rmpcr_init();  # (1073741824, -30)
my $two = Rmpcr_init();  # (1073741824, -29)
my $four = Rmpcr_init(); # (1073741824, -28)
my $half = Rmpcr_init(); # (1073741824, -31)
my $qtr = Rmpcr_init();  # (1073741824, -32)

my $zero = Rmpcr_init();
Rmpcr_set_zero($zero);

my @parts = Rmpcr_split($zero);
cmp_ok(@parts, '==', 1, "Rmpcr_split: one element for zero");
cmp_ok($parts[0], '==', 0, "Rmpcr_split: zero returns 0");

@parts = Rmpcr_split_mpfr($zero);
cmp_ok(@parts, '==', 1, "Rmpcr_split_mpfr: one element for zero");
cmp_ok(Math::MPFR::Rmpfr_zero_p($parts[0]), '!=', 0, "Rmpcr_split_mpfr: zero returns 0");

cmp_ok(Rmpcr_zero_p($zero), '!=', 0, "zero is zero");
my $nbl = Rmpcr_init_nobless(); # no magic

Rmpcr_set_inf($rop);
Rmpcr_set_inf($nbl);

@parts = Rmpcr_split($rop);
cmp_ok(@parts, '==', 1, "Rmpcr_split: one element for Inf");
cmp_ok($parts[0], 'eq', 'Inf', "Rmpcr_split: Inf returns 'Inf'");

@parts = Rmpcr_split_mpfr($rop);
cmp_ok(@parts, '==', 1, "Rmpcr_split_mpfr: one element for Inf");
cmp_ok($parts[0], 'eq', 'Inf', "Rmpcr_split_mpfr: Inf returns 'Inf'");
cmp_ok(ref($parts[0]), 'ne', 'Math::MPFR', "Rmpcr_split_mpfr: 'Inf' is not a Math::MPFR object");

cmp_ok(ref($rop), 'eq', 'Math::MPC::Radius', 'isa Math::MPC::Radius object');
cmp_ok(ref($nbl), 'eq', 'SCALAR', 'ref() of unblessed object is SCALAR');

cmp_ok(Rmpcr_inf_p($rop), '!=', 0, "Object is Inf");
cmp_ok(Rmpcr_zero_p($nbl), '==', 0, "Object is not Zero");
cmp_ok(Rmpcr_cmp($rop, $nbl), '==', 0, "Objects are equivalent");
cmp_ok(Rmpcr_cmp($rop, $nbl), '==', Rmpcr_cmp($nbl, $rop), "Argument reversal does not destroy equivalence");

Rmpcr_set($chk, $nbl);
cmp_ok(Rmpcr_cmp($rop, $chk), '==', 0, "Rmpcr_set works");

Rmpcr_sqr($chk, $nbl);
cmp_ok(Rmpcr_cmp($rop, $nbl), '==', 0, "Inf ** 2 == Inf");

Rmpcr_sqrt($chk, $nbl);
cmp_ok(Rmpcr_cmp($rop, $nbl), '==', 0, "Inf ** 0.5 == Inf");

Rmpcr_set_one($chk);
Rmpcr_set_zero($nbl);

cmp_ok(Rmpcr_cmp($chk, $rop), '<', 0, "1 < Inf");
cmp_ok(Rmpcr_cmp($rop, $chk), '>', 0, "Inf > 1");

Rmpcr_set_one($one);
cmp_ok(Rmpcr_lt_half_p($one), '==', 0, "1 > 0.5");

Rmpcr_set_zero($nbl);
cmp_ok(Rmpcr_lt_half_p($nbl), '!=', 0, "0 < 0.5");

my $mpc1 = Math::MPC->new(3.0, -4.0);
my $mpc2 = Math::MPC->new(4.0, -3.0);
Rmpcr_c_abs_rnd($rop, $mpc1, 2); # MPFR_RNDU
Rmpcr_c_abs_rnd($chk, $mpc2, 2); # MPFR_RNDU
cmp_ok(Rmpcr_cmp($rop, $chk), '==', 0, "Rmpcr_c_abs_rnd is consistent");

Rmpcr_c_abs_rnd($chk, $mpc2, 3); # MPFR_RNDD
cmp_ok(Rmpcr_cmp($rop, $chk), '>', 0, "Value is lessened by rounding down");

Rmpcr_set_ui64_2si64($two , 2, 0);# 1073741824, -29);
Rmpcr_set_ui64_2si64($four, 4, 0);# 1073741824, -28);
Rmpcr_set_ui64_2si64($half, 1073741824, -31);
Rmpcr_set_ui64_2si64($qtr , 1073741824, -32);
Rmpcr_set_str_2str($chk, "1", "-1");
cmp_ok(Rmpcr_cmp($half, $chk), '==', 0, "1: Rmpcr_str_2str functions correctly");

@parts = Rmpcr_split_mpfr($two);
cmp_ok(Math::MPFR::Rmpfr_get_prec($parts[0]), '==', 64, "mantissa is a 64-bit prec Math::MPFR object");
cmp_ok(Math::MPFR::Rmpfr_get_prec($parts[1]), '==', 64, "exponent is a 64-bit prec Math::MPFR object");
cmp_ok($parts[0], '==', '1073741824', "mantissa is 1073741824");
cmp_ok($parts[1], '==', '-29', "mantissa is -29");

@parts = Rmpcr_split($two);
cmp_ok(@parts, '==', 2, "Rmpcr_split: 2 elements for real non-zero radius");
cmp_ok($parts[0], '==', 1073741824, "Rmpcr_split: mant is 1073741824");
cmp_ok($parts[1], '==', -29, "Rmpcr_split: exp is -29");

cmp_ok(Rmpcr_lt_half_p($qtr), '!=', 0, "0.25 < 0.5");

#Rmpcr_say($one); # (1073741824, -30)

Rmpcr_set_ui64_2si64($rop, 1 << 31, -31);
cmp_ok(Rmpcr_cmp($rop, $one), '>', 0, "(1<<31, -1) is normalized within bound");

Rmpcr_set_ui64_2si64($rop, (1 << 31) + 1, -31);
cmp_ok(Rmpcr_cmp($rop, $one), '>', 0, "((1<<31)+1, -1) is normalized within bound");

Rmpcr_add($rop, $one, $one);
cmp_ok(Rmpcr_cmp($rop, $two), '>', 0, "1+1 >= 2");

Rmpcr_sub($rop, $two, $one);
cmp_ok(Rmpcr_cmp($rop, $one), '>=', 0, "2-1 >= 1"); # Actually equivalent

Rmpcr_mul($rop, $one, $one);
cmp_ok(Rmpcr_cmp($rop, $one), '>', 0, "1*1 > 1");

Rmpcr_div($rop, $one, $one);
cmp_ok(Rmpcr_cmp($rop, $one), '>', 0, "1/1 > 1");

Rmpcr_mul($chk, $one, $four);
Rmpcr_mul_2ui($rop, $one, 2);
cmp_ok(Rmpcr_cmp($rop, $four), '==', 0, "Rmpcr_mul_2ui works");
cmp_ok(Rmpcr_cmp($rop, $chk), '<', 0, "Rmpcr_mul_2ui is not the same as Rmpcr_mul");

Rmpcr_div($chk, $four, $four);
Rmpcr_div_2ui($rop, $four, 2);
cmp_ok(Rmpcr_cmp($rop, $one), '==', 0, "Rmpcr_div_2ui works");
cmp_ok(Rmpcr_cmp($rop, $chk), '<', 0, "Rmpcr_div_2ui is not the same as Rmpcr_div");

Rmpcr_sqr($rop, $two);
cmp_ok(Rmpcr_cmp($rop, $four), '>', 0, "2**2 > 4");

Rmpcr_sqrt($rop, $four);
cmp_ok(Rmpcr_cmp($rop, $two), '==', 0, "4**0.5 == 2");

Rmpcr_sqr($rop, $rop);
cmp_ok(Rmpcr_cmp($rop, $four), '>', 0, "(4**0.5)**2 > 4");

Rmpcr_set_ui64_2si64($chk, 11717, -22);
Rmpcr_set_str_2str($rop, '11717', '-22');
cmp_ok(Rmpcr_cmp($rop, $chk), '==', 0, "2: Rmpcr_set_str_2str works");

Rmpcr_max($rop, $one, $two);
cmp_ok(Rmpcr_cmp($rop, $two), '==', 0, "Rmpcr_max works");

cmp_ok(Rmpcr_get_exp($two),      '==', 2, "Rmpcr_get_exp works");
cmp_ok(Rmpcr_get_exp_mpfr($two), '==', 2, "Rmpcr_get_exp_mpfr works");

my $op1 = Rmpcr_init();
my $op2 = Rmpcr_init();

Rmpcr_set_ui64_2si64($op1, 112957, -32);
Rmpcr_set_ui64_2si64($op1, 102957, -33);

Rmpcr_sub($rop, $op2, $op1);
cmp_ok(Rmpcr_inf_p($rop), '!=', 0, "no rounding: inf returned");

Rmpcr_sub_rnd($rop, $op2, $op1, 2); # MPFR_RNDU
cmp_ok(Rmpcr_inf_p($rop), '!=', 0, "rounding up: inf returned");

Rmpcr_sub_rnd($rop, $op2, $op1, 3); # MPFR_RNDD
cmp_ok(Rmpcr_inf_p($rop), '!=', 0, "rounding down: inf returned");

Rmpcr_sub_rnd($rop, $op1, $op2, 2); # MPFR_RNDU
cmp_ok(Rmpcr_inf_p($rop), '==', 0, "rounding up: finite value returned");

Rmpcr_sub($chk, $op1, $op2);
cmp_ok(Rmpcr_cmp($rop, $chk), '==', 0, "Rmpcr_sub same as Rmpcr_sub_rnd with MPFR_RNDU");

Rmpcr_sub_rnd($rop, $op1, $op2, 3); # MPFR_RNDD
cmp_ok(Rmpcr_inf_p($rop), '==', 0, "rounding down: finite value returned");

my $mpc3 = Math::MPC->new(1.4141, 1.4142);

Rmpcr_c_abs_rnd($rop, $mpc3, 2); # MPFR_RNDU (2147387131, -30)
Rmpcr_c_abs_rnd($chk, $mpc3, 3); # MPFR_RNDD (2147387128, -30)
cmp_ok(Rmpcr_cmp($rop, $chk), '>', 0, 'rounded up > rounded down');

Rmpcr_set($chk, $rop); # $chk == $rop

Rmpcr_add_rounding_error($rop, 50, 2); # MPFR_RNDU
Rmpcr_add_rounding_error($chk, 30, 0); # MPFR_RNDD

# Now check that $rop and $chk are different.
cmp_ok(Rmpcr_cmp($chk, $rop), '!=', 0, "different results at different rounding and prec");

my $tinyr = Rmpcr_init();
Rmpcr_set_str_2str($tinyr, '1', '-36028797018963968');

my @check = ();

if($Config{ivsize} < 8) {
  eval{@parts = Rmpcr_split($tinyr);};
  like($@, qr/^Use Rmpcr_split_mpfr function instead/, "Rmpcr_split: croaks on overflow when IVSIZE < 8");
  @check = Rmpcr_split_mpfr($tinyr);

  eval{Rmpcr_get_exp($tinyr);};
  like($@, qr/^Use Rmpcr_get_exp_mpfr function instead/, "Rmpcr_get_exp: croaks on overflow when IVSIZE < 8");

  my $p = Math::MPFR::Rmpfr_get_default_prec();
  Math::MPFR::Rmpfr_set_default_prec(64); # Allow correct use of overloaded '==' operator.
  cmp_ok(Rmpcr_get_exp_mpfr($tinyr), '==', '-36028797018963967', "correct exponent of -36028797018963967 returned");
  Math::MPFR::Rmpfr_set_default_prec($p); # Restore original default.
}
else {
  Rmpcr_set_ui64_2si64($rop, 1, -36028797018963968);
  cmp_ok(Rmpcr_cmp($tinyr, $rop), '==', 0, "tiny radius values match");
  @check = Rmpcr_split($tinyr);
  my $check = Rmpcr_get_exp_mpfr($tinyr);
  cmp_ok(Math::MPFR::Rmpfr_cmp_IV($check, -36028797018963967), '==', 0, "1: Rmpcr_get_exp_mpfr ok");
  cmp_ok($check, '==', -36028797018963967, "2: Rmpcr_get_exp_mpfr ok");
  cmp_ok($check, '==', Rmpcr_get_exp($tinyr), "Rmpcr_get_exp_mpfr and Rmpcr_get_exp agree");
}

@parts = Rmpcr_split_mpfr($tinyr);

cmp_ok($parts[0], '==', $check[0], "Rmpcr_split and Rmpcr_split_mpfr have same mantissa");
cmp_ok($parts[1], '==', $check[1], "Rmpcr_split and Rmpcr_split_mpfr have same exponent");

#################################################################
Rmpcr_clear($nbl); # $nbl is unblessed and must be specifically #
                   # freed in order to avoid memory leak.       #
done_testing();                                                 #
#################################################################
