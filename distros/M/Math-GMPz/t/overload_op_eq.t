# Test cross class overloading of +=, *=, -=, /=, ....
# for the cases where the second arg is either a
# a Math::GMPq object or a Math::MPFR object.
# In these cases the operation returns a Math::GMPq
# or (respectively) a Math::MPFR object.

use strict;
use warnings;
use Math::GMPz qw(:mpz);

use Test::More;

my $have_mpfr = 0;
eval {require Math::MPFR;};
$have_mpfr = 1 unless $@;

my $have_gmpq = 0;
eval {require Math::GMPq;};
$have_gmpq = 1 unless $@;


my $z1 = Math::GMPz->new(123);
my $z2 = Math::GMPz->new(123);
my $q = 0;
$q  = Math::GMPq->new('1/11') if $have_gmpq;
my $fr = 0;
$fr = Math::MPFR->new(17.1) if $have_mpfr;

eval {$z1 /= 0;};
like($@, qr/^Division by 0 not allowed/, 'division by 0 is illegal');

if($have_gmpq) {
  if($Math::GMPq::VERSION < 0.43) {
    warn "\n  Skipping Math::GMPq tests -  Math::GMPq version 0.35(or later)\n" .
          "  is needed. We have only version $Math::GMPq::VERSION\n";
  }
  else {
    my $z = Math::GMPz->new(123);
    $z *= $q;
    cmp_ok(ref($z), 'eq', 'Math::GMPq', '$z changes to a Math::GMPq object');
    cmp_ok($z, '==', $q * Math::GMPz->new(123), '$z *= $q sets $z to 123/11');

    $z = Math::GMPz->new(123);
    cmp_ok(ref($z), 'eq', 'Math::GMPz', '$z has been reverted to a Math::GMPz object');
    $z += $q;
    cmp_ok(ref($z), 'eq', 'Math::GMPq', '$z changes to a Math::GMPq object');
    cmp_ok($z, '==', $q + Math::GMPz->new(123), '$z += $q sets $z to 1354/11');

    $z = Math::GMPz->new(123);
    $z -= $q;
    cmp_ok(ref($z), 'eq', 'Math::GMPq', '$z changes to a Math::GMPq object');
    cmp_ok($z, '==', Math::GMPz->new(123) - $q, '$z -= $q sets $z to 1352/11');

    $z = Math::GMPz->new(123);
    $z /= $q;
    cmp_ok(ref($z), 'eq', 'Math::GMPq', '$z changes to a Math::GMPq object');
    cmp_ok($z, '==', Math::GMPz->new(123) / $q, '$z /= $q sets $z to 1353');
  }
}

############################################

# The following tests are mainly to check that 'op=' overloading
# involving a Math::MPFR object operand returns a Math::MPFR object
# that has the same precision as that operand.
# OTOH when 'op' overloading involves a Math::MPFR object the
# returned Math::MPFR object should have default precision.
# (Other checks are also performed.)

if($have_mpfr) {
  if($Math::MPFR::VERSION < 4.19) {
    warn "\n  Skipping all tests involving Math::MPFR objects -  Math::MPFR version 4.19\n" .
          "   (or later) is needed. We have only version $Math::MPFR::VERSION\n";
  }
  else {
    my $z = Math::GMPz->new(123);
    cmp_ok(ref($z), 'eq', 'Math::GMPz', '$z has been reverted to a Math::GMPz object');
    $z *= $fr;
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', $fr * Math::GMPz->new(123), '$z *= $fr sets $z to 2.1033000000000002e3');

    $z = Math::GMPz->new(123);
    $z += $fr;
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', $fr + Math::GMPz->new(123), '$z += $fr sets $z to 1.4009999999999999e2');

    $z = Math::GMPz->new(123);
    $z -= $fr;
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', Math::GMPz->new(123) - $fr, '$z -= $fr sets $z to 1.0590000000000001e2');

    $z = Math::GMPz->new(123);
    $z /= $fr;
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', Math::GMPz->new(123) / $fr, '$z /= $fr sets $z to 7.1929824561403501');

    $z = Math::GMPz->new(2);
    $z **= Math::MPFR->new(0.5);
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', Math::GMPz->new(2) ** Math::MPFR->new(0.5), '$z **= $Math::MPFR->new(0.5) sets $z to 1.4142135623730951');

    $z = Math::GMPz->new(2);
    Math::MPFR::Rmpfr_set_default_prec(113);
    $z **= Math::MPFR->new(0.5);
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', Math::GMPz->new(2) ** Math::MPFR->new(0.5), '$z **= Math::MPFR->new(0.5) sets $z to 1.41421356237309504880168872420969798');
  }

  if($have_mpfr) {
    if($Math::MPFR::VERSION >= 4.19) {

      my $fr = Math::MPFR::Rmpfr_init2(70);
      Math::MPFR::Rmpfr_set_ui($fr, 2, 0);
      Math::MPFR::Rmpfr_sqrt($fr, $fr, 0);

      my @precs = (30, 53, 64, 113, 130);

      cmp_ok($fr, '!=', sqrt(2), "different precisions are not equivalent");

      for my $p(@precs) {
        my $z = Math::GMPz->new(~0);
        Math::MPFR::Rmpfr_set_default_prec($p);
#
        my ($c1, $c2) = ($z * $fr, $fr * $z);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "* Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "* Z: C2 precision ok");
        cmp_ok(ref($c1), 'eq', 'Math::MPFR',  "* Z: reference ok");
        cmp_ok(ref($c2), 'eq', ref($c1),      "* Z: references match");
        cmp_ok($c1, '==', $c2,                "* Z: values match");
#
        ($c1, $c2) = ($z + $fr, $fr + $z);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "+ Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "+ Z: C2 precision ok");
        cmp_ok(ref($c1), 'eq', 'Math::MPFR',  "+ Z: reference ok");
        cmp_ok(ref($c2), 'eq', ref($c1),      "+ Z: references match");
        cmp_ok($c1, '==', $c2,                "+ Z: values match");
#
        ($c1, $c2) = ($z - $fr, $fr - $z);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "- Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "- Z: C2 precision ok");
        cmp_ok(ref($c1), 'eq', 'Math::MPFR',  "- Z: reference ok");
        cmp_ok(ref($c2), 'eq', ref($c1),      "- Z: references match");
        cmp_ok($c1, '==', -$c2,               "- Z: values match");
#
        ($c1, $c2) = ($z / $fr, $fr / $z);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p,          "/ Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p,          "/ Z: C2 precision ok");
        cmp_ok(ref($c1), 'eq', 'Math::MPFR',           "/ Z: reference ok");
        cmp_ok(ref($c2), 'eq', ref($c1),               "/ Z: references match");
        cmp_ok($c1 * $c2, '==', _approx($c1 * $c2, 1), "/ Z: values match");
#
        if($Math::MPFR::VERSION >= 4.35) {
          ($c1, $c2) = ($z % $fr, $fr % $z);
          cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p,          "% Z: C1 precision ok");
          cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p,          "% Z: C2 precision ok");
          cmp_ok(ref($c1), 'eq', 'Math::MPFR',           "% Z: reference ok");
          cmp_ok(ref($c2), 'eq', ref($c1),               "% Z: references match");
          cmp_ok($c2, '==', Math::MPFR->new($fr),        "% Z: F % Z == F");
        }
      }

#########################################################

      for my $p(@precs) {
        my $fr = Math::MPFR::Rmpfr_init2(70);
        Math::MPFR::Rmpfr_set_ui($fr, 2, 0);
        Math::MPFR::Rmpfr_sqrt($fr, $fr, 0);
        my $z = Math::GMPz->new(~0);
        my $z_copy = Math::GMPz->new($z);
        Math::MPFR::Rmpfr_set_default_prec($p);
        my ($c1, $c2) = ($z *= $fr, $fr *= $z_copy);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', 70,  "*= Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', 70,  "*= Z: C2 precision ok");
        cmp_ok(ref($c1), 'eq', 'Math::MPFR',   "*= Z: reference ok");
        cmp_ok(ref($c2), 'eq', ref($c1),       "*= Z: references match");
        cmp_ok(ref($z), 'eq', 'Math::MPFR',    "*= Z: Math::GMPz object changes to Math::MPFR object");
        cmp_ok(ref($fr), 'eq', 'Math::MPFR',   "*= Z: Math::MPFR object stays a Math::MPFR object");
        cmp_ok($c1, '==', $z,                  "*= Z: \$c1 set correctly");
        cmp_ok($c2, '==', $fr,                 "*= Z: \$c2 set correctly");
        cmp_ok($c1, '==', $c2,                 "*= Z: values match");
      }

#########################################################

      for my $p(@precs) {
        my $fr = Math::MPFR::Rmpfr_init2(70);
        Math::MPFR::Rmpfr_set_ui($fr, 2, 0);
        Math::MPFR::Rmpfr_sqrt($fr, $fr, 0);
        my $z = Math::GMPz->new(~0);
        my $z_copy = Math::GMPz->new($z);
        Math::MPFR::Rmpfr_set_default_prec($p);
        my ($c1, $c2) = ($z += $fr, $fr += $z_copy);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', 70,  "+= Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', 70,  "+= Z: C2 precision ok");
        cmp_ok(ref($c1), 'eq', 'Math::MPFR',   "+= Z: reference ok");
        cmp_ok(ref($c2), 'eq', ref($c1),       "+= Z: references match");
        cmp_ok(ref($z), 'eq', 'Math::MPFR',    "+= Z: Math::GMPz object changes to Math::MPFR object");
        cmp_ok(ref($fr), 'eq', 'Math::MPFR',   "+= Z: Math::MPFR object stays a Math::MPFR object");
        cmp_ok($c1, '==', $z,                  "+= Z: \$c1 set correctly");
        cmp_ok($c2, '==', $fr,                 "+= Z: \$c2 set correctly");
        cmp_ok($c1, '==', $c2,                 "+= Z: values match");
      }

#########################################################

      for my $p(@precs) {
        my $fr = Math::MPFR::Rmpfr_init2(70);
        Math::MPFR::Rmpfr_set_ui($fr, 2, 0);
        Math::MPFR::Rmpfr_sqrt($fr, $fr, 0);
        my $z = Math::GMPz->new(~0);
        my $z_copy = Math::GMPz->new($z);
        Math::MPFR::Rmpfr_set_default_prec($p);
        my ($c1, $c2) = ($z -= $fr, $fr -= $z_copy);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', 70,  "-= Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', 70,  "-= Z: C2 precision ok");
        cmp_ok(ref($c1), 'eq', 'Math::MPFR',   "-= Z: reference ok");
        cmp_ok(ref($c2), 'eq', ref($c1),       "-= Z: references match");
        cmp_ok(ref($z), 'eq', 'Math::MPFR',    "-= Z: Math::GMPz object changes to Math::MPFR object");
        cmp_ok(ref($fr), 'eq', 'Math::MPFR',   "-= Z: Math::MPFR object stays a Math::MPFR object");
        cmp_ok($c1, '==', $z,                  "-= Z: \$c1 set correctly");
        cmp_ok($c2, '==', $fr,                 "-= Z: \$c2 set correctly");
        Math::MPFR::Rmpfr_mul_si($c2, $c2, -1, 0); # Do not use overloaded ops here.
        cmp_ok($c1, '==', $c2,                "-= Z: values match");

      }

#########################################################

      for my $p(@precs) {
        my $fr = Math::MPFR::Rmpfr_init2(70);
        Math::MPFR::Rmpfr_set_ui($fr, 2, 0);
        Math::MPFR::Rmpfr_sqrt($fr, $fr, 0);
        my $z = Math::GMPz->new(~0);
        my $z_copy = Math::GMPz->new($z);
        Math::MPFR::Rmpfr_set_default_prec($p);
        my ($c1, $c2) = ($z /= $fr, $fr /= $z_copy);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', 70,          "/= Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', 70,          "/= Z: C2 precision ok");
        cmp_ok(ref($c1), 'eq', 'Math::MPFR',           "/= Z: reference ok");
        cmp_ok(ref($c2), 'eq', ref($c1),               "/= Z: references match");
        cmp_ok(ref($z), 'eq', 'Math::MPFR',            "/= Z: Math::GMPz object changes to Math::MPFR object");
        cmp_ok(ref($fr), 'eq', 'Math::MPFR',           "/= Z: Math::MPFR object stays a Math::MPFR object");
        cmp_ok($c1, '==', $z,                          "/= Z: \$c1 set correctly");
        cmp_ok($c2, '==', $fr,                         "/= Z: \$c2 set correctly");
        Math::MPFR::Rmpfr_mul($c1, $c1, $c2, 0); # Do not use overloaded '*' here.
        cmp_ok($c1, '==', _approx($c1, 1), "/= Z: values match");
      }
#
      for my $p(@precs) { #### test '**' and '**=' ####
        Math::MPFR::Rmpfr_set_default_prec($p);
        my $v = 2251799813685247.0;
        my $zv = Math::GMPz->new($v);
        my $z2 = Math::GMPz->new(2);
        my $fv = Math::MPFR::Rmpfr_init2(300);
        my $f2 = Math::MPFR::Rmpfr_init2(300);
        Math::MPFR::Rmpfr_set_NV($fv, $v, 0);
        Math::MPFR::Rmpfr_set_ui($f2, 2, 0);
        my $c1 = $zv ** $f2;
        my $c2 = $fv ** $z2;
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "** Z: C1 precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "** Z: C2 precision ok");
        cmp_ok($c1, '==', $c2,                "** Z : values match ($c1)");

        $zv **= $f2;
        $fv **= $z2;

        cmp_ok(Math::MPFR::Rmpfr_get_prec($zv), '==', 300, "**= Z: ZV precision ok");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($fv), '==', 300, "**= Z: FV precision ok");
        cmp_ok($zv, '==', $fv,                 "**= Z: values match");
        if($p > 64) {
          cmp_ok($c1, '==', $zv,                 "**= Z: C1 == ZV");
          cmp_ok($c2, '==', $fv,                 "**= Z: C2 == FV");
        }
        else {
          cmp_ok($c1, '!=', $zv,                 "**= Z: C1 != ZV");
          cmp_ok($c2, '!=', $fv,                 "**= Z: C2 != FV");
        }
      }

      if($Math::MPFR::VERSION >= 4.35) {
        for my $p(@precs) { #### test '%' and '%=' ####
          my ($f_val, $f_div) = (Math::MPFR::Rmpfr_init2(300), Math::MPFR::Rmpfr_init2(300));
          Math::MPFR::Rmpfr_set_NV($f_val, 65.5, 0);
          Math::MPFR::Rmpfr_set_NV($f_div, 6.75, 0);
          my $z_val = Math::GMPz->new(70);
          my $z_div = Math::GMPz->new(7);

          Math::MPFR::Rmpfr_set_default_prec($p);

          my($c1, $c2) = ($z_val % $f_div, $f_val % $z_div);

          cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "% Z: C1 precision ok");
          cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "% Z: C2 precision ok");
          cmp_ok($c1, '==', $c2,                "% Z:values match");

          $f_val %= $z_div;
          $z_val %= $f_div;

          cmp_ok(Math::MPFR::Rmpfr_get_prec($f_val), '==', 300, "% Z: F_VAL precision ok");
          cmp_ok(Math::MPFR::Rmpfr_get_prec($z_val), '==', 300, "% Z: Z_VAL precision ok");

          cmp_ok($c1, '==', $z_val,                 "**= Z: C1 == Z_VAL");
          cmp_ok($c2, '==', $f_val,                 "**= Z: C2 == F_VAL");
        }
      }
    }
  }
}
done_testing();

sub _approx {
  # 1st arg is a Math::MPFR object.
  # 2nd arg is the object's expected value.
  # Return $obj if the 2 values differ by no more than 1 ULP. (The calling test will pass.)
  # Else, return $expected. (The calling test will fail.)
  my ($obj, $expected) = (shift, shift);
  return $obj if $obj == $expected;

  my $copy = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($obj));
  Math::MPFR::Rmpfr_set($copy, $obj, 0);
  if($copy < $expected) {
    Math::MPFR::Rmpfr_nextabove($copy);
    return $obj if $copy >= $expected;
  }
  else {
    Math::MPFR::Rmpfr_nextbelow($copy);
    return $obj if $copy<= $expected;
  }
  return $expected;
}
