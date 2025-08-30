use strict;
use warnings;

use Math::MPFR qw(:mpfr);

# DENORM_MIN =                  # 5.9605e-8
# DENORM_MAX =                  # 6.0976e-5
# NORM_MIN   =                  # 6.1035e-5
# NORM_MAX   =                  # 6.5504e4

use Test::More;

  for my $m(1..25) {
    cmp_ok(subnormalize_float16("${m}e-8" + 0), '==', subnormalize_float16(Math::MPFR->new("${m}e-8" + 0) ), "'${m}e-8'subnormalizes ok");
    cmp_ok(subnormalize_float16("-${m}e-8" + 0), '==', subnormalize_float16(Math::MPFR->new("-${m}e-8" + 0) ), "'-${m}e-8'subnormalizes ok");
  }

{
  my $check = Rmpfr_init2(11);

  my $s1 = '6.5504e4';
  my $rop1 = subnormalize_float16($s1);
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok(Rmpfr_get_prec($rop1), '==', 11, "ROP1 has precision of 11");
  cmp_ok(Rmpfr_inf_p($rop1), '==', 0, "ROP1 is NOT Inf");
  cmp_ok($rop1, '==', $check, "ROP1 is set to '6.5504e4'");

  Rmpfr_nextabove($check);
  cmp_ok("$check", 'eq', '6.5536e4', "nextabove is '6.5536e4'");

  $s1 = '-6.5504e4';
  my $rop2 = subnormalize_float16($s1);
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok(Rmpfr_get_prec($rop2), '==', 11, "ROP2 has precision of 11");
  cmp_ok(Rmpfr_inf_p($rop2), '==', 0, "ROP2 is NOT Inf");
  cmp_ok($rop2, '==', $check, "ROP2 is set to '-6.5504e4'");

  Rmpfr_nextbelow($check);
  cmp_ok("$check", 'eq', '-6.5536e4', "nextabove is '-6.5536e4'");

  $s1 = '6.5536e4';
  my $rop3 = subnormalize_float16($s1);
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok("$check", 'eq', '6.5536e4', "CHECK has value of '6.5536e4'");
  cmp_ok(Rmpfr_get_prec($rop3), '==', 11, "ROP3 has precision of 11");
  cmp_ok(Rmpfr_inf_p($rop3), '!=', 0, "ROP3 is Inf");
  cmp_ok($rop3, '>', 0, "ROP3 is +Inf");

  $s1 = '-6.5536e4';
  my $rop4 = subnormalize_float16($s1);
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok("$check", 'eq', '-6.5536e4', "CHECK has value of '-6.5536e4'");
  cmp_ok(Rmpfr_get_prec($rop4), '==', 11, "ROP4 has precision of 11");
  cmp_ok(Rmpfr_inf_p($rop4), '!=', 0, "ROP4 is Inf");
  cmp_ok($rop4, '<', 0, "ROP4 is -Inf");

}

if(MPFR_VERSION >= 262912) { # MPFR-4.3.0 or later
  if(Math::MPFR::_have_float16()) {
    cmp_ok(Rmpfr_buildopt_float16_p(),  '==', 1, "MPFR library supports _Float16");
    cmp_ok(Math::MPFR::_have_float16(), '==', 1, "_Float16 support is available && utilised");

    my $op = sqrt(Math::MPFR->new(2));
    my $nv = Rmpfr_get_float16($op, MPFR_RNDN);
    cmp_ok($op, '!=', $nv, "values no longer match");

    my $op16 = Rmpfr_init2(11); # _Float16 has 11 bits of precision.
    Rmpfr_set_ui($op16, 2, MPFR_RNDN);
    Rmpfr_sqrt($op16, $op16, MPFR_RNDN);

    cmp_ok($nv, '==', $op16, "values match");
    cmp_ok(unpack_float16($nv, MPFR_RNDN), 'eq', '3DA8', 'hex unpacking of sqrt(2) is as expected');

    my $inex = Rmpfr_set_float16($op, $nv, MPFR_RNDN);
    cmp_ok($inex, '==', 0, 'value set exactly');
    cmp_ok($op, '==', $op16, 'values still match');

    # Smallest Positive Subnormal
    cmp_ok(unpack_float16(Math::MPFR->new(2 ** -24), MPFR_RNDN), 'eq', '0001', "smallest positive subnormal ok");

    # Largest Negative Subnormal
    cmp_ok(unpack_float16(Math::MPFR->new(-(2 ** -24)), MPFR_RNDN), 'eq', '8001', "largest negative subnormal ok");

    # Largest Positive Subnormal
    cmp_ok(uc(unpack_float16(Math::MPFR->new(2 ** -14) * 1023 / 1024, MPFR_RNDN)), 'eq', '03FF', "largest positive subnormal ok");

    # Smallest Positive Normal
    cmp_ok(unpack_float16(Math::MPFR->new(2 ** -14), MPFR_RNDN), 'eq', '0400', "smallest positive normal ok");

    # Largest Number Less Than 1
    cmp_ok(uc(unpack_float16(Math::MPFR->new(2 ** -1) + ((0.5 * 1023) / 1024), MPFR_RNDN)), 'eq', '3BFF', "largest number less than 1 ok");

    # 1
    cmp_ok(uc(unpack_float16(Math::MPFR->new(1), MPFR_RNDN)), 'eq', '3C00', "1 ok");

    # Largest Normal Number
    cmp_ok(uc(unpack_float16(Math::MPFR->new(65504), MPFR_RNDN)), 'eq', '7BFF', "largest normal number ok");

    # Smallest Normal Number
    cmp_ok(uc(unpack_float16(Math::MPFR->new(-65504), MPFR_RNDN)), 'eq', 'FBFF', "smallest normal number ok");

    Rmpfr_set_inf($op, 1);
    cmp_ok(uc(unpack_float16($op, MPFR_RNDN)), 'eq', '7C00', "+inf ok");

    Rmpfr_set_inf($op, -1);
    cmp_ok(uc(unpack_float16($op, MPFR_RNDN)), 'eq', 'FC00', "-inf ok");

    Rmpfr_set_zero($op, 1);
    cmp_ok(unpack_float16($op, MPFR_RNDN), 'eq', '0000', "0 ok");

    Rmpfr_set_zero($op, -1);
    cmp_ok(unpack_float16($op, MPFR_RNDN), 'eq', '8000', "-0 ok");

    my $nan = unpack_float16(Math::MPFR->new(), MPFR_RNDN);
    my $ok = 0;
    $ok = 1 if length($nan) == 4 && $nan =~/^7|^F/i
               && Math::MPFR->new(substr($nan, -3, 3), 16) > 0xc00;

    cmp_ok($ok, '==' , 1, "NaN unpacks correctly");
    warn "NaN unpacks incorrectly: got $nan\n" unless $ok;

    eval { require Math::Float16; };
    unless($@) {
      my $bf_1 = sqrt(Math::Float16->new(2));
      my $bf_2 = Math::Float16->new();
      my $mpfr = Rmpfr_init2(8);
      Rmpfr_set_FLOAT16($mpfr, $bf_1, MPFR_RNDN);
      Rmpfr_get_FLOAT16($bf_2, $mpfr, MPFR_RNDN);
      cmp_ok($bf_2, '==', sqrt(Math::Float16->new(2)), 'sanity check');
      cmp_ok(Math::Float16::unpack_f16_hex($bf_2), 'eq', '3DA8', 'Rmpfr_set_FLOAT16 and Rmpfr_get_FLOAT16 pass round trip');
    }

  }
  else {
    cmp_ok(Math::MPFR::_have_float16(), '==', 0, "MPFR library support for_Float16 is not utilised");

    my ($op, $nv) = (Math::MPFR->new(), 0);
    eval { $nv = Rmpfr_get_float16($op, MPFR_RNDN);};
    like($@, qr/^Perl interface to Rmpfr_get_float16 not available/, 'Rmpfr_get_float16: $@ set as expected');

    eval { Rmpfr_set_float16($op, $nv, MPFR_RNDN);};
    like($@, qr/^Perl interface to Rmpfr_set_float16 not available/, 'Rmpfr_set_float16: $@ set as expected');
  }
}
else {

  cmp_ok(Rmpfr_buildopt_float16_p(), '==', 0, "Rmpfr_buildopt_float16_p() returns 0");
  cmp_ok(Math::MPFR::_have_float16(), '==', 0, "_Float16 support is lacking");

  my ($op, $nv) = (Math::MPFR->new(), 0);
  eval { $nv = Rmpfr_get_float16($op, MPFR_RNDN);};
  like($@, qr/^Perl interface to Rmpfr_get_float16 not available/, 'Rmpfr_get_float16: $@ set as expected');

  eval { Rmpfr_set_float16($op, $nv, MPFR_RNDN);};
  like($@, qr/^Perl interface to Rmpfr_set_float16 not available/, 'Rmpfr_set_float16: $@ set as expected');
}

done_testing();
