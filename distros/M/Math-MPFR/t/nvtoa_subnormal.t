
# More checks on nvtoa's handling of subnormal values

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;
use Test::More;

if(196869 < MPFR_VERSION) {

  my($bits, $pow, $str);

  if($Config{nvsize} == 8) {
    # nvtype is either double or 8-byte long double
    $bits = 53;
    $pow  = -1074;
  }
  elsif($Config{nvtype} eq '__float128') {
    $bits = 113;
    $pow  = -16494;
  }
  else {
    $bits = Math::MPFR::_required_ldbl_mant_dig();
    if($bits == 2098) {
      # nvtype is IBM DoubleDouble
      $bits = 53;
      $pow = -1074;
    }
    elsif($bits == 64 ) { $pow = -16445 }
    elsif($bits == 113) { $pow = -16494 }
    else                { die "Unknown nvtype" }
  }

  # Note that 2 ** $pow is the smallest positive (non-zero) value
  # that can be represented by the particular nvtype.

  if(2 ** $pow != 0) {
    $pow--;
    $bits++;

    my($val, $last_val) = (0, 0);

    for my $b(1 .. $bits) {
       next unless $b % 10; # Set every 10th to zero - just for some additional complexity
       $val = $last_val + (2 ** ($b + $pow));

       $str = nvtoa($val);
       cmp_ok(atonv($str), '==', $val,     "$b: atonv($str) == $val");
       cmp_ok(atonv($str), '>', $last_val, "$b: atonv($str) > $last_val");
       cmp_ok($str, 'eq', doubletoa($val), "$b: $str eq doubletoa($val)")
         if $Config{nvsize} == 8;

       other_checks($str, $val, $b);

       $last_val = $val;
    }
  }
  else {
    warn "\nSkipping all tests - this perl thinks that 2 ** $pow == 0\n";
    ok(1, "This perl is garbage"); # provide a test
  }

  done_testing();
}
else {

  eval {atonv('1.3');};
  like( $@, qr/^The atonv function requires mpfr\-3\.1\.6 or later/, '$@ reports that atonv is unavailable');

  done_testing();

}

sub other_checks {
  # check that $str is the shortest accurate representation of $val
  my($str, $val, $b) = (shift, shift, shift);
  my($newstr1, $newstr2, $skip) = ('', '', 0);

  # Replace the final digit of the significand with '0' and check
  # that the resultant value (in $newstr1) is less than $val.
  # Also, having removed the final digit of the original significand,
  # increment that value by 1 ULP, and check the resultant value (in
  # $newstr2) is greater than $val.

  # For this exercise all of the strings are of the
  # form significand . "e" . exponent.

  my @s = split /e/i, $str;
  $newstr1 = $s[0];
  chop $newstr1;
  $newstr2 = $newstr1;
  $skip = 1 unless length($newstr2);

  $newstr1 .= '0' . 'e' . $s[1];
  $newstr2 = plus_one_ulp($newstr2);
  $newstr2 .= 'e' . $s[1];

  cmp_ok(atonv($newstr1), '<', $val, "$b: atonv($newstr1) < $val");
  cmp_ok(atonv($newstr2), '>', $val, "$b: atonv($newstr2) > $val")
    unless $skip;

}


sub plus_one_ulp {
  my($ret, $pos) = (shift, 0);
  my $len = length($ret);

  for(1 .. $len) {
    if(substr($ret, -$_, 1) eq '.') {
      $pos = -$_;
      substr($ret, $pos, 1, '');
      last;
    }
  }

  $ret++;

  # Don't insert a '.' if the string that was given to this sub:
  # a) did not include a '.';
  #   OR
  # b) terminated with a '.'.

  substr($ret, length($ret) + $pos + 1, 0, '.')
    if $pos < -1;

  return $ret;
}
