use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..4\n";

my ($have_gmpq, $have_gmpz, $have_gmp) = (0, 0, 0);
my ($mpq, $mpz, $gmp);
my $str = '12345';
my $double = 0.5;
my $ui = 4294967295;
my $max_even = 4294967294;
my $si = (($ui - 1) / 2) * -1;
my $nan = Rmpfr_get_d(Math::MPFR->new(), GMP_RNDN);
my $mpfi_nan = Math::MPFI->new();
my $prec = 95;

Rmpfi_set_default_prec($prec);

########################################## TEST 1

my $ok = '';

if($] eq '5.008') {
  warn "Skipping 1a as it might be that NaN == NaN on this build of perl";
  $ok .= 'a';
}
else {
  if($nan != $nan) {$ok .= 'a'}
  else { warn "1a: nan == nan on this perl\n"}
}

unless($mpfi_nan == $mpfi_nan) {$ok .= 'b'}
else {warn "1b: \$mpfi_nan == \$mpfi_nan\n"}

if($mpfi_nan != $mpfi_nan) {$ok .= 'c'}
else {warn "1c: \$mpfi_nan == \$mpfi_nan\n"}

unless($mpfi_nan < $mpfi_nan) {$ok .= 'd'}
else {warn "1d: \$mpfi_nan < \$mpfi_nan\n"}

unless($mpfi_nan > $mpfi_nan) {$ok .= 'e'}
else {warn "1e: \$mpfi_nan > \$mpfi_nan\n"}

if(!defined($mpfi_nan <=> $mpfi_nan)) {$ok .= 'f'}
else {warn "1f: Got ", $mpfi_nan <=> $mpfi_nan, "\nExpected undef\n"}

unless($mpfi_nan == $nan) {$ok .= 'g'}
else {warn "1g: \$mpfi_nan == \$nan\n"}

if($mpfi_nan != $nan) {$ok .= 'h'}
else {warn "1h: \$mpfi_nan == \$nan\n"}

unless($mpfi_nan < $nan) {$ok .= 'i'}
else {warn "1i: \$mpfi_nan < \$nan\n"}

unless($mpfi_nan > $nan) {$ok .= 'j'}
else {warn "1j: \$mpfi_nan > \$nan\n"}

if(!defined($mpfi_nan <=> $nan)) {$ok .= 'k'}
else {warn "1k: Got ", $mpfi_nan <=> $nan, "\nExpected undef\n"}

unless($mpfi_nan == $double) {$ok .= 'l'}
else {warn "1l: \$mpfi_nan == \$double\n"}

if($mpfi_nan != $double) {$ok .= 'm'}
else {warn "1m: \$mpfi_nan == \$double\n"}

unless($mpfi_nan < $double) {$ok .= 'n'}
else {warn "1n: \$mpfi_nan < \$double\n"}

unless($mpfi_nan > $double) {$ok .= 'o'}
else {warn "1o: \$mpfi_nan > \$double\n"}

if(!defined($mpfi_nan <=> $double)) {$ok .= 'p'}
else {warn "1p: Got ", $mpfi_nan <=> $nan, "\nExpected undef\n"}

unless($mpfi_nan == $ui) {$ok .= 'q'}
else {warn "1q: \$mpfi_nan == \$ui\n"}

if($mpfi_nan != $ui) {$ok .= 'r'}
else {warn "1r: \$mpfi_nan == \$ui\n"}

unless($mpfi_nan < $ui) {$ok .= 's'}
else {warn "1s: \$mpfi_nan < \$ui\n"}

unless($mpfi_nan > $ui) {$ok .= 't'}
else {warn "1t: \$mpfi_nan > \$ui\n"}

if(!defined($mpfi_nan <=> $ui)) {$ok .= 'u'}
else {warn "1u: Got ", $mpfi_nan <=> $ui, "\nExpected undef\n"}

unless($mpfi_nan == $si) {$ok .= 'v'}
else {warn "1v: \$mpfi_nan == \$si\n"}

if($mpfi_nan != $si) {$ok .= 'w'}
else {warn "1w: \$mpfi_nan == \$si\n"}

unless($mpfi_nan < $si) {$ok .= 'x'}
else {warn "1x: \$mpfi_nan < \$si\n"}

unless($mpfi_nan > $si) {$ok .= 'y'}
else {warn "1y: \$mpfi_nan > \$si\n"}

if(!defined($mpfi_nan <=> $si)) {$ok .= 'z'}
else {warn "1z: Got ", $mpfi_nan <=> $si, "\nExpected undef\n"}

unless($mpfi_nan == $str) {$ok .= 'A'}
else {warn "1A: \$mpfi_nan == \$str\n"}

if($mpfi_nan != $str) {$ok .= 'B'}
else {warn "1B: \$mpfi_nan == \$str\n"}

unless($mpfi_nan < $str) {$ok .= 'C'}
else {warn "1C: \$mpfi_nan < \$str\n"}

unless($mpfi_nan > $str) {$ok .= 'D'}
else {warn "1D: \$mpfi_nan > \$str\n"}

if(!defined($mpfi_nan <=> $str)) {$ok .= 'E'}
else {warn "1E: Got ", $mpfi_nan <=> $str, "\nExpected undef\n"}

if($ok eq 'abcdefghijklmnopqrstuvwxyzABCDE') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

########################################## TEST 2

$ok = '';

unless($nan == $mpfi_nan) {$ok .= 'g'}
else {warn "2g: \$nan == \$mpfi_nan\n"}

if($nan != $mpfi_nan) {$ok .= 'h'}
else {warn "2h: \$nan == \$mpfi_nan\n"}

unless($nan < $mpfi_nan) {$ok .= 'i'}
else {warn "2i: \$nan < \$mpfi_nan\n"}

unless($nan > $mpfi_nan) {$ok .= 'j'}
else {warn "2j: \$nan > \$mpfi_nan\n"}

if(!defined($nan <=> $mpfi_nan)) {$ok .= 'k'}
else {warn "2k: Got ", $nan <=> $mpfi_nan, "\nExpected undef\n"}

unless($double == $mpfi_nan) {$ok .= 'l'}
else {warn "2l: \$double == \$mpfi_nan\n"}

if($double != $mpfi_nan) {$ok .= 'm'}
else {warn "2m: \$double == \$mpfi_nan\n"}

unless($double < $mpfi_nan) {$ok .= 'n'}
else {warn "2n: \$double < \$mpfi_nan\n"}

unless($double > $mpfi_nan) {$ok .= 'o'}
else {warn "2o: \$double > \$mpfi_nan\n"}

if(!defined($double <=> $mpfi_nan)) {$ok .= 'p'}
else {warn "2p: Got ", $nan <=> $mpfi_nan, "\nExpected undef\n"}

unless($ui == $mpfi_nan) {$ok .= 'q'}
else {warn "2q: \$ui == \$mpfi_nan\n"}

if($ui != $mpfi_nan) {$ok .= 'r'}
else {warn "2r: \$ui == \$mpfi_nan\n"}

unless($ui < $mpfi_nan) {$ok .= 's'}
else {warn "2s: \$ui < \$mpfi_nan\n"}

unless($ui > $mpfi_nan) {$ok .= 't'}
else {warn "2t: \$ui > \$mpfi_nan\n"}

if(!defined($ui <=> $mpfi_nan)) {$ok .= 'u'}
else {warn "2u: Got ", $ui <=> $mpfi_nan, "\nExpected undef\n"}

unless($si == $mpfi_nan) {$ok .= 'v'}
else {warn "2v: \$si == \$mpfi_nan\n"}

if($si != $mpfi_nan) {$ok .= 'w'}
else {warn "2w: \$si != \$mpfi_nan\n"}

unless($si < $mpfi_nan) {$ok .= 'x'}
else {warn "2x: \$si < \$mpfi_nan\n"}

unless($si > $mpfi_nan) {$ok .= 'y'}
else {warn "2y: \$si > $mpfi_nan\n"}

if(!defined($si <=> $mpfi_nan)) {$ok .= 'z'}
else {warn "2z: Got ", $si <=> $mpfi_nan, "\nExpected undef\n"}

unless($str == $mpfi_nan) {$ok .= 'A'}
else {warn "2A: \$str == \$mpfi_nan\n"}

if($str != $mpfi_nan) {$ok .= 'B'}
else {warn "2B: \$str\n != \$mpfi_nan"}

unless($str < $mpfi_nan) {$ok .= 'C'}
else {warn "2C: \$str < \$mpfi_nan\n"}

unless($str > $mpfi_nan) {$ok .= 'D'}
else {warn "2D: \$str > \$mpfi_nan\n"}

if(!defined($str <=> $mpfi_nan)) {$ok .= 'E'}
else {warn "2E: Got ", $str <=> $mpfi_nan, "\nExpected undef\n"}

if($ok eq 'ghijklmnopqrstuvwxyzABCDE') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

########################################## TEST 3

$ok = '';

my $mpfi = Math::MPFI->new(0.5);

if($mpfi == $mpfi) {$ok .= 'a'}
else {
  warn "3a: Got: ", $mpfi == $mpfi, "\nExpected a true value\n";
}

if($mpfi < $mpfi + 1) {$ok .= 'b'}
else {
  warn "3b: Got: ", $mpfi < $mpfi + 1, "\nExpected a true value\n";
}

if($mpfi + 1 > $mpfi) {$ok .= 'c'}
else {
  warn "3c: Got: ", $mpfi+ 1 > $mpfi, "\nExpected a true value\n";
}

if($mpfi == $double) {$ok .= 'd'}
else {
  warn "3d: Got: ", $mpfi == $double, "\nExpected a true value\n";
}

if($double == $mpfi) {$ok .= 'D'}
else {
  warn "3D: Got: ", $double == $mpfi, "\nExpected a true value\n";
}

if($mpfi < $double + 1) {$ok .= 'e'}
else {
  warn "3e: Got: ", $mpfi < $double + 1, "\nExpected a true value\n";
}

if($double + 1 > $mpfi) {$ok .= 'E'}
else {
  warn "3E: Got: ", $double + 1 > $mpfi, "\nExpected a true value\n";
}

if($mpfi + 1 > $double) {$ok .= 'f'}
else {
  warn "3f: Got: ", $mpfi+ 1 > $double, "\nExpected a true value\n";
}

if($double < $mpfi + 1) {$ok .= 'F'}
else {
  warn "3F: Got: ", $double < $mpfi + 1, "\nExpected a true value\n";
}

if(($mpfi <=> $double) == 0 && ($mpfi <=> $double + 1) < 0 && ($mpfi <=> $double - 1) > 0) {$ok .= 'g'}
else {warn "3g: Expected true values, but got at least one false value\n"}

if(($double <=> $mpfi) == 0 && ($double + 1 <=> $mpfi) > 0 && ($double - 1 <=> $mpfi) < 0) {$ok .= 'G'}
else {warn "3G: Expected true values, but got at least one false value\n"}

Rmpfi_set_ui($mpfi, $max_even);

if($mpfi == $max_even) {$ok .= 'h'}
else {
  warn "3h: Got: ", $mpfi == $max_even, "\nExpected a true value\n";
}

if($max_even == $mpfi) {$ok .= 'H'}
else {
  warn "3H: Got: ", $max_even == $mpfi, "\nExpected a true value\n";
}

if($mpfi < $ui) {$ok .= 'i'}
else {
  warn "3i: Got: ", $mpfi < $ui, "\nExpected a true value\n";
}

if($ui > $mpfi) {$ok .= 'I'}
else {
  warn "3I: Got: ", $ui > $mpfi, "\nExpected a true value\n";
}

if($mpfi + 1 > $max_even) {$ok .= 'j'}
else {
  warn "3j: Got: ", $mpfi + 1 > $max_even, "\nExpected a true value\n";
}

if($max_even < $mpfi + 1) {$ok .= 'J'}
else {
  warn "3J: Got: ", $max_even < $mpfi + 1, "\nExpected a true value\n";
}

if(($mpfi <=> $max_even) == 0 && ($mpfi <=> $max_even + 1) < 0 && ($mpfi <=> $max_even - 1) > 0) {$ok .= 'k'}
else {warn "3k: Expected true values, but got at least one false value\n"}

if(($max_even <=> $mpfi) == 0 && ($max_even + 1 <=> $mpfi) > 0 && ($max_even - 1 <=> $mpfi) < 0) {$ok .= 'K'}
else {warn "3K: Expected true values, but got at least one false value\n"}

Rmpfi_set_si($mpfi, $si + 1);

if($mpfi == $si + 1) {$ok .= 'l'}
else {
  warn "3l: Got: ", $mpfi == $si + 1, "\nExpected a true value\n";
}

if($si + 1 == $mpfi) {$ok .= 'L'}
else {
  warn "3L: Got: ", $si + 1 == $mpfi, "\nExpected a true value\n";
}

if($mpfi < $si + 2) {$ok .= 'm'}
else {
  warn "3m: Got: ", $mpfi < $si + 2, "\nExpected a true value\n";
}

if($si + 2 > $mpfi) {$ok .= 'M'}
else {
  warn "3M: Got: ", $si + 2 > $mpfi, "\nExpected a true value\n";
}

if($mpfi > $si) {$ok .= 'n'}
else {
  warn "3n: Got: ", $mpfi > $si, "\nExpected a true value\n";
}

if($si < $mpfi) {$ok .= 'N'}
else {
  warn "3N: Got: ", $si < $mpfi, "\nExpected a true value\n";
}

if(($mpfi <=> $si + 1) == 0 && ($mpfi <=> $si + 2) < 0 && ($mpfi <=> $si) > 0) {$ok .= 'o'}
else {warn "3o: Expected true values, but got at least one false value\n"}

if(($si + 1 <=> $mpfi) == 0 && ($si + 2 <=> $mpfi) > 0 && ($si <=> $mpfi) < 0) {$ok .= 'O'}
else {warn "3O: Expected true values, but got at least one false value\n"}

Rmpfi_set_str($mpfi, $str, 10);

if($mpfi == $str) {$ok .= 'p'}
else {
  warn "3p: Got: ", $mpfi == $str, "\nExpected a true value\n";
}

if($str == $mpfi) {$ok .= 'P'}
else {
  warn "3P: Got: ", $str == $mpfi, "\nExpected a true value\n";
}

if($mpfi - 1 < $str) {$ok .= 'q'}
else {
  warn "3q: Got: ", $mpfi - 1 < $str, "\nExpected a true value\n";
}

if($str > $mpfi - 1) {$ok .= 'Q'}
else {
  warn "3Q: Got: ", $str > $mpfi - 1, "\nExpected a true value\n";
}

if($mpfi + 1 > $str) {$ok .= 'r'}
else {
  warn "3r: Got: ", $mpfi+ 1 > $str, "\nExpected a true value\n";
}

if($str < $mpfi + 1) {$ok .= 'R'}
else {
  warn "3R: Got: ", $str < $mpfi + 1, "\nExpected a true value\n";
}

if(($mpfi <=> $str) == 0 && ($mpfi - 1 <=> $str) < 0 && ($mpfi + 1 <=> $str) > 0) {$ok .= 's'}
else {warn "3s: Expected true values, but got at least one false value\n"}

if(($str <=> $mpfi) == 0 && ($str <=> $mpfi - 1) > 0 && ($str <=> $mpfi + 1) < 0) {$ok .= 'S'}
else {warn "3S: Expected true values, but got at least one false value\n"}

if($ok eq 'abcdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsS') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

########################################## TEST 4

$ok = '';
Rmpfi_set_d($mpfi, 0.5);

if($mpfi <= $mpfi && $mpfi >= $mpfi) {$ok .= 'a'}
else {
  warn "4a: Expected true values, but got at least one false value\n";
}

if($mpfi <= $mpfi + 1) {$ok .= 'b'}
else {
  warn "4b: Got: ", $mpfi <= $mpfi + 1, "\nExpected a true value\n";
}

if($mpfi + 1 >= $mpfi) {$ok .= 'c'}
else {
  warn "4c: Got: ", $mpfi+ 1 >= $mpfi, "\nExpected a true value\n";
}

if($mpfi >= $double && $mpfi <= $double) {$ok .= 'd'}
else {
  warn "4d: Expected true values, but got at least one false value\n";
}

if($double >= $mpfi && $double <= $mpfi) {$ok .= 'D'}
else {
  warn "4D: Expected true values, but got at least one false value\n";
}

if($mpfi <= $double + 1) {$ok .= 'e'}
else {
  warn "4e: Got: ", $mpfi <= $double + 1, "\nExpected a true value\n";
}

if($double + 1 >= $mpfi) {$ok .= 'E'}
else {
  warn "4E: Got: ", $double + 1 >= $mpfi, "\nExpected a true value\n";
}

if($mpfi + 1 >= $double) {$ok .= 'f'}
else {
  warn "4f: Got: ", $mpfi+ 1 >= $double, "\nExpected a true value\n";
}

if($double <= $mpfi + 1) {$ok .= 'F'}
else {
  warn "4F: Got: ", $double <= $mpfi + 1, "\nExpected a true value\n";
}

Rmpfi_set_ui($mpfi, $max_even);

if($mpfi <= $max_even && $mpfi >= $max_even) {$ok .= 'h'}
else {
  warn "4h: Expected true values, but got at least one false value\n";
}

if($max_even <= $mpfi && $max_even >= $mpfi) {$ok .= 'H'}
else {
  warn "4H: Expected true values, but got at least one false value\n";
}

if($mpfi <= $ui) {$ok .= 'i'}
else {
  warn "4i: Got: ", $mpfi <= $ui, "\nExpected a true value\n";
}

if($ui >= $mpfi) {$ok .= 'I'}
else {
  warn "4I: Got: ", $ui >= $mpfi, "\nExpected a true value\n";
}

if($mpfi + 1 >= $max_even) {$ok .= 'j'}
else {
  warn "4j: Got: ", $mpfi + 1 >= $max_even, "\nExpected a true value\n";
}

if($max_even <= $mpfi + 1) {$ok .= 'J'}
else {
  warn "4J: Got: ", $max_even <= $mpfi + 1, "\nExpected a true value\n";
}

Rmpfi_set_si($mpfi, $si + 1);

if($mpfi <= $si + 1 && $mpfi >= $si + 1) {$ok .= 'l'}
else {
  warn "4l: Expected true values, but got at least one false value\n";
}

if($si + 1 <= $mpfi && $si + 1 >= $mpfi) {$ok .= 'L'}
else {
  warn "4L: Expected true values, but got at least one false value\n";
}

if($mpfi <= $si + 2) {$ok .= 'm'}
else {
  warn "4m: Got: ", $mpfi <= $si + 2, "\nExpected a true value\n";
}

if($si + 2 >= $mpfi) {$ok .= 'M'}
else {
  warn "4M: Got: ", $si + 2 >= $mpfi, "\nExpected a true value\n";
}

if($mpfi >= $si) {$ok .= 'n'}
else {
  warn "4n: Got: ", $mpfi >= $si, "\nExpected a positive number\n";
}

if($si <= $mpfi) {$ok .= 'N'}
else {
  warn "4N: Got: ", $si <= $mpfi, "\nExpected a positive number\n";
}

Rmpfi_set_str($mpfi, $str, 10);

if($mpfi >= $str && $mpfi <= $str) {$ok .= 'o'}
else {
  warn "4o: Expected true values, but got at least one false value\n";
}

if($str >= $mpfi && $str <= $mpfi) {$ok .= 'O'}
else {
  warn "4O: Expected true values, but got at least one false value\n";
}

if($mpfi - 1 <= $str) {$ok .= 'p'}
else {
  warn "4p: Got: ", $mpfi - 1 <= $str, "\nExpected a true value\n";
}

if($str >= $mpfi - 1) {$ok .= 'P'}
else {
  warn "4P: Got: ", $str >= $mpfi - 1, "\nExpected a true value\n";
}

if($mpfi + 1 >= $str) {$ok .= 'q'}
else {
  warn "4q: Got: ", $mpfi+ 1 >= $str, "\nExpected a true value\n";
}

if($str <= $mpfi + 1) {$ok .= 'Q'}
else {
  warn "4Q: Got: ", $str <= $mpfi + 1, "\nExpected a true value\n";
}

if($ok eq 'abcdDeEfFhHiIjJlLmMnNoOpPqQ') {print "ok 4\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 4\n";
}

