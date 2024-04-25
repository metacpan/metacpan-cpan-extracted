use strict;
use warnings;
use Config;
use Math::Ryu qw(:all);

use Test::More;

if(Math::Ryu::_compiler_has_uint128()) { warn "\nCompiler HAS_UINT128_T: 1\n" }
else { warn "\nCompiler HAS_UINT128: 0\n" }

warn "MAX_DEC_DIG: ", Math::Ryu::MAX_DEC_DIG, "\n";

cmp_ok($Math::Ryu::VERSION, 'eq', '1.03', "\$Math::Ryu::VERSION is as expected");

cmp_ok(Math::Ryu::MAX_DEC_DIG, '!=', 0, "MAX_DEC_DIG is non-zero");

cmp_ok(Math::Ryu::MAX_DEC_DIG, '==', Math::Ryu::_get_max_dec_dig(), "MAX_DEC_DIG is ok");

if(Math::Ryu::MAX_DEC_DIG == 17) {
  *NV2S = \&d2s;
  my $s = fmtpy(d2s(sqrt 2));
  cmp_ok($s, 'eq', '1.4142135623730951', "fmtpy(d2s(sqrt(2))) is as expected");
}
elsif(Math::Ryu::MAX_DEC_DIG == 21) {
  *NV2S = \&ld2s;
  my $s = fmtpy(ld2s(sqrt 2));
  cmp_ok($s, 'eq', '1.4142135623730950488', "fmtpy(ld2s(sqrt(2))) is as expected");
}
else {
  # Math::Ryu::MAX_DEC_DIG == 36
  *NV2S = \&q2s;
  my $s = fmtpy(q2s(1.4 / 10));
  cmp_ok($s, 'eq', '0.13999999999999999999999999999999999', "fmtpy(q2s(1.4 / 10)) is as expected");
}

# It's not intended for nv2s() to take a string as its argument,
# but let's keep an eye on the behaviour anyway:
cmp_ok(nv2s('hello'), 'eq', '0.0', "nv2s('hello') returns 0.0");
my $t = nv2s(1.4 / 10);
$t .= 'mmm';

if($] < 5.03 && $Config{nvtype} eq 'double' && 0.13999999999999999 == 0.14) {
  warn "Skipping a test because this perl ($]) assigns the string '0.13999999999999999' incorrectly\n";
}
else {
  cmp_ok(nv2s($t), 'eq', nv2s(1.4 / 10), "nv2s('$t') behaves ok");
}

cmp_ok(nv2s(6.0), 'eq', '6.0', "6.0 appears in expected format");

cmp_ok(nv2s(6e-7),  'eq',  '6e-07',  "Me-0P ok");
cmp_ok(nv2s(-6e-7), 'eq', '-6e-07', "-Me-0P ok");

# Most old shit perls (pre-5.30.0) might fail to assign the
# value correctly, so we avoid next 2 tests on such systems.

if($] >= 5.03 || Math::Ryu::MAX_DEC_DIG == 36) {
  cmp_ok(nv2s(6e-117),  'eq',  '6e-117',  "Me-PPP ok");
  cmp_ok(nv2s(-6e-117), 'eq', '-6e-117', "-Me-PPP ok");
}

cmp_ok(nv2s(6e40),  'eq',  '6e+40',  "Me+PP ok");
cmp_ok(nv2s(-6e40), 'eq', '-6e+40', "-Me+PP ok");
cmp_ok(nv2s(6e9),   'eq',  '6000000000.0',  "Me+P ok");
cmp_ok(nv2s(-6e9),  'eq', '-6000000000.0', "-Me+P ok");

my $nvprec = Math::Ryu::MAX_DEC_DIG - 2;
my $nv = ('6' . ('0' x $nvprec) . '.0') + 0;
cmp_ok(nv2s($nv),  'eq', '6' . ('0' x $nvprec) . '.0', "6e+${nvprec} ok");
cmp_ok(nv2s(-$nv),  'eq', '-6' . ('0' x $nvprec) . '.0', "-6e+${nvprec} ok");
cmp_ok(fmtpy_pp(NV2S($nv)),  'eq', '6' . ('0' x $nvprec) . '.0', "6e+${nvprec} fmtpy_pp ok");
cmp_ok(fmtpy_pp(NV2S(-$nv)),  'eq', '-6' . ('0' x $nvprec) . '.0', "-6e+${nvprec} fmtpy_pp ok");

$nv = ('6125' . ('0' x ($nvprec - 3)) . '.0') + 0;
cmp_ok(nv2s($nv),  'eq', '6125' . ('0' x ($nvprec - 3)) . '.0', "6.125e+${nvprec} ok");
cmp_ok(nv2s(-$nv),  'eq', '-6125' . ('0' x ($nvprec - 3)) . '.0', "-6.125e+${nvprec} ok");
cmp_ok(fmtpy_pp(NV2S($nv)),  'eq', '6125' . ('0' x ($nvprec - 3)) . '.0', "6.125e+${nvprec} fmtpy_pp ok");
cmp_ok(fmtpy_pp(NV2S(-$nv)),  'eq', '-6125' . ('0' x ($nvprec - 3)) . '.0', "-6.125e+${nvprec} fmtpy_pp ok");

$nvprec++;
$nv = ('6' . ('0' x $nvprec) . '.0') + 0;
cmp_ok(nv2s($nv),  'eq', '6e+' . "$nvprec", "6e+${nvprec}  ok");
cmp_ok(nv2s(-$nv),  'eq', '-6e+' . "$nvprec", "-6e+${nvprec}  ok");
cmp_ok(fmtpy_pp(NV2S($nv)),  'eq', '6e+' . "$nvprec", "6e+${nvprec} fmtpy_pp ok");
cmp_ok(fmtpy_pp(NV2S(-$nv)),  'eq', '-6e+' . "$nvprec", "-6e+${nvprec} fmtpy_pp ok");

$nv = ('6125' . ('0' x ($nvprec - 3)) . '.0') + 0;
cmp_ok(nv2s($nv),  'eq', '6.125e+' . "$nvprec", "6.125e+${nvprec}  ok");
cmp_ok(nv2s(-$nv),  'eq', '-6.125e+' . "$nvprec", "-6.125e+${nvprec}  ok");
cmp_ok(fmtpy_pp(NV2S($nv)),  'eq', '6.125e+' . "$nvprec", "6.125e+${nvprec} fmtpy_pp ok");
cmp_ok(fmtpy_pp(NV2S(-$nv)),  'eq', '-6.125e+' . "$nvprec", "-6.125e+${nvprec} fmtpy_pp ok");

done_testing();
