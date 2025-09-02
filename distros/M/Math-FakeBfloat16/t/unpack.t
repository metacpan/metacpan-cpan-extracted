use strict;
use warnings;
use Math::FakeBfloat16 qw(:all);

use Test::More;
cmp_ok(unpack_bf16_hex($Math::FakeBfloat16::bf16_DENORM_MIN), 'eq', '0001', "DENORM_MIN unpacks correctly");
cmp_ok(unpack_bf16_hex($Math::FakeBfloat16::bf16_DENORM_MAX), 'eq', '007F', "DENORM_MAX unpacks correctly");
cmp_ok(unpack_bf16_hex($Math::FakeBfloat16::bf16_NORM_MIN),   'eq', '0080', "NORM_MIN unpacks correctly");
cmp_ok(unpack_bf16_hex($Math::FakeBfloat16::bf16_NORM_MAX),   'eq', '7F7F', "NORM_MAX unpacks correctly");
cmp_ok(unpack_bf16_hex(sqrt(Math::FakeBfloat16->new(2))),     'eq', '3FB5', "sqrt 2 unpacks correctly");
cmp_ok(unpack_bf16_hex(Math::FakeBfloat16->new('5e-41')),     'eq', '0001', "'5e-41' unpacks correctly");
cmp_ok(unpack_bf16_hex(Math::FakeBfloat16->new(Math::MPFR->new('5e-41'))), 'eq', '0001', "MPFR('5e-41') unpacks correctly");

cmp_ok(unpack_bf16_hex(-$Math::FakeBfloat16::bf16_DENORM_MIN), 'eq', '8001', "-DENORM_MIN unpacks correctly");
cmp_ok(unpack_bf16_hex(-$Math::FakeBfloat16::bf16_DENORM_MAX), 'eq', '807F', "-DENORM_MAX unpacks correctly");
cmp_ok(unpack_bf16_hex(-$Math::FakeBfloat16::bf16_NORM_MIN),   'eq', '8080', "-NORM_MIN unpacks correctly");
cmp_ok(unpack_bf16_hex(-$Math::FakeBfloat16::bf16_NORM_MAX),   'eq', 'FF7F', "-NORM_MAX unpacks correctly");
cmp_ok(unpack_bf16_hex(-(sqrt(Math::FakeBfloat16->new(2)))),   'eq', 'BFB5', "-(sqrt 2) unpacks correctly");
cmp_ok(unpack_bf16_hex(Math::FakeBfloat16->new('-5e-41')),     'eq', '8001', "'-5e-41' unpacks correctly");
cmp_ok(unpack_bf16_hex(Math::FakeBfloat16->new(Math::MPFR->new('-5e-41'))), 'eq', '8001', "MPFR('5e-41') unpacks correctly");

###############################################################
###############################################################
{
    my $inc = Math::FakeBfloat16->new('0');
    my $dec = Math::FakeBfloat16->new('-0');

    my $mpfr_inc   = Math::MPFR::Rmpfr_init2(16);
    my $mpfr_dec   = Math::MPFR::Rmpfr_init2(16);
    my $mpfr_store = Math::MPFR::Rmpfr_init2(16);
    Math::MPFR::Rmpfr_set_zero($mpfr_store, 1); # Set to 0.
    my $rnd = 0; # Round to nearest, ties to even.

    cmp_ok(unpack_bf16_hex($inc), 'eq', '0000', " 0 unpacks to 0000");
    cmp_ok(unpack_bf16_hex($dec), 'eq', '8000', "-0 unpacks to 8000");

    for(1..2060) {
      bf16_nextabove($inc);
      bf16_nextbelow($dec);
      my $unpack_inc = unpack_bf16_hex($inc);
      my $unpack_dec = unpack_bf16_hex($dec);

      cmp_ok(length($unpack_inc), '==', 4, "length($unpack_inc) == 4");
      cmp_ok(length($unpack_dec), '==', 4, "length($unpack_inc) == 4");

      Math::MPFR::Rmpfr_strtofr($mpfr_inc, $unpack_inc, 16, $rnd);
      cmp_ok($mpfr_inc - $mpfr_store, '==', 1, "inc has been incremented to $unpack_inc");
      Math::MPFR::Rmpfr_strtofr($mpfr_dec, $unpack_dec, 16, $rnd);
      cmp_ok($mpfr_dec - $mpfr_inc, '==', 0x8000, "dec has been decremented to $unpack_dec");

      Math::MPFR::Rmpfr_set($mpfr_store, $mpfr_inc, $rnd);
    }

    #cmp_ok(is_bf16_inf($inc), '==', 1, "values have reached infinity");

}
###############################################################
###############################################################

{
  my $inc = Math::FakeBfloat16->new('-inf');
  my $dec = Math::FakeBfloat16->new('inf');

  cmp_ok(is_bf16_inf($inc), '==', -1, "is -inf as expected");
  cmp_ok(is_bf16_inf($dec), '==', 1, "is +inf as expected");

  my $mpfr_inc   = Math::MPFR::Rmpfr_init2(16);
  my $mpfr_dec   = Math::MPFR::Rmpfr_init2(16);
  my $mpfr_store = Math::MPFR::Rmpfr_init2(16);
  my $rnd = 0; # Round to nearest, ties to even.
  Math::MPFR::Rmpfr_strtofr($mpfr_store, '7F80', 16, $rnd); # Infinity, as is $dec

  cmp_ok(unpack_bf16_hex($inc), 'eq', 'FF80', " -inf unpacks to FF80");
  cmp_ok(unpack_bf16_hex($dec), 'eq', '7F80', "+inf unpacks to 7F80");

  for(1..2060) {
    bf16_nextabove($inc);
    bf16_nextbelow($dec);
    my $unpack_inc = unpack_bf16_hex($inc);
    my $unpack_dec = unpack_bf16_hex($dec);

    cmp_ok(length($unpack_inc), '==', 4, "length($unpack_inc) == 4");
    cmp_ok(length($unpack_dec), '==', 4, "length($unpack_inc) == 4");

    Math::MPFR::Rmpfr_strtofr($mpfr_dec, $unpack_dec, 16, $rnd);
    cmp_ok($mpfr_store - $mpfr_dec, '==', 1, "dec has been decremented to $unpack_dec");
    Math::MPFR::Rmpfr_strtofr($mpfr_inc, $unpack_inc, 16, $rnd);
    cmp_ok($mpfr_inc - $mpfr_dec, '==', 0x8000, "inc has been incremented to $unpack_inc");

    Math::MPFR::Rmpfr_set($mpfr_store, $mpfr_dec, $rnd);
  }
}

done_testing();
