use strict;
use warnings;
use Math::Ryu qw(:all);
use Test::More;

eval {require Math::MPFR;};

if($@) {
  plan skip_all => 'could not load Math::MPFR';
}
elsif($Math::MPFR::VERSION < 4.07) {
  plan skip_all => "need at least Math-MPFR-4.07, have Math-MPFR-$Math::MPFR::VERSION";
}
elsif(Math::MPFR::MPFR_VERSION() <= 196869) {
  plan skip_all => 'need at least mpfr-3.1.6, have mpfr-' . Math::MPFR::MPFR_VERSION_STRING();
}

my $count = 0;

for (-324 .. -290, -200 .. -180, -50 .. 50, 200 .. 250) {
    my $str = (5 + int(rand(5))) . "." . random_digits() . "e$_";
    my $nv = Math::MPFR::atonv($str);

    my($s1, $s2);

    $count++;

    if($count % 3) {
      $s1 = Math::MPFR::nvtoa($nv);
      $s2 = d2s($nv);
    }
    else {
      $s1 = Math::MPFR::nvtoa($nv / 10);
      $s2 = d2s($nv / 10);
    }

    cmp_ok(s2d($s1), '==', s2d($s2),
           "s2d() handles formats provided by both nvtoa() and d2s()");

    cmp_ok(Math::MPFR::atonv($s1), '==', Math::MPFR::atonv($s2),
           "atonv() handles formats provided by both nvtoa() and d2s()");

    # nvtoa() and d2s() can provide different formatting of the
    # same value. We now standardize the forms they take so that
    # valid comparison checks can be made

    # They both might not signify a positive exponent with an
    # explicit '+' symbol. If so, ignore the discrepancy.
    $s1 =~ s/e\+/e/i;
    $s2 =~ s/e\+/e/i;

    # They both might not signify a 0 exponent with an
    # explicit 'e0' symbol. If so, ignore the discrepancy.
    $s1 =~ s/e0$//i;
    $s2 =~ s/e0$//i;

    # -ve exponents might vary in the number of leading zeros.
    # If so, ignore the discrepancy:
    $s1 =~ s/e\-0/e-/i;
    $s2 =~ s/e\-0/e-/i;

    # They both might not produce a terminating '.0',
    # If so, ignore the discrepancy
    $s1 =~ s/\.0$//i;
    $s2 =~ s/\.0$//i;

    # Allow for differences like '8.024475095697535e5' vs '802447.5095697535'
    # and '6.604427846250071e-4' vs '0.0006604427846250071'
    if(lc($s1) ne lc($s2)) {
      my @p2 = split /e/i, $s2;
      $p2[0] =~ s/\.//; # remove the existing decimal point
      if($p2[1] > 0) {  # exponent of $s2 is greater than 0
        while(length($p2[0]) <= $p2[1]) {$p2[0] .= '0'}
        substr($p2[0], $p2[1] + 1, 0, '.');
        $p2[0] =~ s/\.$//; # remove trailing decimal point
        $s2 = $p2[0];
      }
      else {
        my $prefix = '0' x -$p2[1];
        substr($prefix, 1, 0, '.');
        $s2 = $prefix . $p2[0];
      }
    }

    cmp_ok(lc($s2), 'eq', lc($s1), "agrees with Math::MPFR::nvtoa()");
}

my $f = Math::MPFR->new();

my $nan = Math::MPFR::Rmpfr_get_NV($f, 0);
cmp_ok(lc(d2s($nan)), 'eq', lc(Math::MPFR::nvtoa($nan)), "nan stringification is ok");

Math::MPFR::Rmpfr_set_inf($f, 0);

my $pinf = Math::MPFR::Rmpfr_get_NV($f, 0);
like(lc(d2s($pinf)), qr/^\+?inf/i, "+inf stringification is ok");
like(lc(d2s(-$pinf)), qr/^\-inf/i, "-inf stringification is ok");

cmp_ok(uc(d2s(0.0)), 'eq', '0E0', "zero stringifies as expected (0E0)"); # or 0e0

Math::MPFR::Rmpfr_set_ui($f, 0, 0);
Math::MPFR::Rmpfr_neg($f, $f, 0); # $f is -0.0

my $neg_zero = Math::MPFR::Rmpfr_get_NV($f, 0); # $neg_zero is -0.0
cmp_ok(uc(d2s($neg_zero)), 'eq', '-0E0', "negative zero stringifies as expected (-0E0)"); # or -0e0

done_testing();

sub random_digits {
    my $ret = '';
    $ret .= int(rand(10)) for 1 .. 10;
    return $ret;
}
