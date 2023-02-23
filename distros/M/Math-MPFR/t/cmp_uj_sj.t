use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;
use Test::More;

if(Math::MPFR::_has_longlong()) {
  my $fr1 = Math::MPFR->new(2 ** 64);
  my $fr2 = Math::MPFR->new(2 ** 63);
  my $uv  = Math::MPFR->new(~0);

  cmp_ok(Rmpfr_cmp   ( $fr1, $uv ), '==', 0, "Math::MPFR->new(2 ** 64) == Math::MPFR->new(~0)");
  cmp_ok(Rmpfr_cmp_uj( $fr1, ~0  ), '>',  0, "Math::MPFR->new(2 ** 64) > ~0");
  cmp_ok(Rmpfr_cmp_IV( $fr1, ~0  ), '>',  0, "Rmpfr_cmp_IV and Rmpfr_cmp_uj are the same");

  my $iv = Math::MPFR->new(~0 >> 1);

  cmp_ok(Rmpfr_cmp   ( $fr2, $iv      ), '==', 0, "Math::MPFR->new(2 ** 63) == Math::MPFR->new(~0 >> 1)");
  cmp_ok(Rmpfr_cmp_sj( $fr2, ~0 >> 1  ), '>',  0, "Math::MPFR->new(2 ** 63) > ~0 >> 1");
  cmp_ok(Rmpfr_cmp_IV( $fr2, ~0 >> 1  ), '>',  0, "Rmpfr_cmp_IV and Rmpfr_cmp_sj are the same");

}
else {

  eval { Rmpfr_cmp_uj(Math::MPFR->new(0), 0); };
  like($@, qr/^Rmpfr_cmp_uj is unavailable because/, '$@ set as expected for Rmpfr_cmp_uj');

  eval { Rmpfr_cmp_sj(Math::MPFR->new(0), 0); };
  like($@, qr/^Rmpfr_cmp_sj is unavailable because/, '$@ set as expected for Rmpfr_cmp_sj');

  if($Config{ivsize} == 8) {
    my $fr1 = Math::MPFR->new(2 ** 64);
    my $fr2 = Math::MPFR->new(2 ** 63);
    my $uv  = Math::MPFR->new(~0);

    cmp_ok(Rmpfr_cmp   ( $fr1, $uv ), '==', 0, "Math::MPFR->new(2 ** 64) == Math::MPFR->new(~0)");
    cmp_ok(Rmpfr_cmp_ui( $fr1, ~0  ), '>',  0, "Math::MPFR->new(2 ** 64) > ~0");
    cmp_ok(Rmpfr_cmp_IV( $fr1, ~0  ), '>',  0, "Rmpfr_cmp_IV and Rmpfr_cmp_ui are the same");

    my $iv = Math::MPFR->new(~0 >> 1);

    cmp_ok(Rmpfr_cmp   ( $fr2, $iv      ), '==', 0, "Math::MPFR->new(2 ** 63) == Math::MPFR->new(~0 >> 1)");
    cmp_ok(Rmpfr_cmp_si( $fr2, ~0 >> 1  ), '>',  0, "Math::MPFR->new(2 ** 63) > ~0 >> 1");
    cmp_ok(Rmpfr_cmp_IV( $fr2, ~0 >> 1  ), '>',  0, "Rmpfr_cmp_IV and Rmpfr_cmp_si are the same");
  }
  else {
    my $fr1 = Math::MPFR->new(2 ** 32);
    my $fr2 = Math::MPFR->new(2 ** 31);
    my $uv  = Math::MPFR->new(~0);

    cmp_ok(Rmpfr_cmp   ( $fr1, $uv ), '>', 0, "Math::MPFR->new(2 ** 32) > Math::MPFR->new(~0)");
    cmp_ok(Rmpfr_cmp_ui( $fr1, ~0  ), '>', 0, "Math::MPFR->new(2 ** 32) > ~0");
    cmp_ok(Rmpfr_cmp_IV( $fr1, ~0  ), '>', 0, "Rmpfr_cmp_IV and Rmpfr_cmp_ui are the same");

    my $iv = Math::MPFR->new(~0 >> 1);

    cmp_ok(Rmpfr_cmp   ( $fr2, $iv      ), '>', 0, "Math::MPFR->new(2 ** 31) > Math::MPFR->new(~0 >> 1)");
    cmp_ok(Rmpfr_cmp_si( $fr2, ~0 >> 1  ), '>', 0, "Math::MPFR->new(2 ** 31) > ~0 >> 1");
    cmp_ok(Rmpfr_cmp_IV( $fr2, ~0 >> 1  ), '>', 0, "Rmpfr_cmp_IV and Rmpfr_cmp_si are the same");
  }
}

done_testing();

