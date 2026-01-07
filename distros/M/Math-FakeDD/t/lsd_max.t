# Check that when the lsd is set to the maximum possible value for
# an lsd (ie 2 ** 970), nextup and nextdown work  correctly.
# Here, we start with the value (2 ** 1023) + (2 **970), for which
# the msd is 2 ** 1023 (8.98846567431158e+307) and
# the lsd is 2 ** 970  (9.9792015476736e+291).
# Further down we look at an equivalent value whose msd and lsd differs
# from this first one.
use strict;
use warnings;
use Math::FakeDD qw(:all);

use Test::More;

my($global_pos_up, $global_pos_down, $global_neg_up, $global_neg_down);

my $obj1 = Math::FakeDD->new(2) ** 1023;
my $lsd_max = 2 ** 970;
$obj1 += $lsd_max;

{
  cmp_ok($obj1->{msd}, '==', 2 ** 1023    , 'test 1 ok');
  cmp_ok($obj1->{lsd}, '==', 2 ** 970     , 'test 2 ok');
  cmp_ok($obj1       , '==', $obj1->{mpfr}, 'test 3 ok');

  my $obj2 = dd_nextup($obj1);
  $global_pos_up = mpfr2dd($obj2->{mpfr});

  cmp_ok($obj2->{msd}, '>', $obj1->{msd}, 'test 4 ok');
  cmp_ok($obj2->{lsd}, '<' , 0          , 'test 5 ok');

  my $obj3 = dd_nextdown($obj2);

  cmp_ok($obj3, '==', $obj1, 'test 6 (roundtrip) ok');
}

{
  cmp_ok($obj1->{msd}, '==', 2 ** 1023    , 'test 7 ok');
  cmp_ok($obj1->{lsd}, '==', 2 ** 970     , 'test 8 ok');
  cmp_ok($obj1       , '==', $obj1->{mpfr}, 'test 9 ok');

  my $obj2 = dd_nextdown($obj1);
  $global_pos_down = mpfr2dd($obj2->{mpfr});

  cmp_ok($obj2->{msd}, '==', $obj1->{msd}, 'test 10 ok');
  cmp_ok($obj2->{lsd}, '>',  0           , 'test 11 ok');
  cmp_ok($obj2->{lsd}, '<', 2 ** 970,    , 'test 12 ok');

  my $obj3 = dd_nextup($obj2);

  cmp_ok($obj3, '==', $obj1, 'test 13 (roundtrip) ok');
}

$obj1 *= -1;

{
  cmp_ok($obj1->{msd}, '==', -(2 ** 1023)    , 'test 14 ok');
  cmp_ok($obj1->{lsd}, '==', -(2 ** 970)     , 'test 15 ok');
  cmp_ok($obj1       , '==', $obj1->{mpfr}, 'test 16 ok');

  my $obj2 = dd_nextup($obj1);
  $global_neg_up = mpfr2dd($obj2->{mpfr});

  cmp_ok($obj2->{msd}, '==', $obj1->{msd}, 'test 17 ok');
  cmp_ok($obj2->{lsd}, '<' , 0          , 'test 18 ok');
  cmp_ok($obj2->{lsd}, '>', -(2 ** 970),    , 'test 19 ok');

  my $obj3 = dd_nextdown($obj2);

  cmp_ok($obj3, '==', $obj1, 'test 20 (roundtrip) ok');
}

{
  cmp_ok($obj1->{msd}, '==', -(2 ** 1023)    , 'test 21 ok');
  cmp_ok($obj1->{lsd}, '==', -(2 ** 970)     , 'test 22 ok');
  cmp_ok($obj1       , '==', $obj1->{mpfr}, 'test 23 ok');

  my $obj2 = dd_nextdown($obj1);
  $global_neg_down = mpfr2dd($obj2->{mpfr});

  cmp_ok($obj2->{msd}, '<', $obj1->{msd}, 'test 24 ok');
  cmp_ok($obj2->{lsd}, '>',  0           , 'test 25 ok');

  my $obj3 = dd_nextup($obj2);

  cmp_ok($obj3, '==', $obj1, 'test 26 (roundtrip) ok');
}

$obj1 *= -1; # revert $obj1 to its original (+ve) form.

{
  my $obj2 = $obj1 + (2 ** -1074); # ($obj1 + (2 ** -1074) == $obj1)
  # $obj2 holds the same value as $obj1, but $obj2->{msd} != $obj1->{msd}
  # and $obj2->{lsd} != $obj1->{lsd}.
  # The addition of 2 ** -1074 (which is ultimately ignored), is enough to
  # round the 53-bit representation of the 2098-bit Math::MPFR object up to
  # (2 ** 1023) + (2 ** 971) = 8.988465674311582e+307. This value (which is
  # set as the msd) is greater than the DoubleDouble value by an amount
  # of 2 ** 970.
  # Hence the lsd is therefore set to -(2 ** 970) = -9.9792015476736e+291.
  # That is, this particular value can be held by 2 different forms.
  # I believe this is correct behaviour - if it ever changes then I want
  # to know about it.
  # Also I want to know that nextup and nextdown are still working
  # correctly when the Math::FakeDD object has this alternative form.
  cmp_ok($obj2, '==', $obj1                , 'test 27 ok');
  cmp_ok($obj2->{msd}, '>', $obj1->{msd}   , 'test 28 ok');
  cmp_ok($obj2->{lsd}, '<', 0              , 'test 29 ok');
  cmp_ok($obj2->{mpfr}, '==', $obj1->{mpfr}, 'test 30 ok');
  my $obj3 = dd_nextup($obj2);
  cmp_ok($obj3->{msd}, '==' , $global_pos_up->{msd }, 'test 31 ok');
  cmp_ok($obj3->{lsd}, '==' , $global_pos_up->{lsd} , 'test 32 ok');
  cmp_ok($obj3->{mpfr}, '==', $global_pos_up->{mpfr}, 'test 33 ok');
  my $obj4 = dd_nextdown($obj2);
  cmp_ok($obj4->{msd}, '==' , $global_pos_down->{msd }, 'test 34 ok');
  cmp_ok($obj4->{lsd}, '==' , $global_pos_down->{lsd} , 'test 35 ok');
  cmp_ok($obj4->{mpfr}, '==', $global_pos_down->{mpfr}, 'test 36 ok');

}

$obj1 *= -1; # $obj1 is negative again.

{
  my $obj2 = $obj1 - 1; # ($obj1 - 1 == $obj1)
  # $obj2 holds the same value as $obj1, but $obj2->{msd} != $obj1->{msd}
  # and $obj2->{lsd} != $obj1->{lsd}.
  cmp_ok($obj2, '==', $obj1                , 'test 37 ok');
  cmp_ok($obj2->{msd}, '<', $obj1->{msd}   , 'test 38 ok');
  cmp_ok($obj2->{lsd}, '>', 0              , 'test 39 ok');
  cmp_ok($obj2->{mpfr}, '==', $obj1->{mpfr}, 'test 40 ok');
  my $obj3 = dd_nextup($obj2);
  cmp_ok($obj3->{msd}, '==' , $global_neg_up->{msd }, 'test 41 ok');
  cmp_ok($obj3->{lsd}, '==' , $global_neg_up->{lsd} , 'test 42 ok');
  cmp_ok($obj3->{mpfr}, '==', $global_neg_up->{mpfr}, 'test 43 ok');
  my $obj4 = dd_nextdown($obj2);
  cmp_ok($obj4->{msd}, '==' , $global_neg_down->{msd }, 'test 44 ok');
  cmp_ok($obj4->{lsd}, '==' , $global_neg_down->{lsd} , 'test 45 ok');
  cmp_ok($obj4->{mpfr}, '==', $global_neg_down->{mpfr}, 'test 46 ok');

}

done_testing();
__END__

