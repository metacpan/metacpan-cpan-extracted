# Additional nvtoa() testing.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;
use Test::More;

# We'll check a list of 10000 randomly derived NV values.
# The mantissa of each NV will be between 1 and $MAX_DIG decimal digits.
# Neither the first nor last mantissa digit will be zero
# The exponent will be in the range -$MAX_POW..$MAX_POW
# Exponents will alternate between -ve and +ve
# Every third mantissa will be negative.
# Assign that random string to an NV ($nv) and check that nvtoa($nv) == $nv
# If the equivalence does not hold, issue a message, register a FAIL, and quit.
#
# Then, remove all leading and trailing zeroes from the mantissa and check that
# the number of mantissa digits in the output string is no greater than the number of
# mantissa digits in the input string.
#
# Then we check that replacing the last (ie least significant) digit of the
# output mantissa with a 0 results in an NV of a different value to the original.
# We actually do this by simply chopping the mantissa and incrementing the exponent.
#
# Then increment this chopped mantissa by one, and check that this value is also
# different to the original NV.
#
# Having established that (eg) $nv == 1234e-11 && $nv > 123e-10 && $nv < 124e-10
# we have also established that "accurate" representation of this particular $nv can be
# achieved with as few as 4 mantissa digits.
#
# In this script we test the correctness of nvtoa() differently, depending upon
# whether perl is prone to mis-assignment, or not.
#
# For perls whose NV is the "Double-Double" long double, perl is prone to mis-assignment
# and $reliable is set to false, irrespective of the value of $].
#
# Else, in order for perl to be deemed reliable (in which case we set $reliable to true),
# perls whose nvtype is NOT __float128, need to be at version 5.29.4 (or later) &&
#    if perl's nvtype is "double", then $Config{d_strtod} needs to be defined
#    or if perl's nvtype is "long double", then $Config{d_strtold} needs to be defined.
# All perl's whose nvtype is __float128 assign correctly and $reliable is set to true for
# them, irrespective of the value of $].
#
# All perls that don't fit any of the above categories are deemed unreliable, and
# $reliable is set to false.

if(MPFR_VERSION_MAJOR < 3 || (MPFR_VERSION_MAJOR() == 3  && MPFR_VERSION_PATCHLEVEL < 6)) {
  plan skip_all => "nvtoa.t utilizes Math::MPFR functionality that requires mpfr-3.1.6\n";
  exit 0;
}

plan tests => 1;
my $todo = 0;

# Some systems provide sqrtl() but not powl() for their -Duselongdouble builds
unless(sqrt(2.0) == 2 ** 0.5) {
  warn "\nPoorly configured system\n";
  $todo = 1;
}

my $MAX_DIG;
my $MAX_POW;
my $ok = 1;

if   ($Math::MPFR::NV_properties{bits} == 53)  { $MAX_DIG = 17;
                                                 $MAX_POW = 350;
                                               }
elsif($Math::MPFR::NV_properties{bits} == 64)  { $MAX_DIG = 21;
                                                 $MAX_POW = 5000;
                                               }
elsif($Math::MPFR::NV_properties{bits} == 113) { $MAX_DIG = 36;
                                                 $MAX_POW = 5000;
                                               }
else                                           { $MAX_DIG = 34;   # NV is Double-Double
                                                 $MAX_POW = 350;
                                               }

my $reliable = 0;

if(
   $Config{nvtype} eq '__float128'
   ||
   ($] > 5.029005 && $Config{nvtype} eq 'double' && defined($Config{d_strtod}))
   ||
   ($] > 5.029005 && $Config{nvtype} eq 'long double' && defined($Config{d_strtold}) && $MAX_DIG != 34)
  ) {

  warn "Using perl for string to NV assignment. (Perl deemed reliable)\n";
  $reliable = 1;
}
else {
  warn "Avoiding perl for string to NV assignment. (Perl is UNRELIABLE)\n";
}

my $count = 10000;

while(1) {
  $count--;
  last if $count < 0;
  my $mantissa_sign = $count % 3 ? '' : '-';
  my $mantissa = 1 + int(rand(9));
  my $exponent = int(rand($MAX_POW));

  # Skew the exponent towards the more usual values that are typically used.
  # nvtoa() calculations are quite expensive on long double and __float128
  # builds for NVs whose exponents are a long way from zero.
  $exponent = int(rand(10)) if ($exponent > 50 && $exponent < $MAX_POW / 1.5);
  $exponent = '-' . $exponent if ($count & 1);

  my $len = int(rand($MAX_DIG));

  while(length($mantissa) < $len) { $mantissa .= int(rand(10)) }
  $mantissa .= 1 +int(rand(9)) if $len;

  my $str = $mantissa_sign . $mantissa . 'e' . $exponent;

  my $nv;

  if($reliable) {
    $nv = $str * 1.0;
  }
  else {
    $nv = atonv($str);
  }

  my $nvtoa = nvtoa($nv);

  # Now check that $nvtoa == $nv

  if($reliable) { # perl can assign the string directly
    my $nvtoa_num = $nvtoa; # Avoid numifying $nvtoa

    if($nvtoa_num != $nv) {
      warn "$str: $nvtoa != $nv\n";
      $ok = 0;
      last;
    }
  }
  else {         # perl is unreliable so we assign the string using atonv()
    if(atonv($nvtoa) != $nv) {
      warn "$str: ", atonv($nvtoa), " != $nv\n";
      $ok = 0;
      last;
    }
  }

  next if ($nvtoa =~ /Inf$/ || $nv == 0);

  $nvtoa =~ s/\.//;
  $nvtoa =~ s/^\-//;
  my $significand = (split /e/, $nvtoa)[0];
  while($significand =~ /0$/) {
    chop $significand;
  }
  substr($significand, 0, 1, '') while $significand =~ /^0/;

  if(length $significand > length $mantissa) {
    warn "$str: $significand longer than $mantissa\n";
    warn sprintf("%a vs %a\n", atonv($str), atonv($nvtoa)), "\n";
    $ok = 0;
    last;
  }

  my $new_exponent = $exponent + length($mantissa) - length($significand);

  if(length $significand > 1) {
    chop $significand;
    #if($new_exponent < 0) { $new_exponent-- }
    #else { $new_exponent++ }
    $new_exponent++;
  }
  else { next }

  # Now check that truncating the significand and incrementing the exponent has altered the value
  # eg 1234e-11 becomes 123e-10 - which should be less than the original $nv.

  my $new_str = $mantissa_sign . $significand . 'e' . $new_exponent;

  if($reliable) {
    my $new_str_num = $new_str; # Avoid numifying $new_str
    if($nv < 0) {               # $new_str_num  should be greater than $nv
      unless($new_str_num > $nv) {
        warn "Trunc: $nv: $new_str !> $str\n";
        $ok = 0;
        last;
      }
    }
    else {                      # $new_str_num  should be less than $nv
      unless($new_str_num < $nv) {
        warn "Trunc: $nv: $new_str !< $str\n";
        $ok = 0;
        last;
      }
    }
  }
  else {
    if($nv < 0) {               # atonv($new_str)  should be greater than $nv
      unless(atonv($new_str) > $nv) {
        warn "Trunc: $nv: $new_str !> $str\n";
        $ok = 0;
        last;
      }
    }
    else {                      # atonv($new_str) should be less than $nv
      unless(atonv($new_str) < $nv) {
        warn "Trunc: $nv: $new_str !< $str\n";
        $ok = 0;
        last;
      }
    }
  }

  # Now increment the truncated string and check that it still produces
  # a different value to the original
  # eg 123e-10 becomes 124e-10 - which should be greater than the original $nv

  $significand++;

  $new_str = $mantissa_sign . $significand . 'e' . $new_exponent;

  #print "$new_str\n\n";

  if($reliable) {
    my $new_str_num = $new_str; # Avoid numifying $new_str
    if($nv < 0) {               # $new_str_num  should be less than $nv
      unless($new_str_num < $nv) {
        warn "Inc: $nv: $new_str !< $str\n";
        $ok = 0;
        last;
      }
    }
    else {                      # $new_str_num  should be greater than $nv
      unless($new_str_num > $nv) {
        warn "Inc: $nv: $new_str !> $str\n";
        $ok = 0;
        last;
      }
    }
  }
  else {
    if($nv < 0) {               # atonv($new_str)  should be less than $nv
      unless(atonv($new_str) < $nv) {
        warn "Inc: $nv: $new_str !< $str\n";
        $ok = 0;
        last;
      }
    }
    else {                      # atonv($new_str)  should be greater than $nv
      unless(atonv($new_str) > $nv) {
        warn "Inc: $nv: $new_str !> $str\n";
        $ok = 0;
        last;
      }
    }
  }

}

    if($todo) {
      TODO: {
        local $TODO = "Tests don't yet accommodate this inferior -Duselongdouble implementation";
        ok($ok == 1, 'test 1');
      };
    }
    else {
      ok($ok == 1, 'test 1');
    }


__END__

