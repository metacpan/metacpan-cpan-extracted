# Test cross class overloading of +=, *=, -=, /=,
# and **= for the cases where the second arg is a
# Math::MPFR object.
# In these cases the operation returns a Math::MPFR object

use strict;
use warnings;
use Math::GMPq qw(:mpq);

use Test::More;

my $have_mpfr = 0;
eval {require Math::MPFR;};
$have_mpfr = 1 unless $@;

my $q  = Math::GMPq->new('1/11');
my $fr = 0;
$fr = Math::MPFR->new(17.1) if $have_mpfr;

############################################

if($have_mpfr) {

  if($Math::MPFR::VERSION < 4.19) {
    is(1,1);
    warn "\n  Skipping remaining tests -  Math::MPFR version 4.19 (or later)\n" .
          "  is needed. We have only version $Math::MPFR::VERSION\n";
    done_testing();
    exit 0;
  }
  else {

    $q = Math::GMPq->new('1/11');
    cmp_ok(ref($q), 'eq', 'Math::GMPq', '$q is a Math::GMPq object');
    $q *= $fr;
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', $fr * Math::GMPq->new('1/11'), '$q *= $fr sets $q to 1.5545454545454547');

    $q = Math::GMPq->new('1/11');
    cmp_ok(ref($q), 'eq', 'Math::GMPq', '$q has been reverted to a Math::GMPq object');
    $q += $fr;
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', $fr + Math::GMPq->new('1/11'), '$q += $fr sets $q to 1.7190909090909091e1');

    $q = Math::GMPq->new('1/11');
    $q -= $fr;
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', Math::GMPq->new('1/11') - $fr, '$q -= $fr sets $z to -1.7009090909090911e1');

    $q = Math::GMPq->new('1/11');
    $q /= $fr;
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', Math::GMPq->new('1/11') / $fr, '$q /= $fr sets $q to 5.3163211057947893e-3');

    $q = Math::GMPq->new(2);
    $q **= Math::MPFR->new(0.5);
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', Math::GMPq->new(2) ** Math::MPFR->new(0.5), '$q **= $Math::MPFR->new(0.5) sets $q to 1.4142135623730951');

    $q = Math::GMPq->new(2);
    Math::MPFR::Rmpfr_set_default_prec(113);
    $q **= Math::MPFR->new(0.5);
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', Math::GMPq->new(2) ** Math::MPFR->new(0.5), '$q **= Math::MPFR->new(0.5) sets $z to 1.41421356237309504880168872420969798');

    ###########################################################
    # Some further checks on using Math::MPFR objects with    #
    # with the overloaded Math::GMPq operations - including   #
    # examination of the precision of the returned Math::MPFR #
    # objects. ################################################
    ###########################################################

    for my $p(30, 53, 64, 113, 120) {

    ############################################################
      {
      Math::MPFR::Rmpfr_set_default_prec($p);
      my $mpfr_op = Math::MPFR::Rmpfr_init2(100);
      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0);
      my $gmpq_op = Rmpq_init();
      Rmpq_set_NV($gmpq_op,3.5);

      my($c1, $c2) = ($mpfr_op + $gmpq_op, $gmpq_op + $mpfr_op);
      cmp_ok($c1, '==', $c2, "$p: '+' is commutative");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "$p: \$c1: correct precision returned for '+' op");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "$p: \$c2: correct precision returned for '+' op");

      $mpfr_op += $gmpq_op;
      my $c3 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($mpfr_op));
      Math::MPFR::Rmpfr_set($c3, $mpfr_op, 0);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c3), '==', 100, "$p: \$c3: correct precision returned for '+=' op");

      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0); # Reset to original value

      $gmpq_op += $mpfr_op;
      my $c4 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($gmpq_op));
      Math::MPFR::Rmpfr_set($c4, $gmpq_op, 0);

      cmp_ok(Math::MPFR::Rmpfr_get_prec($c4), '==', $p, "$p: \$c4: correct precision returned for '+=' op");

      cmp_ok($c3, '==', $c4, "$p: '*=' is commutative");
      cmp_ok($c1, '==', $c4, "$p: '*=' and '*' returned same value"); # Not guaranteed in general
      }
    ############################################################
    ############################################################
      {
      Math::MPFR::Rmpfr_set_default_prec($p);
      my $mpfr_op = Math::MPFR::Rmpfr_init2(100);
      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0);
      my $gmpq_op = Rmpq_init();
      Rmpq_set_NV($gmpq_op, 3.5);

      my ($c1, $c2) = ($mpfr_op * $gmpq_op, $gmpq_op * $mpfr_op);
      cmp_ok($c1, '==', $c2, "$p: '*' is commutative");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "$p: \$c1: correct precision returned for '*' op");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "$p: \$c2: correct precision returned for '*' op");

      $mpfr_op *= $gmpq_op;
      my $c3 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($mpfr_op));
      Math::MPFR::Rmpfr_set($c3, $mpfr_op, 0);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c3), '==', 100, "$p: \$c3: correct precision returned for '*=' op");

      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0); # Reset to original value

      $gmpq_op *= $mpfr_op;
      my $c4 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($gmpq_op));
      Math::MPFR::Rmpfr_set($c4, $gmpq_op, 0);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c4), '==', $p, "$p: \$c4: correct precision returned for '*=' op");

      cmp_ok($c3, '==', $c4, "$p: '*=' is commutative");
      cmp_ok($c1, '==', $c4, "$p: '*=' and '*' returned same value"); # Not guaranteed in general
      }
    ############################################################
    ############################################################
      {
      Math::MPFR::Rmpfr_set_default_prec($p);
      my $mpfr_op = Math::MPFR::Rmpfr_init2(100);
      my $mpfr_inv = Math::MPFR::Rmpfr_init2(100);
      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0);
      my $gmpq_op = Rmpq_init();
      Rmpq_set_NV($gmpq_op,3.5);
      my $gmpq_inv = Rmpq_init();
      Rmpq_inv($gmpq_inv, $gmpq_op); # Reciprocals
      my $gmpq_op_copy = Rmpq_init();
      Rmpq_set_NV($gmpq_op_copy, 3.5);

      my ($c1, $c2) = ($mpfr_op / $gmpq_op, $gmpq_op / $mpfr_op);
      my ($d1, $d2) = ($mpfr_op * $gmpq_inv, $gmpq_op * (1 /$mpfr_op));
      cmp_ok($c1, '==', $d1, "$p: '/' and '*' reciprocate as expected");
#     cmp_ok($c2, '==', $d2, "$p: '/' and '*' (again) reciprocate as expected"); # orig, replaced by next line.
      cmp_ok($c2, '==', _approx($c2,$d2), "$p: '/' and '*' (again) reciprocate as expected");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "$p: \$c1: correct precision returned for '/' op");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "$p: \$c2: correct precision returned for '/' op");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($d1), '==', $p, "$p: \$d1: correct precision returned for inverted '*' op");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($d2), '==', $p, "$p: \$d2: correct precision returned for inverted '*' op");

      $mpfr_op /= $gmpq_op;
      my $c3 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($mpfr_op));
      my $d3 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($mpfr_op));
      Math::MPFR::Rmpfr_set($c3, $mpfr_op, 0);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c3), '==', 100, "$p: \$c3: correct precision returned for '/=' op");

      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0); # Reset to original value

      $mpfr_op *= $gmpq_inv;
      Math::MPFR::Rmpfr_set($d3, $mpfr_op, 0);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($d3), '==', 100, "$p: \$d3: correct precision returned for inverted '*=' op");

      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0); # Reset to original value

      $gmpq_op /= $mpfr_op;
      my $c4 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($gmpq_op));
      Math::MPFR::Rmpfr_set($c4, $gmpq_op, 0);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c4), '==', $p, "$p: \$c4: correct precision returned for '/=' op");

      Math::MPFR::Rmpfr_ui_div($mpfr_inv, 1, $mpfr_op, 0);
      $gmpq_op_copy *= $mpfr_inv;
      my $d4 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($gmpq_op_copy));
      Math::MPFR::Rmpfr_set($d4, $gmpq_op_copy, 0);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($d4), '==', $p, "$p: \$c4: correct precision returned for '/=' op");

      cmp_ok($c3, '==', $d3, "$p: inversion of '/=' with '*=' equates");
      unless($p > 100) {
        cmp_ok($c4, '==', _approx($c4,$d4), "$p: inversion of '*=' with '/=' equates");
      } # close unless{}
      }
    ############################################################
    ############################################################
      if($Math::MPFR::VERSION >= 4.35) {
        Math::MPFR::Rmpfr_set_default_prec($p);
        my $mpfr_op = Math::MPFR::Rmpfr_init2(100);
        Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0);
        my $gmpq_op = Rmpq_init();
        Rmpq_set_NV($gmpq_op,22.8125);

        my($c1, $c2) = ($mpfr_op % $gmpq_op, $gmpq_op % $mpfr_op);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "$p: \$c1: correct precision returned for '%' op");
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "$p: \$c2: correct precision returned for '%' op");
        cmp_ok($c1, '==', 2.5, "$p: \$c1: value unaltered for '%' op");
        cmp_ok($c2, '==', 0.3125, "$p: \$c2: correct value for '%' op");

        $mpfr_op %= $gmpq_op;
        my $c3 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($mpfr_op));
        Math::MPFR::Rmpfr_set($c3, $mpfr_op, 0);
        cmp_ok(Math::MPFR::Rmpfr_get_prec($c3), '==', 100, "$p: \$c3: correct precision returned for '%=' op");
        cmp_ok($c3, '==', 2.5, "$p: \$c3: value unaltered for '%=' op");

        Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0); # Reset to original value

        cmp_ok(Math::MPFR::Rmpfr_get_prec($mpfr_op), '==', 100, "$p: \$mpfr_op: correct precision returned for '%=' op");

        $gmpq_op %= $mpfr_op;
        cmp_ok(Math::MPFR::Rmpfr_get_prec($gmpq_op), '==', $p, "$p: \$gmpq_op: correct precision returned for '%=' op");
        my $c4 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($gmpq_op));
        Math::MPFR::Rmpfr_set($c4, $gmpq_op, 0);

        cmp_ok(Math::MPFR::Rmpfr_get_prec($c4), '==', $p, "$p: \$c4: correct precision returned for '%=' op");
        cmp_ok($c4, '==', 0.3125, "$p: \$c4: correct value for '%=' op");
      }
      else {
        warn "Skipping some '%' and '%=' overloading tests as Math-MPFR-4.35 or later is required - have only $Math::MPFR::VERSION\n";
      }
    ############################################################
    ############################################################
      {
      Math::MPFR::Rmpfr_set_default_prec($p);
      my $mpfr_op = Math::MPFR::Rmpfr_init2(100);
      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0);
      my $gmpq_op = Rmpq_init();
      Rmpq_set_NV($gmpq_op,4.0);

      my($c1, $c2) = ($mpfr_op ** $gmpq_op, $gmpq_op ** $mpfr_op);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c1), '==', $p, "$p: \$c1: correct precision returned for '**' op");
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c2), '==', $p, "$p: \$c2: correct precision returned for '**' op");
      cmp_ok($c1, '==', 39.0625, "$p: \$c1: value set to 39.0625for '**' op");
      cmp_ok($c2, '==', 32, "$p: \$c2: value set to 32 for '**' op");

      $mpfr_op **= $gmpq_op;
      my $c3 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($mpfr_op));
      Math::MPFR::Rmpfr_set($c3, $mpfr_op, 0);
      cmp_ok(Math::MPFR::Rmpfr_get_prec($c3), '==', 100, "$p: \$c3: correct precision returned for '**=' op");

      cmp_ok($c3, '==', 39.0625, "$p: \$c3: value set to 39.0625 for '**=' op");

      Math::MPFR::Rmpfr_set_NV($mpfr_op, 2.5, 0); # Reset to original value

      cmp_ok(Math::MPFR::Rmpfr_get_prec($mpfr_op), '==', 100, "$p: \$mpfr_op: correct precision returned for '**=' op");

      $gmpq_op **= $mpfr_op;
      cmp_ok(Math::MPFR::Rmpfr_get_prec($gmpq_op), '==', $p, "$p: \$gmpq_op: correct precision returned for '**=' op");
      my $c4 = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($gmpq_op));
      Math::MPFR::Rmpfr_set($c4, $gmpq_op, 0);

      cmp_ok(Math::MPFR::Rmpfr_get_prec($c4), '==', $p, "$p: \$c4: correct precision returned for '**=' op");
      cmp_ok($c4, '==', 32, "$p: \$c4: set to 32 for '**=' op");
      }
    ############################################################

    }
  }
}
else {
  is(1,1);
  warn "Skipping all tests - could not load Math::MPFR";
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
