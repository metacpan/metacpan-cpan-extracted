######################################################
# Testing mpfr_fmod_ui, introduced in mpfr-4.2.0-dev #
# However, Rmpfr_fmod_ui works against aearlier      #
# versions of the mpfr library - albeit suboptimally #
# when mpfr version is older than 4.2.0              #
######################################################

use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Test::More;

my $div = 2015;
my $den = Rmpfr_init2(64);

my $rop1 = Math::MPFR->new();
my $rop2 = Math::MPFR->new();
my $num = Math::MPFR->new(7000.2);
Rmpfr_set_ui($den, $div, MPFR_RNDN);
Rmpfr_fmod    ( $rop1, $num, $den, MPFR_RNDN);
Rmpfr_fmod_ui ( $rop2, $num, $div, MPFR_RNDN );

cmp_ok($rop1, '==', $rop2, '53-bit prec: Rmpfr_fmod and Rmpfr_fmod_ui agree');

Rmpfr_set_default_prec(6);

my $rop3 = Math::MPFR->new();
my $rop4 = Math::MPFR->new();

for(1..149) {
  my $div = int(rand(2048)) + 1;
  my $num = Math::MPFR->new(1 + rand(6000));
  Rmpfr_set_ui($den, $div, MPFR_RNDN);
  Rmpfr_fmod    ( $rop3, $num, $den, MPFR_RNDN);
  Rmpfr_fmod_ui ( $rop4, $num, $div, MPFR_RNDN );

  cmp_ok($rop3, '==', $rop4, "$num $div: Rmpfr_fmod and Rmpfr_fmod_ui agree");
}

done_testing()
