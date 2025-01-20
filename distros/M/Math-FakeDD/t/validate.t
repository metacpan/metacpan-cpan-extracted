
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

if($ENV{SKIP_REPRO_TESTS}) {
  is(1, 1);
  warn "\n skipping all tests as \$ENV{SKIP_REPRO_TESTS} is set\n";
  done_testing();
  exit 0;
}

my $dbl_min = 2 ** -1022;

for(my $i = -300; $i <= 300; $i++) {
  for my $run (1..6) {
    my $input = rand();

    while(length($input) > 19) { chop $input }
    while($input =~ /0$/) { chop $input }
    $input =~ s/[e\-]//gi;

    my $str = "$input" . "e" . $i;
    $str = '-' . $str if $run & 1;

    my $orig = Math::FakeDD->new($str);

    my $repro   = dd_repro($orig);
    my $decimal = dd_dec  ($orig);
    my $hex     = dd_hex  ($orig);

    chop_inc_test(dd_repro($orig), $orig);

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

dd_assign($fudd1, 2 ** -1025);
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, 2 ** -1075);
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, 2 ** -1074);
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, 2 ** -1073);
chop_inc_test(dd_repro($fudd1), $fudd1);

$fudd1 += 2 ** -1068;
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, 2 ** -1022);
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, 2 ** -1021);
chop_inc_test(dd_repro($fudd1), $fudd1);

$fudd1 += 2 ** -1020;
chop_inc_test(dd_repro($fudd1), $fudd1);;

dd_assign($fudd1, 2 ** -1021);
$fudd1 += (2 ** -1064) ;
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, '0.59374149305888224e17'); # mpfr_dump() exponent == 56
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, '0.0605815825720235e15');  # mpfr_dump() exponent == 46
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, '0.32264564579955e13');    # mpfr_dump() exponent == 42
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, '0.217045016575725e14');   # mpfr_dump() exponent == 45
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, '0.920640108967635e14');   # mpfr_dump() exponent == 47
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, '0.26580405907862925e15'); # mpfr_dump() exponent == 48
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, '0.94562172840506875e15'); # mpfr_dump() exponent == 50
chop_inc_test(dd_repro($fudd1), $fudd1);

dd_assign($fudd1, '0.59951823306102625e15'); # mpfr_dump() exponent == 50
chop_inc_test(dd_repro($fudd1), $fudd1);

done_testing();

sub chop_inc_test {
   my $res;
   my ($repro, $op) = (shift, shift);
   if(defined($_[0])) {
     $res = dd_repro_test($repro, $op, $_[0]);
   }
   else {
     $res = dd_repro_test($repro, $op);
   }
   ok($res == 15) or dd_diag($res, $op);
}

sub dd_diag {
  print STDERR "Failed round-trip for " . sprintx($_[1])     . "\n" unless $_[0] & 1;
  print STDERR "Failed chop test for " . sprintx($_[1])      . "\n" unless $_[0] & 2;
  print STDERR "Failed increment test for " . sprintx($_[1]) . "\n" unless $_[0] & 4;
}

__END__
