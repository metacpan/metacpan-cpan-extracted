
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

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

for(my $i = -300; $i <= 300; $i++) {
  for(1..3) {
    my $input = rand();

    while(length($input) > 19) { chop $input }
    while($input =~ /0$/) { chop $input }

    my $str = "$input" . "e" . $i;

    my $orig = Math::FakeDD->new($str);
    my $repro = dd_repro($orig);
    my $decimal = dd_dec($orig);

    if($orig < 1 && $orig > -1) {
      cmp_ok(int($orig), '==', 0, "int() expected to return a value of 0");
    }
    else {
      cmp_ok(int($orig), '!=', 0, "int() expected to return a value other than 0");
    }

    my $dd_repro   = Math::FakeDD->new($repro);
    my $dd_decimal = Math::FakeDD->new($decimal);

    cmp_ok($dd_repro, '==', $dd_decimal, "exact decimal representation assigns correctly");

    cmp_ok($orig,      '==', abs($dd_repro * -1), "$str: abs() ok");
    my $t = int(Math::FakeDD->new($repro));
    cmp_ok(int($orig), '==', $t                 , "$str: int() ok");

    my $check1 = Math::FakeDD->new($repro);
    cmp_ok($check1, '==', $orig, "$str: round trip achieved");

    my @chop  = split /e/i, $str;
    chop($chop[0]);
    next if $chop[0] =~ /\.$/;
    $repro = $chop[0] . 'e' . $chop[1];

    my $check2 = Math::FakeDD->new($repro);
    cmp_ok($check2, '!=', $orig, "$str: chop() alters value");

    next if $chop[0] =~ /9$/;

    ++substr($chop[0], -1); # round up the last digit.

    $repro = $chop[0] . 'e' . $chop[1];

    my $check3 = Math::FakeDD->new($repro);
    cmp_ok($check3, '!=', $orig, "$str: round-up alters value");
  }
}

# cmp_ok(1, '==', 3, "failing test");
done_testing();

