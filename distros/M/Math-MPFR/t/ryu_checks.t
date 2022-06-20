# Check nvtoa() against Math::Ryu's ryu implementation.
# Math::Ryu requires that nvsize is 8, so we skip all tests
# if nvsize is not 8, or if Math::Ryu is not installed.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;
use Test::More;

if($Config{nvsize} != 8) {
  is(1, 1);
  warn "\nSkipping all tests because nvsize != 8\n";
  done_testing();
  exit 0;
}

eval { require Math::Ryu };
if($@) {
  is(1, 1);
  warn "\nSkipping all tests because Math::Ryu is unavailable\n";
  done_testing();
  exit 0;
}

my $rop1 = Rmpfr_init2(512);
my $rop2 = Rmpfr_init2(512);

for(-1075 .. 1025) {
  my $d = 2 ** $_;
  my $s1 = Math::Ryu::d2s($d);
  my $s2 = nvtoa($d);

  Rmpfr_set_str($rop1, $s1, 10, MPFR_RNDN);
  Rmpfr_set_str($rop2, $s2, 10, MPFR_RNDN);

  ok($rop1 == $rop2, "nvtoa agrees with ryu for 2 ** $_");

  $d = (2 ** $_) +
       (2 ** ($_ + 1)) +
       (2 ** ($_ + 2)) +
       (2 ** ($_ + 3));

  $s1 = Math::Ryu::d2s($d);
  $s2 = nvtoa($d);

  Rmpfr_set_str($rop1, $s1, 10, MPFR_RNDN);
  Rmpfr_set_str($rop2, $s2, 10, MPFR_RNDN);

  ok($rop1 == $rop2, "nvtoa agrees with ryu for 2 ** $_ + .....");

  my $p = $_ <= 0 ? $_ + 4 + int(rand(50))
                  : $_ - 4 - int(rand(50));

  $d = (2 ** $_) +
       (2 ** $p);

  $s1 = Math::Ryu::d2s($d);
  $s2 = nvtoa($d);

  Rmpfr_set_str($rop1, $s1, 10, MPFR_RNDN);
  Rmpfr_set_str($rop2, $s2, 10, MPFR_RNDN);

  ok($rop1 == $rop2, "nvtoa agrees with ryu for (2**$_) + (2**$p");

}

done_testing();

