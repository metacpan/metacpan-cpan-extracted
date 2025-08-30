use strict;
use warnings;

use Math::MPFR qw(:mpfr);

use Test::More;

  for my $m(1..25) {
    cmp_ok(subnormalize_float16("${m}e-46" + 0), '==', subnormalize_float16(Math::MPFR->new("${m}e-46" + 0) ), "'${m}e-46'subnormalizes ok");
    cmp_ok(subnormalize_float16("-${m}e-46" + 0), '==', subnormalize_float16(Math::MPFR->new("-${m}e-46" + 0) ), "'-${m}e-46'subnormalizes ok");
  }

{
  my $check = Rmpfr_init2(24);

  my $s1 = '3.40282347e38';
  my $rop1 = subnormalize_float32($s1);
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok(Rmpfr_get_prec($rop1), '==', 24, "ROP1 has precision of 24");
  cmp_ok(Rmpfr_inf_p($rop1), '==', 0, "ROP1 is NOT Inf");
  cmp_ok($rop1, '==', $check, "ROP1 is set to '3.40282347e38'");

  Rmpfr_nextabove($check);
  cmp_ok("$check", 'eq', '3.40282367e38', "nextabove is '3.40282367e38'");

  $s1 = '-3.40282347e38';
  my $rop2 = subnormalize_float32($s1);
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok(Rmpfr_get_prec($rop2), '==', 24, "ROP2 has precision of 24");
  cmp_ok(Rmpfr_inf_p($rop2), '==', 0, "ROP2 is NOT Inf");
  cmp_ok($rop2, '==', $check, "ROP2 is set to '-3.40282347e38'");

  Rmpfr_nextbelow($check);
  cmp_ok("$check", 'eq', '-3.40282367e38', "nextbelow is '-3.40282367e38'");

  $s1 = '3.40282367e38';
  my $rop3 = subnormalize_float32($s1);
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok("$check", 'eq', '3.40282367e38', "CHECK has value of '3.40282367e38'");
  cmp_ok(Rmpfr_get_prec($rop3), '==', 24, "ROP3 has precision of 24");
  cmp_ok(Rmpfr_inf_p($rop3), '!=', 0, "ROP3 is Inf");
  cmp_ok($rop3, '>', 0, "ROP3 is +Inf");

  $s1 = '-3.40282367e38';
  my $rop4 = subnormalize_float32($s1);
  Rmpfr_strtofr($check, $s1, 0, MPFR_RNDN);
  cmp_ok("$check", 'eq', '-3.40282367e38', "CHECK has value of '-3.40282367e38'");
  cmp_ok(Rmpfr_get_prec($rop4), '==', 24, "ROP4 has precision of 24");
  cmp_ok(Rmpfr_inf_p($rop4), '!=', 0, "ROP4 is Inf");
  cmp_ok($rop4, '<', 0, "ROP4 is -Inf");

}

my $op = sqrt(Math::MPFR->new(2));
my $nv = Rmpfr_get_flt($op, MPFR_RNDN);
cmp_ok($op, '!=', $nv, "values no longer match");

my $op32 = Rmpfr_init2(24); # _Float32 has 24 bits of precision.
Rmpfr_set_ui($op32, 2, MPFR_RNDN);
Rmpfr_sqrt($op32, $op32, MPFR_RNDN);

cmp_ok($nv, '==', $op32, "values match");
cmp_ok(unpack_float32($nv, MPFR_RNDN), 'eq', '3FB504F3', 'hex unpacking of sqrt(2) is as expected');

my $inex = Rmpfr_set_flt($op, $nv, MPFR_RNDN);

cmp_ok($inex, '==', 0, 'value was set exactly');
cmp_ok($op, '==', $op32, 'values still match');

eval { require Math::Float32; };
unless($@) {
  my $bf_1 = sqrt(Math::Float32->new(2));
  my $bf_2 = Math::Float32->new();
  my $mpfr = Rmpfr_init2(24);
  Rmpfr_set_FLT($mpfr, $bf_1, MPFR_RNDN);
  Rmpfr_get_FLT($bf_2, $mpfr, MPFR_RNDN);
  cmp_ok(Math::Float32::unpack_flt_hex($bf_2), 'eq', '3FB504F3', 'Rmpfr_set_FLT and Rmpfr_get_FLT pass round trip');
}

done_testing();
