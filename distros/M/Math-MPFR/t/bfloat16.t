use strict;
use warnings;

use Math::MPFR qw(:mpfr);

use Test::More;

{
  my $check = Rmpfr_init2(8);

  my $s1 = '3.39e38';
  my $rop1 = subnormalize_bfloat16($s1 );
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok(Rmpfr_get_prec($rop1), '==', 8, "ROP1 has precision of 8");
  cmp_ok(Rmpfr_inf_p($rop1), '==', 0, "ROP1 is NOT Inf");
  cmp_ok($rop1, '==', $check, "ROP1 is set to '3.39e38'");

  Rmpfr_nextabove($check);
  cmp_ok("$check", 'eq', '3.403e38', "nextabove is '3.403e38'");

  $s1 = '-3.39e38';
  my $rop2 = subnormalize_bfloat16($s1 );
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok(Rmpfr_get_prec($rop2), '==', 8, "ROP2 has precision of 8");
  cmp_ok(Rmpfr_inf_p($rop2), '==', 0, "ROP2 is NOT Inf");
  cmp_ok($rop2, '==', $check, "ROP2 is set to '-3.39e38'");

  Rmpfr_nextbelow($check);
  cmp_ok("$check", 'eq', '-3.403e38', "nextabove is '-3.403e38'");

  $s1 = '3.403e38';
  my $rop3 = subnormalize_bfloat16($s1 );
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok("$check", 'eq', '3.403e38', "CHECK has value of '3.403e38'");
  cmp_ok(Rmpfr_get_prec($rop3), '==', 8, "ROP3 has precision of 8");
  cmp_ok(Rmpfr_inf_p($rop3), '!=', 0, "ROP3 is Inf");
  cmp_ok($rop3, '>', 0, "ROP3 is +Inf");

  $s1 = '-3.403e38';
  my $rop4 = subnormalize_bfloat16($s1 );
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok("$check", 'eq', '-3.403e38', "CHECK has value of '-3.403e38'");
  cmp_ok(Rmpfr_get_prec($rop4), '==', 8, "ROP4 has precision of 8");
  cmp_ok(Rmpfr_inf_p($rop4), '!=', 0, "ROP4 is Inf");
  cmp_ok($rop4, '<', 0, "ROP4 is -Inf");

  for my $m(1..25) {
    cmp_ok(subnormalize_bfloat16("${m}e-41" ), '==', subnormalize_bfloat16(Math::MPFR->new("${m}e-41") ), "'${m}e-41'subnormalizes ok");
    cmp_ok(subnormalize_bfloat16("-${m}e-41" ), '==', subnormalize_bfloat16(Math::MPFR->new("-${m}e-41") ), "'-${m}e-41'subnormalizes ok");
  }

  my $mpfr_denorm_min = Rmpfr_init2(8);
  Rmpfr_strtofr($mpfr_denorm_min, '9.184e-41', 0, MPFR_RNDN);

  my $mpfr_denorm_min_neg = Rmpfr_init2(8);
  Rmpfr_strtofr($mpfr_denorm_min_neg, '-9.184e-41', 0, MPFR_RNDN);

  my $mpfr_norm_max = Rmpfr_init2(8);
  Rmpfr_strtofr($mpfr_norm_max, '3.39e38', 0, MPFR_RNDN);

  my $mpfr_below_norm_max = Rmpfr_init2(8);
  Rmpfr_strtofr($mpfr_below_norm_max, '3.39e38', 0, MPFR_RNDN);
  Rmpfr_nextbelow($mpfr_below_norm_max);


  cmp_ok(subnormalize_bfloat16("0b0.1p-133" ),           '==', 0 , "'0b0.1p-133'as string subnormalizes ok");
  cmp_ok(  subnormalize_bfloat16(Math::MPFR->new("0b0.1p-133") ), '==', 0 , "'0b0.1p-133'as mpfr object subnormalizes ok");
  cmp_ok(subnormalize_bfloat16("-0b0.1p-133" ),           '==', 0 , "'-0b0.1p-133'as string subnormalizes ok");
  cmp_ok(  subnormalize_bfloat16(Math::MPFR->new("-0b0.1p-133") ), '==', 0 , "'-0b0.1p-133'as mpfr object subnormalizes ok");

  cmp_ok(subnormalize_bfloat16("0b0.10111p-133" ),           '==', $mpfr_denorm_min , "'0b0.10111p-133'as string subnormalizes ok");
  cmp_ok(subnormalize_bfloat16(Math::MPFR->new("0b0.10111p-133") ), '==', $mpfr_denorm_min,  "'0b0.10111p-133'as mpfr object subnormalizes ok");
  cmp_ok(subnormalize_bfloat16("-0b0.10111p-133" ),           '==', $mpfr_denorm_min_neg , "'-0b0.10111p-133'as string subnormalizes ok");
  cmp_ok(subnormalize_bfloat16(Math::MPFR->new("-0b0.10111p-133") ), '==', $mpfr_denorm_min_neg,  "'-0b0.10111p-133'as mpfr object subnormalizes ok");

  cmp_ok(subnormalize_bfloat16("0b0.11p-133" ),           '==', $mpfr_denorm_min , "'-0b0.11p-133' as string subnormalizes ok");
  cmp_ok(subnormalize_bfloat16(Math::MPFR->new("0b0.11p-133") ), '==', $mpfr_denorm_min,  "'0b0.11p-133'as mpfr object subnormalizes ok");
  cmp_ok(subnormalize_bfloat16("-0b0.11p-133" ),           '==', $mpfr_denorm_min_neg , "'-0b0.11p-133' as string subnormalizes ok");
  cmp_ok(subnormalize_bfloat16(Math::MPFR->new("-0b0.11p-133") ), '==', $mpfr_denorm_min_neg,  "'-0b0.11p-133' as mpfr object subnormalizes ok");

  cmp_ok(subnormalize_bfloat16("0b0.1111111p128" ),           '==', $mpfr_below_norm_max , "'0b0.1111111p128'as string subnormalizes ok");
  cmp_ok(subnormalize_bfloat16(Math::MPFR->new("0b0.1111111p128") ), '==', $mpfr_below_norm_max,  "'0b0.1111111p128'as mpfr object subnormalizes ok");
  cmp_ok(subnormalize_bfloat16("-0b0.1111111p128" ),           '==', -$mpfr_below_norm_max , "'-0b0.1111111p128'as string subnormalizes ok");
  cmp_ok(subnormalize_bfloat16(Math::MPFR->new("-0b0.1111111p128") ), '==', -$mpfr_below_norm_max,  "'-0b0.1111111p128'as mpfr object subnormalizes ok");

  cmp_ok(subnormalize_bfloat16("0b0.11111111p128" ),           '==', $mpfr_norm_max , "NORM_MAX as string subnormalizes ok");
  cmp_ok(subnormalize_bfloat16(Math::MPFR->new("0b0.11111111p128") ), '==', $mpfr_norm_max,  "NORM_MAX as mpfr object subnormalizes ok");

  cmp_ok(Rmpfr_inf_p(subnormalize_bfloat16("0b0.111111111p128" )),           '!=', 0 , "'0b0.111111111p128'as string subnormalizes ok");
  cmp_ok(Rmpfr_inf_p(subnormalize_bfloat16(Math::MPFR->new("0b0.111111111p128") )), '!=', 0,  "'0b0.111111111p128'as mpfr object subnormalizes ok");
  cmp_ok(Rmpfr_inf_p(subnormalize_bfloat16("-0b0.111111111p128" )),           '!=', 0 , "'-0b0.111111111p128'as string subnormalizes ok");
  cmp_ok(Rmpfr_inf_p(subnormalize_bfloat16(Math::MPFR->new("-0b0.111111111p128") )), '!=', 0,  "'-0b0.111111111p128'as mpfr object subnormalizes ok");

  cmp_ok(Rmpfr_signbit(subnormalize_bfloat16("0b0.11111111p128" )),           '==', 0 , "'0b0.11111111p128'as string subnormalizes ok");
  cmp_ok(Rmpfr_signbit(subnormalize_bfloat16(Math::MPFR->new("0b0.11111111p128") )), '==', 0,  "'0b0.11111111p128'as mpfr object subnormalizes ok");
  cmp_ok(Rmpfr_signbit(subnormalize_bfloat16("-0b0.11111111p128" )),           '!=', 0 , "'-0b0.11111111p128'as string subnormalizes ok");
  cmp_ok(Rmpfr_signbit(subnormalize_bfloat16(Math::MPFR->new("-0b0.11111111p128") )), '!=', 0,  "'-0b0.11111111p128'as mpfr object subnormalizes ok");

# 8-bit Bfloat16 denorm_min is 9.184e-41:
#  0x1p-133
#  9.184e-41
#  0.10000000E-132 (MPFR)

  Rmpfr_strtofr($check, '9.184e-41', 10, MPFR_RNDN);
  my $check_neg = Rmpfr_init2(8);
  Rmpfr_strtofr($check_neg, '-9.184e-41', 10, MPFR_RNDN);

  $s1 = '0b0.1000000000000001p-133'; # Double precision '4.5919149377459931e-41')
  cmp_ok(subnormalize_bfloat16($s1 ), '==', $check, "0b0.1000000000000001p-133 ok");
  cmp_ok(subnormalize_bfloat16("-$s1" ), '==', $check_neg, "-0b0.1000000000000001p-133 ok");

  $s1 = '4.5919149377459931e-41';
  cmp_ok(subnormalize_bfloat16($s1 ), '==', $check, "4.5919149377459931e-41 as string ok");
  cmp_ok(subnormalize_bfloat16("-$s1" ), '==', $check_neg, "-4.5919149377459931e-41 as string ok");
  cmp_ok(subnormalize_bfloat16($s1 + 0 ), '==', $check, "4.5919149377459931e-41 as NV ok");
  cmp_ok(subnormalize_bfloat16(-($s1 + 0) ), '==', $check_neg, "-4.5919149377459931e-41 as NV ok");

}

if(MPFR_VERSION >= 262912) { # MPFR-4.3.0 or later
  if(Math::MPFR::_have_bfloat16()) {
    cmp_ok(Rmpfr_buildopt_bfloat16_p(),  '==', 1, "MPFR library supports __bf16");
    cmp_ok(Math::MPFR::_have_bfloat16(), '==', 1, "bfloat16 support is available && utilised");

    my $op = sqrt(Math::MPFR->new(2));
    my $nv = Rmpfr_get_bfloat16($op, MPFR_RNDN);
    cmp_ok($op, '!=', $nv, "values no longer match");

    my $op16 = Rmpfr_init2(8); # bfloat16 has 8 bits of precision.
    Rmpfr_set_ui($op16, 2, MPFR_RNDN);
    Rmpfr_sqrt($op16, $op16, MPFR_RNDN);

    cmp_ok($nv, '==', $op16, "values match");
    cmp_ok(unpack_bfloat16($nv, MPFR_RNDN), 'eq', '3FB5', 'hex unpacking of sqrt(2) is as expected');

    my $inex = Rmpfr_set_bfloat16($op, $nv, MPFR_RNDN);
    cmp_ok($inex, '==', 0, 'value set exactly');
    cmp_ok($op, '==', $op16, 'values still match');

    my $nan = unpack_bfloat16(Math::MPFR->new(), MPFR_RNDN);
    my $ok = 0;
    $ok = 1 if length($nan) == 4 && $nan =~ /^FF|^7F/i
               && Math::MPFR->new(substr($nan, -2, 2), 16) > 0x80;

    cmp_ok($ok, '==' , 1, "NaN unpacks correctly");
    warn "NaN unpacks incorrectly: got $nan\n" unless $ok;

    Rmpfr_set_inf($op, 1);
    my $pinf = unpack_bfloat16($op, MPFR_RNDN);
    cmp_ok(uc($pinf), 'eq', '7F80', '+inf unpacks correctly');

    Rmpfr_set_inf($op, -1);
    my $ninf = unpack_bfloat16($op, MPFR_RNDN);
    cmp_ok(uc($ninf), 'eq', 'FF80', '-inf unpacks correctly');

    Rmpfr_set_zero($op, 1);
    my $pzero = unpack_bfloat16($op, MPFR_RNDN);
    cmp_ok($pzero, 'eq', '0000', '0 unpacks correctly');

    Rmpfr_set_zero($op, -1);
    my $nzero = unpack_bfloat16($op, MPFR_RNDN);
    cmp_ok($nzero, 'eq', '8000', '-0 unpacks correctly');

    eval { require Math::Bfloat16; };
    unless($@) {
      my $bf_1 = sqrt(Math::Bfloat16->new(2));
      my $bf_2 = Math::Bfloat16->new();
      my $mpfr = Rmpfr_init2(8);
      Rmpfr_set_BFLOAT16($mpfr, $bf_1, MPFR_RNDN);
      Rmpfr_get_BFLOAT16($bf_2, $mpfr, MPFR_RNDN);
      cmp_ok(Math::Bfloat16::unpack_bf16_hex($bf_2), 'eq', '3FB5', 'Rmpfr_set_BFLOAT16 and Rmpfr_get_BFLOAT16 pass round trip');
    }
  }
  else {
    cmp_ok(Math::MPFR::_have_bfloat16(), '==', 0, "MPFR library support for bfloat16 is not utilised");

    my ($op, $nv) = (Math::MPFR->new(), 0);
    eval { $nv = Rmpfr_get_bfloat16($op, MPFR_RNDN);};
    like($@, qr/^Perl interface to Rmpfr_get_bfloat16 not available/, 'Rmpfr_get_bfloat16: $@ set as expected');
    eval { Rmpfr_set_bfloat16($op, $nv, MPFR_RNDN);};
    like($@, qr/^Perl interface to Rmpfr_set_bfloat16 not available/, 'Rmpfr_set_bfloat16: $@ set as expected');
  }
}
else {
  cmp_ok(Rmpfr_buildopt_bfloat16_p(), '==', 0, "Rmpfr_buildopt_bfloat16_p() returns 0");
  cmp_ok(Math::MPFR::_have_bfloat16(), '==', 0, "bfloat16 support is lacking");

  my ($op, $nv) = (Math::MPFR->new(), 0);
  eval { $nv = Rmpfr_get_bfloat16($op, MPFR_RNDN);};
  like($@, qr/^Perl interface to Rmpfr_get_bfloat16 not available/, 'Rmpfr_get_bfloat16: $@ set as expected');
  eval { Rmpfr_set_bfloat16($op, $nv, MPFR_RNDU);};
  like($@, qr/^Perl interface to Rmpfr_set_bfloat16 not available/, 'Rmpfr_set_bfloat16: $@ set as expected');
}

done_testing();
