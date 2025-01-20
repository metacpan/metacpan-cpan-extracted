
# Test exp(), exp2(), exp(10), log(), log2() and log(10).

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Config;
use Test::More;

my $v = '1.73205080756887729352744634150587232';
my $dd = Math::FakeDD->new($v);
my $repro = dd_repro($dd);
ok(dd_repro_test($repro, $dd) == 15, "$v ok");

my $exp = dd_exp($dd);
$repro = dd_repro($exp);
ok(dd_repro_test($repro, $exp) == 15, "dd_exp($v) ok");

my $log = dd_log($exp);
$repro = dd_repro($log);
ok(dd_repro_test($repro, $log) == 15, "dd_log(dd_exp($v)) ok");

ok($log == $dd, sprintx($log) . '==' . sprintx($dd));

my $exp2 = dd_exp2($dd);
$repro = dd_repro($exp2);
ok(dd_repro_test($repro, $exp2) == 15, "dd_exp2($v) ok");

my $log2 = dd_log2($exp2);
$repro = dd_repro($log2);
ok(dd_repro_test($repro, $log2) == 15, "dd_log2(dd_exp2($v)) ok");

ok($log2 == $dd, sprintx($log2) . '==' . sprintx($dd));

my $exp10 = dd_exp10($dd);
$repro = dd_repro($exp10);
ok(dd_repro_test($repro, $exp10) == 15, "dd_exp10($v) ok");

my $log10 = dd_log10($exp10);
$repro = dd_repro($log10);
ok(dd_repro_test($repro, $log10) == 15, "dd_log10(dd_exp10($v)) ok");

ok($log10 == $dd, sprintx($log10) . '==' . sprintx($dd));

my $t_0 = ~0;
my $t_plus = Math::MPFR::Rmpfr_init2(113);
Math::MPFR::Rmpfr_set_IV($t_plus, $t_0, 0);
Math::MPFR::Rmpfr_add_ui($t_plus, $t_plus, 1, 0); # $t_plus is a power of 2

my $s1 = "$t_plus";
substr($s1, 0, 1, 1); # In case the leading digit is not 1.

substr($s1, $_, 1, 0)
  for(1 .. length($s1) - 1); # $s1 is now a power of 10

$log10 = dd_log10($s1);
$repro = dd_repro($log10);
ok(dd_repro_test($repro, $log10) == 15, "dd_log10($s1) ok");

my $correct1 = $Config{ivsize} == 4 ? 12 : 23;
ok($log10 == $correct1, "log10($s1) == $correct1"); # 12

my $s2 = $s1;
$s2++;

$log10 = dd_log10($s2);
$repro = dd_repro($log10);
ok(dd_repro_test($repro, $log10) == 15, "dd_log10($s2) ok");

ok($log10 > $correct1, "log10($s2) > $correct1");

$log2 = dd_log2("$t_plus");

$repro = dd_repro($log2);
ok(dd_repro_test($repro, $log2) == 15, "dd_log2($t_plus) ok");

my $correct2 = $Config{ivsize} == 4 ? 32 : 64;
ok($log2 == $correct2, "log2($t_plus) == $correct2");

$exp2 = dd_exp2($log2);

ok($exp2 == "$t_plus", "dd_exp2($log2) == $t_plus"); # 17

$log2 = dd_log2($t_0);

$repro = dd_repro($log2);
ok(dd_repro_test($repro, $log2) == 15, "dd_log2($t_0) ok");  # 18

ok($log2 < $correct2, "dd_log2($t_0) < $correct2");        # 19

$exp2 = dd_exp2($log2);

if($Config{ivsize} == 8) {
   ok($exp2 == $t_0, "dd_exp2($log2) == $t_0"); # 20
}
else {
   ok($exp2->{msd} == 4294967295 && $exp2->{lsd} < 4e-23, "dd_exp2($log2) approximates $t_0"); # 20
}

for(0.2, 0.3, 0.4, 0.50, 0.6, 0.8, 1, 2, 100000.0001) {
  cmp_ok(log(Math::FakeDD->new($_)), '==', dd_log($_), "dd_log($_) ok");
  cmp_ok(exp(Math::FakeDD->new($_)), '==', dd_exp($_), "dd_exp($_) ok");

  cmp_ok(dd_log2(Math::FakeDD->new($_)), '==', dd_log2($_), "dd_log2($_) ok");
  cmp_ok(dd_exp2(Math::FakeDD->new($_)), '==', dd_exp2($_), "dd_exp2($_) ok");

  cmp_ok(dd_log10(Math::FakeDD->new($_)), '==', dd_log10($_), "dd_log10($_) ok");
  cmp_ok(dd_exp10(Math::FakeDD->new($_)), '==', dd_exp10($_), "dd_exp10($_) ok");
}

done_testing();

__END__
