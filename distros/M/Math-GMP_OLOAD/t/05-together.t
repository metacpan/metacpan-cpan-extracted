# Just a re-run of the testing already conducted, but performs it in an environment
# where (potentially) the crossclass overloading of Math::GMP objects is done with
# Math::GMPz && Math::GMPq && Math::MPFR - rather than with just *one* of those modules.
# We also test that Math::GMP (non crossclass) overloading still produces correct
# results when Math::GMP_OLOAD has been loaded.
#
# All of which should be unnecessary ... and hopefully turns out ot be so.

use strict;
use warnings;
use Test::More;

my ($have_gmp, $have_gmpz, $have_gmpq, $have_mpfr) = (0, 0, 0, 0);
my @haves;

eval{ require Math::GMP;};
if(!$@ && $Math::GMP::VERSION >= 2.11) { $have_gmp = 1 }
else {
  plan skip_all => "SKIPPING: No reliable version of Math::GMP was loaded";
  done_testing();
  exit 0;
}

require Math::GMP_OLOAD;

eval { require Math::GMPz;};
push(@haves, 'Math::GMPz')
  if(!$@ && $Math::GMPz::VERSION >= '0.68');

eval { require Math::GMPq;};
push(@haves, 'Math::GMPq')
  if(!$@ && $Math::GMPq::VERSION >= '0.69');

eval { require Math::MPFR;};
push(@haves, 'Math::MPFR')
  if(!$@ && $Math::MPFR::VERSION >= '4.47');

if(@haves == 0) {
  plan skip_all => "SKIPPING: No suitably recent Math::GMPz, Math::GMPq or Math::MPFR was loaded";
  done_testing();
  exit 0;
}
print "@haves\n";
for my $mod(@haves) {
  warn "Overloading $mod objects with Math::GMP objects\n";
  my $gmp = Math::GMP->new(10);
  my $obj = $mod->new(-5);

  my $new1 = $obj + $gmp; # 5
  my $new2 = $gmp + $obj; # 5
  cmp_ok(ref($new1), 'eq', $mod, "1: correct object returned");
  cmp_ok($new1, '==', 5, "2: correct value returned");
  cmp_ok(ref($new2), 'eq', ref($new1), "3: correct object returned");
  cmp_ok($new2, '==', $new1, "4: correct value returned");
  cmp_ok( ($gmp <=> $new2) * -1, '==', ($new2 <=> $gmp), "4A: consistent <=> comparison");
  cmp_ok( ($gmp < $new2), '==', ($new2 > $gmp), "4B: consistent < comparison");
  cmp_ok( ($gmp <= $new2), '==', ($new2 >= $gmp), "4C: consistent <= comparison");
  cmp_ok( ($gmp > $new2), '==', ($new2 < $gmp), "4D: consistent > comparison");
  cmp_ok( ($gmp >= $new2), '==', ($new2 <= $gmp), "4E: consistent >= comparison");
  cmp_ok( ($gmp == $new2), '==', ($new2 == $gmp), "4F: consistent == comparison");
  cmp_ok( ($gmp != $new2), '==', ($new2 != $gmp), "4G: consistent != comparison");

  $new1 = $obj - $gmp; # -15
  $new2 = $gmp - $obj; # 15
  cmp_ok(ref($new1), 'eq', $mod, "5: correct object returned");
  cmp_ok($new1, '==', -15, "6: correct value returned");
  cmp_ok(ref($new2), 'eq', ref($new1), "7: correct object returned");
  cmp_ok($new2, '==', -$new1, "8: correct value returned");
  cmp_ok( ($gmp <=> $new2) * -1, '==', ($new2 <=> $gmp), "8A: consistent <=> comparison");
  cmp_ok( ($gmp < $new2), '==', ($new2 > $gmp), "8B: consistent < comparison");
  cmp_ok( ($gmp <= $new2), '==', ($new2 >= $gmp), "8C: consistent <= comparison");
  cmp_ok( ($gmp > $new2), '==', ($new2 < $gmp), "8D: consistent > comparison");
  cmp_ok( ($gmp >= $new2), '==', ($new2 <= $gmp), "8E: consistent >= comparison");
  cmp_ok( ($gmp == $new2), '==', ($new2 == $gmp), "8F: consistent == comparison");
  cmp_ok( ($gmp != $new2), '==', ($new2 != $gmp), "8G: consistent != comparison");

  $new1 = $obj * $gmp; # -50
  $new2 = $gmp * $obj; # -50
  cmp_ok(ref($new1), 'eq', $mod, "9: correct object returned");
  cmp_ok($new1, '==', -50, "10: correct value returned");
  cmp_ok(ref($new2), 'eq', ref($new1), "11: correct object returned");
  cmp_ok($new2, '==', $new1, "12: correct value returned");
  cmp_ok( ($gmp <=> $new2) * -1, '==', ($new2 <=> $gmp), "12A: consistent <=> comparison");
  cmp_ok( ($gmp < $new2), '==', ($new2 > $gmp), "12B: consistent < comparison");
  cmp_ok( ($gmp <= $new2), '==', ($new2 >= $gmp), "12C: consistent <= comparison");
  cmp_ok( ($gmp > $new2), '==', ($new2 < $gmp), "12D: consistent > comparison");
  cmp_ok( ($gmp >= $new2), '==', ($new2 <= $gmp), "12E: consistent >= comparison");
  cmp_ok( ($gmp == $new2), '==', ($new2 == $gmp), "12F: consistent == comparison");
  cmp_ok( ($gmp != $new2), '==', ($new2 != $gmp), "12G: consistent != comparison");

  $new1 = $obj / $gmp; # -5 / 10
  $new2 = $gmp / $obj; # 10 / -5
  if($mod eq 'Math::GMPz') {
    cmp_ok(ref($new1), 'eq', $mod, "13: correct object returned");
    cmp_ok($new1, '==', 0, "14: correct value returned");
    cmp_ok(ref($new2), 'eq', ref($new1), "15: correct object returned");
    cmp_ok($new2, '==', -2, "16: correct value returned");
  cmp_ok( ($gmp <=> $new2) * -1, '==', ($new2 <=> $gmp), "16A: consistent <=> comparison");
  cmp_ok( ($gmp < $new2), '==', ($new2 > $gmp), "16B: consistent < comparison");
  cmp_ok( ($gmp <= $new2), '==', ($new2 >= $gmp), "16C: consistent <= comparison");
  cmp_ok( ($gmp > $new2), '==', ($new2 < $gmp), "16D: consistent > comparison");
  cmp_ok( ($gmp >= $new2), '==', ($new2 <= $gmp), "16E: consistent >= comparison");
  cmp_ok( ($gmp == $new2), '==', ($new2 == $gmp), "16F: consistent == comparison");
  cmp_ok( ($gmp != $new2), '==', ($new2 != $gmp), "16G: consistent != comparison");
  }
  else {
    cmp_ok(ref($new1), 'eq', $mod, "13: correct object returned");
    cmp_ok($new1, '==', -0.5, "14: correct value returned");
    cmp_ok(ref($new2), 'eq', ref($new1), "15: correct object returned");
    cmp_ok($new2, '==', 1/$new1, "16: correct value returned");
    cmp_ok( ($gmp <=> $new2) * -1, '==', ($new2 <=> $gmp), "17: consistent <=> comparison");
    cmp_ok( ($gmp < $new2), '==', ($new2 > $gmp), "18: consistent < comparison");
    cmp_ok( ($gmp <= $new2), '==', ($new2 >= $gmp), "19: consistent <= comparison");
    cmp_ok( ($gmp > $new2), '==', ($new2 < $gmp), "20: consistent > comparison");
    cmp_ok( ($gmp >= $new2), '==', ($new2 <= $gmp), "21: consistent >= comparison");
    cmp_ok( ($gmp == $new2), '==', ($new2 == $gmp), "22: consistent == comparison");
    cmp_ok( ($gmp != $new2), '==', ($new2 != $gmp), "23: consistent != comparison");
  }

  if($mod eq 'Math::GMPz') {
    $new1 = $obj ** $gmp;
    cmp_ok(ref($new1), 'eq', $mod, "24: correct object returned");
    cmp_ok($new1, '==', 5 ** 10, "25: correct value returned");

    eval { $new2 = $gmp ** $obj;};
    like($@, qr/Exponent does not fit into unsigned long int in Math::GMPz::overload_pow/, "26: dies as expected");

    $new2 = $gmp ** -$obj;
    cmp_ok(ref($new2), 'eq', $mod, "27: correct object returned");
    cmp_ok($new2, '==', 10 ** 5, "28: correct value returned");

    cmp_ok( ($gmp <=> $new2) * -1, '==', ($new2 <=> $gmp), "29: consistent <=> comparison");
    cmp_ok( ($gmp < $new2), '==', ($new2 > $gmp), "30: consistent < comparison");
    cmp_ok( ($gmp <= $new2), '==', ($new2 >= $gmp), "31: consistent <= comparison");
    cmp_ok( ($gmp > $new2), '==', ($new2 < $gmp), "32: consistent > comparison");
    cmp_ok( ($gmp >= $new2), '==', ($new2 <= $gmp), "33: consistent >= comparison");
    cmp_ok( ($gmp == $new2), '==', ($new2 == $gmp), "34: consistent == comparison");
    cmp_ok( ($gmp != $new2), '==', ($new2 != $gmp), "35: consistent != comparison");
  }

  if($mod eq 'Math::GMPq') {
    $new1 = $obj ** $gmp;
    cmp_ok(ref($new1), 'eq', $mod, "36: correct object returned");
    cmp_ok($new1, '==', 5 ** 10, "37: correct value returned");

    eval { $new2 = $gmp ** $obj;};
    like($@, qr/Raising a value to an mpq_t power is not allowed in '\*\*' operation in Math::GMPq::overload_pow/, "38: dies as expected");

    eval { $new2 = $gmp ** -$obj;};
    like($@, qr/Raising a value to an mpq_t power is not allowed in '\*\*' operation in Math::GMPq::overload_pow/, "39: dies as expected");
  }

  if($mod eq 'Math::MPFR') {
    $gmp -= 8;
    $new1 = $obj ** $gmp; # -5 ** 2
    cmp_ok(ref($new1), 'eq', $mod, "40: correct object returned");
    cmp_ok($new1, '==', 25, "41: correct value returned");

    $new2 = $gmp ** $obj; # 2 ** -5
    cmp_ok(ref($new2), 'eq', $mod, "42: correct object returned");
    cmp_ok($new2, '==', 1 / (2 ** 5), "43: correct value returned");

    cmp_ok( ($gmp <=> $new2) * -1, '==', ($new2 <=> $gmp), "44: consistent <=> comparison");
    cmp_ok( ($gmp < $new2), '==', ($new2 > $gmp), "45: consistent < comparison");
    cmp_ok( ($gmp <= $new2), '==', ($new2 >= $gmp), "46: consistent <= comparison");
    cmp_ok( ($gmp > $new2), '==', ($new2 < $gmp), "47: consistent > comparison");
    cmp_ok( ($gmp >= $new2), '==', ($new2 <= $gmp), "48: consistent >= comparison");
    cmp_ok( ($gmp == $new2), '==', ($new2 == $gmp), "49: consistent == comparison");
    cmp_ok( ($gmp != $new2), '==', ($new2 != $gmp), "50: consistent != comparison");
    $gmp += 8; # Restore to original value.
  }
}

for my $n(4, '4', Math::GMP->new(4)) {
  my $gmp = Math::GMP->new(3);
  my($new1, $new2);

  $new1 = $gmp + $n;
  $new2 = $n + $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP + N returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N + GMP returns Math::GMP object");
  cmp_ok($new1, '==', 7, "GMP + N returns correct value");
  cmp_ok($new2, '==', $new1, "N + GMP consistent with GMP + N");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "51: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "52: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "53: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "54: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "55: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "56: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "57: consistent != comparison");

  $new1 = $gmp * $n;
  $new2 = $n * $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP * N returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N * GMP returns Math::GMP object");
  cmp_ok($new1, '==', 12, "GMP * N returns correct value");
  cmp_ok($new2, '==', $new1, "N * GMP consistent with GMP * N");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "58: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "59: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "60: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "61: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "62: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "63: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "64: consistent != comparison");

  $new1 = $gmp - $n;
  $new2 = $n - $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP - N returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N - GMP returns Math::GMP object");
  cmp_ok($new1, '==', -1, "GMP - N returns correct value");
  cmp_ok($new2, '==', -$new1, "N - GMP consistent with GMP - N");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "65: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "66: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "67: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "68: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "69: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "70: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "71: consistent != comparison");

  $new1 = $gmp / $n;
  $new2 = $n / $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP / N returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N / GMP returns Math::GMP object");
  cmp_ok($new1, '==', 0, "GMP / N returns correct value");
  cmp_ok($new2, '==', 1, "N / GMP consistent with GMP / N");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "72: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "73: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "74: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "75: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "76: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "77: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "78: consistent != comparison");

  $new1 = $gmp ** $n;
  $new2 = $n ** $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP ** N returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N ** GMP returns Math::GMP object");
  cmp_ok($new1, '==', 81, "GMP ** N returns correct value");
  cmp_ok($new2, '==', 64, "N ** GMP consistent with GMP ** N");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "79: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "80: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "81: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "82: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "83: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "84: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "85: consistent != comparison");
}

for my $n(4.9, '4.9') {
  my $gmp = Math::GMP->new(3);
  my($new1, $new2);

  $new1 = $gmp + $n;
  $new2 = $n + $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP + N(fraction) returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N(fraction) + GMP returns Math::GMP object");
  cmp_ok($new1, '==', 3, "GMP + N(fraction) returns correct value");
  cmp_ok($new2, '==', $new1, "N(fraction) + GMP consistent with GMP + N(fraction)");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "86: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "87: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "88: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "89: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "90: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "91: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "92: consistent != comparison");

  $new1 = $gmp * $n;
  $new2 = $n * $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP * N(fraction) returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N(fraction) * GMP returns Math::GMP object");
  cmp_ok($new1, '==', 0, "GMP * N(fraction) returns correct value");
  cmp_ok($new2, '==', $new1, "N(fraction) * GMP consistent with GMP * N(fraction)");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "93: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "94: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "95: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "96: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "97: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "98: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "99: consistent != comparison");

  $new1 = $gmp - $n;
  $new2 = $n - $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP - N(fraction) returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N(fraction) - GMP returns Math::GMP object");
  cmp_ok($new1, '==', 3, "GMP - N(fraction) returns correct value");
  cmp_ok($new2, '==', -$new1, "N(fraction) - GMP consistent with GMP - N(fraction)");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "100: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "101: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "102: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "103: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "104: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "105: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "106: consistent != comparison");

  # $new1 = $gmp / $n; # Crashes on division by zero
  $new2 = $n / $gmp;
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N(fraction) / GMP returns Math::GMP object");
  cmp_ok($new2, '==', 0, "N(fraction) / GMP consistent with GMP / N(fraction)");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "107: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "108: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "109: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "110: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "111: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "112: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "113: consistent != comparison");

  $new1 = $gmp ** $n; # The only GMP overloading operation that truncates $n
                      # to nearest integer rather than setting it to zero.
  $new2 = $n ** $gmp;
  cmp_ok(ref($new1), 'eq', 'Math::GMP', "GMP ** N(fraction) returns Math::GMP object");
  cmp_ok(ref($new2), 'eq', 'Math::GMP', "N(fraction) ** GMP returns Math::GMP object");
  cmp_ok($new1, '==', 81, "GMP ** N(fraction) returns correct value");
  cmp_ok($new2, '==', 0, "N(fraction) ** GMP consistent with GMP ** N(fraction)");
  cmp_ok( ($n <=> $new2) * -1, '==', ($new2 <=> $n), "114: consistent <=> comparison");
  cmp_ok( ($n < $new2), '==', ($new2 > $n), "115: consistent < comparison");
  cmp_ok( ($n <= $new2), '==', ($new2 >= $n), "116: consistent <= comparison");
  cmp_ok( ($n > $new2), '==', ($new2 < $n), "117: consistent > comparison");
  cmp_ok( ($n >= $new2), '==', ($new2 <= $n), "118: consistent >= comparison");
  cmp_ok( ($n == $new2), '==', ($new2 == $n), "119: consistent == comparison");
  cmp_ok( ($n != $new2), '==', ($new2 != $n), "120: consistent != comparison");
}

for my $n(4, '4', Math::GMP->new(4)) {
  my $gmp = Math::GMP->new(3);
  my($new1, $new2);

  $gmp **= $n;
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP **= integer returns GMP");
  cmp_ok($gmp, '==', 81, "GMP **= integer returns correct value");

  $gmp += $n;
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP += integer returns GMP");
  cmp_ok($gmp, '==', 85, "GMP += integer returns correct value");

  $gmp -= $n;
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP -= integer returns GMP");
  cmp_ok($gmp, '==', 81, "GMP -= integer returns correct value");

  $gmp *= $n;
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP *= integer returns GMP");
  cmp_ok($gmp, '==', 324, "GMP *= integer returns correct value");

  $gmp /= $n;
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP /= integer returns GMP");
  cmp_ok($gmp, '==', 81, "GMP /= integer returns correct value");
}

for my $n(4.9, '4.9') {
  my $gmp = Math::GMP->new(3);
  my($new1, $new2);

  $gmp **= $n; # Raises to the power of 4.
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP **= fraction returns GMP");
  cmp_ok($gmp, '==', 81, "GMP **= fraction truncates exponent to integer");

  $gmp += $n; # Adds on 0
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP += fraction returns GMP");
  cmp_ok($gmp, '==', 81, "GMP += fraction adds on 0");

  $gmp -= $n; # Subtracts 0
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP -= fraction returns GMP");
  cmp_ok($gmp, '==', 81, "GMP -= fraction subtracts 0");

  $gmp *= $n; # multiplies by 0
  cmp_ok(ref($gmp), 'eq', 'Math::GMP', "GMP *= fraction returns GMP");
  cmp_ok($gmp, '==', 0, "GMP *= fraction multiplies by 0");

  # $gmp /= $n; # Would crash on division by 0
}


done_testing();
