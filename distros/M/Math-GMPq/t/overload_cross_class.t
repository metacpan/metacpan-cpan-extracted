use warnings;
use strict;
use Math::GMPq;
use Config;

use Test::More;

my($rop, $op, $op_pow, $mpq);

eval {require Math::MPFR;};


unless($@) {
  if($Math::MPFR::VERSION < 4.19) {
    warn "\n  Skipping tests -  Math::MPFR version 4.19 (or later)\n" .
          "  is needed. We have only version $Math::MPFR::VERSION\n";
    is(1,1);
  }
  else {

    my $expected_refcnt = 1;
    $expected_refcnt++
      if $Config{ccflags} =~ /\-DPERL_RC_STACK/;

    # Run the tests.
    $op = Math::MPFR->new(100);
    $op_pow = Math::MPFR->new(3.5);
    $mpq = Math::GMPq->new(10075);

    cmp_ok(Math::GMPq::get_refcnt($op), '==', $expected_refcnt, '1: $op reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($op_pow), '==', $expected_refcnt, '1: $op_pow reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($mpq), '==', $expected_refcnt, '1: $mpq reference count as expected');

    $rop = $mpq + $op;
    cmp_ok(ref($rop), 'eq', 'Math::MPFR', '1: Math::MPFR object reurned');
    cmp_ok($rop, '==', 10175, 'returned Math::MPFR object == 10175');

    cmp_ok(Math::GMPq::get_refcnt($op), '==', $expected_refcnt, '2: $op reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($rop), '==', $expected_refcnt, '2: $rop reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($mpq), '==', $expected_refcnt, '2: $mpq reference count as expected');

    $rop = $mpq * $op;

    cmp_ok(Math::GMPq::get_refcnt($op), '==', $expected_refcnt, '3: $op reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($rop), '==', $expected_refcnt, '3: $rop reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($mpq), '==', $expected_refcnt, '3: $mpq reference count as expected');

    cmp_ok(ref($rop), 'eq', 'Math::MPFR', '2: Math::MPFR object reurned');
    cmp_ok($rop, '==', 1007500, 'returned Math::MPFR object == 1007500');

    $rop = $mpq - $op;

    cmp_ok(Math::GMPq::get_refcnt($op), '==', $expected_refcnt, '4: $op reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($rop), '==', $expected_refcnt, '4: $rop reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($mpq), '==', $expected_refcnt, '4: $mpq reference count as expected');

    cmp_ok(ref($rop), 'eq', 'Math::MPFR', '3: Math::MPFR object reurned');
    cmp_ok($rop, '==', 9975, 'returned Math::MPFR object == 9975');

    $rop = $mpq / $op;

    cmp_ok(Math::GMPq::get_refcnt($op), '==', $expected_refcnt, '5: $op reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($rop), '==', $expected_refcnt, '5: $rop reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($mpq), '==', $expected_refcnt, '5: $mpq reference count as expected');

    cmp_ok(ref($rop), 'eq', 'Math::MPFR', '4: Math::MPFR object reurned');
    cmp_ok($rop, '==', 100.75, 'returned Math::MPFR object == 100.75');

    $mpq /= 100;
    $mpq -= 0.75;

    cmp_ok(Math::GMPq::get_refcnt($mpq), '==', $expected_refcnt, '6: $mpq reference count as expected');

    $rop = $mpq ** $op_pow;

    cmp_ok(Math::GMPq::get_refcnt($op_pow), '==', $expected_refcnt, '7: $op_pow reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($rop), '==', $expected_refcnt, '7: $rop reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($mpq), '==', $expected_refcnt, '7: $mpq reference count as expected');

    cmp_ok(ref($rop), 'eq', 'Math::MPFR', '5: Math::MPFR object reurned');
    cmp_ok($rop, '==', 10000000, 'returned Math::MPFR object == 10000000');

    my $ccount = Math::GMPq::_wrap_count();

    for(1..100) {
      $rop = $mpq + $op;
      $rop = $mpq - $op;
      $rop = $mpq * $op;
      $rop = $mpq / $op;
      $rop = $mpq ** $op_pow;
    }

    my $ncount = Math::GMPq::_wrap_count();

    cmp_ok($ccount, '==', $ncount, "counts match");

    if($ccount != $ncount) {
      warn "Looks like we have a memory leak\n" if $ncount > $ccount;
    }

    cmp_ok(Math::GMPq::get_refcnt($op_pow), '==', $expected_refcnt, '8: $op_pow reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($rop), '==', $expected_refcnt, '8: $rop reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($mpq), '==', $expected_refcnt, '8: $mpq reference count as expected');
    cmp_ok(Math::GMPq::get_refcnt($op), '==', $expected_refcnt, '8: $op reference count as expected');
  }

  my $mpq = Math::GMPq->new('5/4');

  my $ok = 0;
  $ok = 1 if !defined($mpq <=> Math::MPFR->new());
  cmp_ok($ok, '==', 1, "GMPQ <==> MPFR(NaN) not defined");

  $ok = 0;
  $ok = 1 if !defined(Math::MPFR->new() <=> $mpq);
  cmp_ok($ok, '==', 1, "MPFR(NaN) <==> GMPQ not defined");

  $ok = 0;
  my $res = ($mpq == Math::MPFR->new());
  $ok = 1 if(defined($res) && $res == 0);
  cmp_ok($ok, '==', 1, "GMPQ == MPFR(NaN) returns 0");

  $ok = 0;
  $res = (Math::MPFR->new() == $mpq);
  $ok = 1 if(defined($res) && $res == 0);
  cmp_ok($ok, '==', 1, "MPFR(NaN) == GMPQ returns 0");

  $ok = 0;
  $res = ($mpq != Math::MPFR->new());
  $ok = 1 if(defined($res) && $res == 1);
  cmp_ok($ok, '==', 1, "GMPQ != MPFR(NaN) returns 1");

  $ok = 0;
  $res = (Math::MPFR->new() != $mpq);
  $ok = 1 if(defined($res) && $res == 1);
  cmp_ok($ok, '==', 1, "MPFR(NaN) != GMPQ returns 1");

  if($Math::MPFR::VERSION >= 4.19) {
    for my $mpfr(Math::MPFR->new(2.5), Math::MPFR->new(1.25), Math::MPFR->new(0.5)) {
      cmp_ok(($mpq > $mpfr), '==',  ($mpfr < $mpq),  "$mpfr: '>'  ok");
      cmp_ok(($mpq < $mpfr), '==' , ($mpfr > $mpq),  "$mpfr: '<'  ok");
      cmp_ok(($mpq == $mpfr), '==', ($mpfr == $mpq), "$mpfr: '==' ok");
      cmp_ok(($mpq != $mpfr), '==', ($mpfr != $mpq), "$mpfr: '!=' ok");
      cmp_ok(($mpq >= $mpfr), '==', ($mpfr <= $mpq), "$mpfr: '>=' ok");
      cmp_ok(($mpq <= $mpfr), '==', ($mpfr >= $mpq), "$mpfr: '<=' ok");

      cmp_ok(($mpq <=> $mpfr), '==', ($mpfr <=> $mpq) * -1, "$mpfr: '<=>' ok");
    }
  }
}
else {
  warn "\nSkipping tests - no Math::MPFR\n";
  is(1,1);
}

# Check that the &PL_sv_yes bug
# does not rear its ugly head here
# See https://github.com/sisyphus/math-decimal64/pull/1

sub hmmmm () {!0}
sub aaarh () {!1}

done_testing();
