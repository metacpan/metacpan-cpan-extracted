
# Validate that, for the selected random values, dd_repro returns a
# a value that, when assigned to a new Math::FakeDD object, results in
# an identical copy of the original object that was given to dd_repro.
#
# Check also that the value returned by dd_repro consists of the fewest
# possible number of decimal digits.
# This is achieved by firstly checking that the equivalence is broken
# when the final digit of the mantissa is removed (truncated).
# We then check that raising (what is now) the final digit by 1 (rounding
# up) still renders the equivalence broken.
#
# Also run some basic sanity tests of int() and abs().

# DBL_MIN = 2.2250738585072014e-308 = 2 ** -1022

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

my $dbl_min = 2 ** -1022;

for(my $i = -300; $i <= 300; $i++) {
  for my $run (1..6) {
    my $input = rand();

    while(length($input) > 19) { chop $input }
    while($input =~ /0$/) { chop $input }

    my $str = "$input" . "e" . $i;
    $str = '-' . $str if $run & 1;

    my $orig = Math::FakeDD->new($str);

    my $repro   = dd_repro($orig);
    my $decimal = dd_dec  ($orig);
    my $hex     = dd_hex  ($orig);

    if($orig < 1 && $orig > -1) {
      cmp_ok(int($orig), '==', 0, "int() expected to return a value of 0");
    }
    else {
      cmp_ok(int($orig), '!=', 0, "int() expected to return a value other than 0");
    }

    my $dd_repro   = Math::FakeDD->new($repro);
    my $dd_decimal = Math::FakeDD->new($decimal);
    my $dd_hex     = Math::FakeDD->new($hex);

    cmp_ok($dd_repro, '==', $orig      , "string returned by dd_repro() assigns to original value");
    cmp_ok($dd_repro, '==', $dd_decimal, "exact decimal representation assigns correctly");
    cmp_ok($dd_hex  , '==', $dd_decimal, "dd_hex() and dd_dec() assign to same value");

    if($orig > 0) {
      cmp_ok($orig,      '==', abs($dd_repro * -1), "$str: abs() ok");
    }
    else {
      cmp_ok(abs($orig),      '==', abs($dd_repro * -1), "$str: abs() ok");
    }
    my $t = int(Math::FakeDD->new($repro));
    cmp_ok(int($orig), '==', $t                 , "$str: int() ok");

    my $check1 = Math::FakeDD->new($repro);
    cmp_ok($check1, '==', $orig, "$str: round trip achieved");

    my @chop  = split /e/i, $repro;
    chop($chop[0]);
    next if $chop[0] =~ /\.$/;

    if(!defined($chop[1])) {
      $repro = $chop[0];
    }
    else {
      $repro = $chop[0] . 'e' . $chop[1];
    }

    my $check2 = Math::FakeDD->new($repro);
    cmp_ok($check2, '!=', $orig, "$str: chop() alters value");
    cmp_ok(abs($check2), '<', abs($orig), "$str: test value < original");

    next if $chop[0] =~ /9$/;

    ++substr($chop[0], -1); # round up the last digit.

    if(!defined($chop[1])) {
      $repro = $chop[0];
    }
    else {
      $repro = $chop[0] . 'e' . $chop[1];
    }
    my $check3 = Math::FakeDD->new($repro);
    cmp_ok($check3, '!=', $orig, "$str: round-up alters value");
    cmp_ok(abs($check3), '>', abs($orig), "$str: test value > original");
  }
}

my $big =    (2 ** 140)   + (2 ** 100);
my $little = (2 ** -1000) + (2 ** -1019);

my $fudd1 = Math::FakeDD->new($big) + $little; # dd_repro() needs to use prec of 1194 bits
my $fudd2 = Math::FakeDD->new($big) - $little; # dd_repro() needs to use prec of 1194 bits

cmp_ok($fudd1, '>', $big, "big + little > big");
cmp_ok($fudd2, '<', $big, "big - little < big");

my $fudd3 = Math::FakeDD->new(dd_repro($fudd1));
my $fudd4 = Math::FakeDD->new(dd_repro($fudd2));

cmp_ok($fudd3, '==', $fudd1, "+: round trip ok");
cmp_ok($fudd4, '==', $fudd2, "-: round trip ok");

dd_assign($fudd1, 2 ** -1075);
cmp_ok(dd_repro($fudd1), 'eq', '0.0', "dd_repro returns '0.0' for 2 ** -1075");

dd_assign($fudd1, 2 ** -1074);
cmp_ok(dd_repro($fudd1), 'eq', '5e-324', "dd_repro returns '5e-324' for 2 ** -1074");

dd_assign($fudd1, 2 ** -1073);
cmp_ok(dd_repro($fudd1), 'eq', '1e-323', "dd_repro displays '1e-323' for 2 ** -1073");

$fudd1 += 2 ** -1068;
cmp_ok(dd_repro($fudd1), 'eq', '3.26e-322', "dd_repro returns '3.26e-322' for (2 ** -1068)+(2 ** -1073)");

dd_assign($fudd1, 2 ** -1022);
cmp_ok(dd_repro($fudd1), 'eq', '2.2250738585072014e-308', "dd_repro returns DBL_MIN as '2.2250738585072014e-308'");

dd_assign($fudd1, 2 ** -1021);
cmp_ok(dd_repro($fudd1), 'eq', '4.450147717014403e-308', "dd_repro returns 2 ** -1021 as '4.450147717014403e-308'");

$fudd1 += 2 ** -1020;
cmp_ok(dd_repro($fudd1), 'eq', '1.3350443151043208e-307', "dd_repro '1.3350443151043208e-307' for (2 ** -1020)+(2 ** -1021)");

dd_assign($fudd1, (2 ** -1021) + (2 ** -1064)) ;
cmp_ok(dd_repro($fudd1), 'eq', '4.450147717014909e-308', "dd_repro '4.450147717014909e-308' for (2 ** -1021)+(2 ** -1064)");

dd_assign($fudd1, '0.59374149305888224e17'); # mpfr_dump() exponent == 56
cmp_ok(Math::FakeDD->new(dd_repro($fudd1)), '==', $fudd1, "round trip for '0.59374149305888224e17' ok");

dd_assign($fudd1, '0.0605815825720235e15');  # mpfr_dump() exponent == 46
cmp_ok(Math::FakeDD->new(dd_repro($fudd1)), '==', $fudd1, "round trip for '0.0605815825720235e15' ok");

dd_assign($fudd1, '0.32264564579955e13');    # mpfr_dump() exponent == 42
cmp_ok(Math::FakeDD->new(dd_repro($fudd1)), '==', $fudd1, "round trip for '0.32264564579955e13' ok");

dd_assign($fudd1, '0.217045016575725e14');   # mpfr_dump() exponent == 45
cmp_ok(Math::FakeDD->new(dd_repro($fudd1)), '==', $fudd1, "round trip for '0.217045016575725e14' ok");

dd_assign($fudd1, '0.920640108967635e14');   # mpfr_dump() exponent == 47
cmp_ok(Math::FakeDD->new(dd_repro($fudd1)), '==', $fudd1, "round trip for '0.920640108967635e14' ok");

dd_assign($fudd1, '0.26580405907862925e15'); # mpfr_dump() exponent == 48
cmp_ok(Math::FakeDD->new(dd_repro($fudd1)), '==', $fudd1, "round trip for '0.26580405907862925e15' ok");

dd_assign($fudd1, '0.94562172840506875e15'); # mpfr_dump() exponent == 50
cmp_ok(Math::FakeDD->new(dd_repro($fudd1)), '==', $fudd1, "round trip for '0.94562172840506875e15' ok");

dd_assign($fudd1, '0.59951823306102625e15'); # mpfr_dump() exponent == 50
cmp_ok(Math::FakeDD->new(dd_repro($fudd1)), '==', $fudd1, "round trip for '0.59951823306102625e15' ok");

done_testing();

