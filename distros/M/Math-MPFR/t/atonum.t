
use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Test::More;

if(196869 >= MPFR_VERSION) {

  eval {atonum("1.3");};
  like  ($@, qr/atonv is not available with this version/, '$@ reports unavailability of atonum');

  done_testing();

}
else {

  my @in = (~0, ~0 - 1, ~0 - 10000, ~0 >> 1, (~0 >> 1) * -1, 1e6, -1e6);

  for my $n (@in) {
    cmp_ok(atonum("$n"), 'eq', "$n", "atonum(\"$n\") eq \"$n\"");
    cmp_ok(atonum("$n"), '==',  $n , "atonum(\"$n\") == $n");
  }

  my $fr = Math::MPFR->new();
  my $nan  = Rmpfr_get_NV($fr, MPFR_RNDN);
  Rmpfr_set_inf($fr, 0);
  my $pinf = Rmpfr_get_NV($fr, MPFR_RNDN);
  my $ninf = $pinf * -1;
  my $pzero = 0.0;
  my $nzero = $pzero * -1.0;

  @in = ($pinf, $ninf, $nan, $pzero, $nzero, sqrt(2), 1 / 10, 1.3e-200, -1.3e-200, 2 ** 200, -(2 ** 200));

  for my $n (@in) {
    cmp_ok(atonum("$n"), 'eq', atonv("$n"),  "atonum(\"$n\") eq atonv(\"$n\")");
    next if $n != $n;
    cmp_ok(atonum("$n"), '==',  atonv("$n"), "atonum(\"$n\") == atonv(\"$n\")");
  }

  done_testing();
}

