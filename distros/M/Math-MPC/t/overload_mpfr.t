# Test arithmetic overloading of Math::MPFR objects, added in Math-MPC-1.40
# Some of these operations require version 4.47 (or later) of Math::MPFR.
# See the "OPERATOR OVERLOADING" section of the Math::MPC documentation.

use strict;
use warnings;

use Math::MPC":mpc";
use Test::More;

*p = \&Math::MPC::overload_string;

my $mpc = Math::MPC->new(21);
my $ok;

# The release of mpc-1.4.0 corrects some earlier mishandling of signed zero.
# However we have the tests pass if their results match the value  that the
# underlying mpc library expects:
my $variable_result = '(2 0)';
$variable_result = '(2 -0)' if Math::MPC::MPC_VERSION >= 66560;

my $rop = $mpc / Math::MPFR->new(7);
cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded div returns Math::MPC::object");
cmp_ok(p($rop), 'eq', '(3 0)', "overloaded div ok");

$rop = $mpc * Math::MPFR->new(7);
cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded mul returns Math::MPC::object");
cmp_ok(p($rop), 'eq', '(1.47e2 0)', "overloaded mul ok");

$rop = $mpc - Math::MPFR->new(7);
cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded minus returns Math::MPC::object");
cmp_ok(p($rop), 'eq', '(1.4e1 0)', "overloaded minus ok");

$rop = $mpc + Math::MPFR->new(7);
cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded add returns Math::MPC::object");
cmp_ok(p($rop), 'eq', '(2.8e1 0)', "overloaded add ok");

$rop = $mpc ** Math::MPFR->new(7);
cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded pow returns Math::MPC::object");
cmp_ok(p($rop), 'eq', '(1.801088541e9 0)', "overloaded pow ok");

if($Math::MPFR::VERSION >= '4.47') {

  my $rop = Math::MPFR->new(42) / $mpc;
  cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded div (inverted) returns Math::MPC object");
  cmp_ok(p($rop), 'eq', $variable_result, "overloaded div (inverted) returns correct value");
  Rmpc_ui_div($rop, 42, $mpc, MPC_RNDNN);
  cmp_ok(p($rop), 'eq', $variable_result, "agreement with Rmpc_ui_div");

  $rop = Math::MPFR->new(42) * $mpc;
  $ok = '(8.82e2 0)';
  cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded mul (inverted) returns Math::MPC object");
  cmp_ok(p($rop), 'eq', $ok, "overloaded mul (inverted) returns correct value");
  Rmpc_mul_ui($rop, $mpc, 42, MPC_RNDNN);
  cmp_ok(p($rop), 'eq', '(8.82e2 0)', "agreement with Rmpc_mul_ui");

  $rop = $mpc * Math::MPFR->new(42);
  cmp_ok(p($rop), 'eq', $ok, "multiplication is commutative");

  $rop = Math::MPFR->new(42) - $mpc;
  cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded minus (inverted) returns Math::MPC object");
  cmp_ok(p($rop), 'eq', '(2.1e1 -0)', "overloaded minus (inverted) returns correct value");
  Rmpc_ui_sub($rop, 42, $mpc, MPC_RNDNN);
  cmp_ok(p($rop), 'eq', '(2.1e1 -0)', "agreement with Rmpc_ui_sub");

  $rop = Math::MPFR->new(42) + $mpc;
  $ok = '(6.3e1 0)';
  cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded add (inverted) returns Math::MPC object");
  cmp_ok(p($rop), 'eq', $ok, "overloaded add (inverted) returns correct value");
  Rmpc_add_ui($rop, $mpc, 42, MPC_RNDNN);
  cmp_ok(p($rop), 'eq', '(6.3e1 0)', "agreement with Rmpc_add_ui");

  $rop = $mpc + Math::MPFR->new(42);
  cmp_ok(p($rop), 'eq', $ok, "additition is commutative");

  $rop = $mpc ** Math::MPFR->new(2);
  cmp_ok(ref($rop), 'eq', 'Math::MPC', "overloaded pow (inverted) returns Math::MPC object");
  cmp_ok(p($rop), 'eq', '(4.41e2 0)', "overloaded pow (inverted) returns correct value");

  $rop = Math::MPFR->new(2) ** $mpc;
  cmp_ok(p($rop), 'eq', '(2.097152e6 0)', "Nth root(X ** N) == logN(N ** X)");

  eval { Rmpc_log2($rop, $rop, MPC_RNDNN);};
  if($@) {
    like($@, qr/^Rmpc_log2 function requires mpc version 1\.3\.2/, "Skipping - MPC library is too old");
  }
  else {
    cmp_ok(p($rop), 'eq', '(2.1e1 0)', "log2 calculation correct");
  }
}

else {
 # Check that expected exception is thrown.

 eval { my $rop = Math::MPFR->new(2) / Math::MPC->new(10);};
 like($@, qr/^Invalid argument supplied to Math::MPFR::overload_div/, "inverted division throws expected error");

 eval { my $rop = Math::MPFR->new(2) - Math::MPC->new(10);};
 like($@, qr/^Invalid argument supplied to Math::MPFR::overload_sub/, "inverted subtraction expected error");

 eval { my $rop = Math::MPFR->new(2) * Math::MPC->new(10);};
 like($@, qr/^Invalid argument supplied to Math::MPFR::overload_mul/, "inverted multiplication throws expected error");

 eval { my $rop = Math::MPFR->new(2) + Math::MPC->new(10);};
 like($@, qr/Invalid argument supplied to Math::MPFR::overload_add/, "inverted addition throws expected error");

 eval { my $rop = Math::MPFR->new(2) ** Math::MPC->new(10);};
 like($@, qr/Invalid argument supplied to Math::MPFR::overload_pow/, "inverted exponentiation throws expected error");

}

Rmpc_set_ui($mpc, 11, MPC_RNDNN);
$mpc -= Math::MPFR->new(3.5);
cmp_ok(ref($mpc), 'eq', 'Math::MPC', "MPC -= MPFR returns Math::MPC object");
cmp_ok(p($mpc), 'eq', '(7.5 0)', "MPC -= MPFR works correctly");

$mpc += Math::MPFR->new(3.5);
cmp_ok(ref($mpc), 'eq', 'Math::MPC', "MPC += MPFR returns Math::MPC object");
cmp_ok(p($mpc), 'eq', '(1.1e1 0)', "MPC += MPFR works correctly");

$mpc *= Math::MPFR->new(3);
cmp_ok(ref($mpc), 'eq', 'Math::MPC', "MPC *= MPFR returns Math::MPC object");
cmp_ok(p($mpc), 'eq', '(3.3e1 0)', "MPC *= MPFR works correctly");

$mpc /= Math::MPFR->new(3);
cmp_ok(ref($mpc), 'eq', 'Math::MPC', "MPC /= MPFR returns Math::MPC object");
cmp_ok(p($mpc), 'eq', '(1.1e1 0)', "MPC /= MPFR works correctly");

$mpc **= Math::MPFR->new(3);
cmp_ok(ref($mpc), 'eq', 'Math::MPC', "MPC **= MPFR returns Math::MPC object");
cmp_ok(p($mpc), 'eq', '(1.331e3 0)', "MPC **= MPFR works correctly");

if($Math::MPFR::VERSION >= '4.47') {

  my $mpfr = Math::MPFR->new(11);
  $mpfr -= Math::MPC->new(3.5);
  cmp_ok(ref($mpfr), 'eq', 'Math::MPC', "MPFR -= MPC returns Math::MPC object");
  cmp_ok(p($mpfr), 'eq', '(7.5 -0)', "MPC -= MPFR works correctly");
  cmp_ok(p($mpfr), 'eq', p(Math::MPFR->new(11) - Math::MPC->new(3.5)), "MPC -= MPFR double-check ok");

  $mpfr = Math::MPFR->new(7.5);
  $mpfr += Math::MPC->new(3.5);
  cmp_ok(ref($mpfr), 'eq', 'Math::MPC', "MPFR += MPC returns Math::MPC object");
  cmp_ok(p($mpfr), 'eq', '(1.1e1 0)', "MPC += MPFR works correctly");
  cmp_ok(p($mpfr), 'eq', p(Math::MPFR->new(7.5) + Math::MPC->new(3.5)), "MPC += MPFR double-check ok");

  $mpfr = Math::MPFR->new(7.5);
  $mpfr *= Math::MPC->new(3.5);
  cmp_ok(ref($mpfr), 'eq', 'Math::MPC', "MPFR *= MPC returns Math::MPC object");
  cmp_ok(p($mpfr), 'eq', '(2.625e1 0)', "MPC *= MPFR works correctly");
  cmp_ok(p($mpfr), 'eq', p(Math::MPFR->new(7.5) * Math::MPC->new(3.5)), "MPC *= MPFR double-check ok");

  $mpfr = Math::MPFR->new(7.0);
  $mpfr /= Math::MPC->new(3.5);
  cmp_ok(ref($mpfr), 'eq', 'Math::MPC', "MPFR /= MPC returns Math::MPC object");
  cmp_ok(p($mpfr), 'eq', $variable_result, "MPC /= MPFR works correctly");
  cmp_ok(p($mpfr), 'eq', p(Math::MPFR->new(7.0) / Math::MPC->new(3.5)), "MPC /= MPFR double-check ok");

  $mpfr = Math::MPFR->new(7.0);
  $mpfr **= Math::MPC->new(3);
  cmp_ok(ref($mpfr), 'eq', 'Math::MPC', "MPFR **= MPC returns Math::MPC object");
  cmp_ok(p($mpfr), 'eq', '(3.43e2 0)', "MPC **= MPFR works correctly");
  cmp_ok(p($mpfr), 'eq', p(Math::MPFR->new(7.0) ** Math::MPC->new(3.0)), "MPC **= MPFR double-check ok");
}

else {
  # Check that expected exception is thrown.

  my $mpfr = Math::MPFR->new(7.0);
  my $mpc = Math::MPC->new(3);

  eval { $mpfr += $mpc;};
  like($@, qr/Invalid argument supplied to Math::MPFR::overload_add_eq/, "inverted += throws expected error");

  eval { $mpfr -= $mpc;};
  like($@, qr/Invalid argument supplied to Math::MPFR::overload_sub_eq/, "inverted -= throws expected error");

  eval { $mpfr *= $mpc;};
  like($@, qr/Invalid argument supplied to Math::MPFR::overload_mul_eq/, "inverted *= throws expected error");

  eval { $mpfr /= $mpc;};
  like($@, qr/Invalid argument supplied to Math::MPFR::overload_div_eq/, "inverted /= throws expected error");

  eval { $mpfr **= $mpc;};
  like($@, qr/Invalid argument supplied to Math::MPFR::overload_pow_eq/, "inverted **= throws expected error");
}

done_testing();
