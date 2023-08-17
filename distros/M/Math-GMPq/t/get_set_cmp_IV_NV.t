# Note - there's no Rmpq_get_IV() function - and no current plan to create one.

use strict;
use warnings;
use Math::GMPq qw(:mpq IOK_flag NOK_flag POK_flag);
use Config;

use Test::More;

my $q  = Rmpq_init();
my $q2 = Rmpq_init();

my $set = 0.7830584899793429087822005385533 * 0.3837528960584712933723494643345;

my ($digits, $bits, $have_mpfr, $big_nv) = (0, 0, 0, 0);

if   ( $Config{nvsize} == 8 ) { $digits = 17   ;
                                $big_nv = 1.7976931348623157e+308;
                                $bits   = 53   } # double precision

elsif( 1 + (2 ** -200) > 1  ) { $digits = 33   ;
                                $big_nv = 1.7976931348623157e+308;
                                $bits   = 2098 } # doubledouble

elsif( length(sqrt(2)) > 23   ) { $digits = 36   ;
                                $big_nv = 1.18973149535723176508575932662800702e4932;
                                $bits   = 113  } # IEEE long double or __float128

else                          { $digits = 21   ;
                                $big_nv = 1.18973149535723176502e4932;
                                $bits   = 64   } # 80-bit extended precision long double.

# Use Math::MPFR for some checks if it's available:

eval{ require Math::MPFR; };

unless($@) {
  $have_mpfr = 1;
  $have_mpfr = 2 if $Math::MPFR::VERSION >= 4.17;
  Math::MPFR::Rmpfr_set_default_prec($bits);
}

for(1 .. 20, 100000 .. 100020) {

  my $nv = $_ / 10.01;
  $nv *= -1 if $_ % 2;

  Rmpq_set_NV($q, $nv);
  my $nv_check = Rmpq_get_NV($q);
  my $id = sprintf "%.${digits}g", $nv;

  cmp_ok($nv_check, '==', $nv, "$id survives \"set and get\" round trip");

  if($have_mpfr > 1) {
    Math::MPFR::Rmpfr_get_q($q2, Math::MPFR->new($nv));
    cmp_ok($q, '==', $q2, "Math::MPFR and Math::GMPq agree for $id");
    cmp_ok($nv_check, '==', Math::MPFR::Rmpfr_get_NV(Math::MPFR->new($nv), 0),
                            "Math:::MPFR and Math::GMPq retrieve the same NV");
  }
}

my @in = (-1022, -1040, -16382, -16400, -1074, -16445, -16494, 1 .. 70);

for (@in) {
  my $nv = 2 ** $_;

  if(NOK_flag($nv)) {
     Rmpq_set_NV($q, $nv);
     Math::MPFR::Rmpfr_get_q($q2, Math::MPFR->new($nv)) if $have_mpfr > 1;
  }
  else {
     Rmpq_set_IV($q, $nv, 1);
     Math::MPFR::Rmpfr_get_q($q2, Math::MPFR->new($nv)) if $have_mpfr > 1;
  }

  my $nv_check = Rmpq_get_NV($q);

  cmp_ok($nv_check, '==', $nv, "2 ** $_ survives \"set and get\" round trip");
  cmp_ok($q, '==', $q2, "Math::MPFR and Math::GMPq agree for 2 ** $_") if $have_mpfr > 1;
}

for(@in) {
  my $pow = $_ + 20;
  my $nv = (2 ** $_);
  $nv += (2 ** $pow);

  if(NOK_flag($nv)) {
     Rmpq_set_NV($q, $nv);
     Math::MPFR::Rmpfr_get_q($q2, Math::MPFR->new($nv)) if $have_mpfr > 1;
  }
  else {
     Rmpq_set_IV($q, $nv, 1);
     Math::MPFR::Rmpfr_get_q($q2, Math::MPFR->new($nv)) if $have_mpfr > 1;
  }

  my $nv_check = Rmpq_get_NV($q);

  cmp_ok($nv_check, '==', $nv, "(2 ** $_) + (2 ** $pow) survives \"set and get\" round trip");
  cmp_ok($q, '==', $q2, "Math::MPFR and Math::GMPq agree for (2 ** $_) + (2 ** $pow)") if $have_mpfr > 1;
}

for(1 .. ($Config{ivsize} * 8) - 21) {
  my $pow = $_ + 20;
  my $iv = (1 << $_);
  $iv += (1 << $pow);

  Rmpq_set_IV($q, $iv, 1);
  Math::MPFR::Rmpfr_get_q($q2, Math::MPFR->new($iv)) if $have_mpfr > 1;

  my $nv_check = Rmpq_get_NV($q);

  cmp_ok($nv_check, '==', $iv, "(1 << $_) + (1 << $pow) survives \"set and get\" round trip");
  cmp_ok(Rmpq_cmp_NV($q, Rmpq_get_NV($q)), '==', 0, "Rmpq_cmp_NV is as expected for (1 << $_) + (1 << $pow)");
  cmp_ok(Rmpq_cmp_IV($q, $iv, 1),            '==', 0, "Rmpq_cmp_IV is as expected for (1 << $_) + (1 << $pow)");
  cmp_ok($q, '==', $q2, "Math::MPFR and Math::GMPq agree for (1 << $_) + (1 << $pow)") if $have_mpfr > 1;
}

for(~0, ~0 >> 1, (~0 >> 1) * -1) {

  my $iv = $_;

  Rmpq_set_IV($q, $iv, 1);
  Math::MPFR::Rmpfr_get_q($q2, Math::MPFR->new($iv)) if $have_mpfr > 1;

  my $nv_check = Rmpq_get_NV($q);

  if($Config{ivsize} == $Config{nvsize}) { # ie LHS & RHS are both 8
    cmp_ok($nv_check, '!=', $iv, "$_ fails \"set and get\" round trip (as expected)");
    cmp_ok(Rmpq_cmp_NV($q, Rmpq_get_NV($q)), '!=', 0, "Rmpq_cmp_NV is as expected for $_");
    cmp_ok(Rmpq_cmp($q, $q2), '!=', 0, "Math::MPFR and Math::GMPq disagree for $_ (as expected)") if $have_mpfr > 1;
  }
  else {
    cmp_ok($nv_check, '==', $iv, "$_ survives \"set and get\" round trip");
    cmp_ok(Rmpq_cmp_NV($q, Rmpq_get_NV($q)), '==', 0, "Rmpq_cmp_NV is as expected for $_");
    cmp_ok(Rmpq_cmp($q, $q2), '==', 0, "Math::MPFR and Math::GMPq agree for $_") if $have_mpfr > 1;
  }

  cmp_ok(Rmpq_cmp_IV($q, $iv, 1), '==', 0, "Rmpq_cmp_IV is as expected for $_");
}

# $big_nv is NV_MAX and a buggy perl could assign that value
# as 'INf', so we avoid the next test if we hit such a bug.
eval {Rmpq_set_NV($q, $big_nv);};

my $nv_check;

if($@ && $@ =~ /cannot coerce an Inf to a Math::GMP/) {
  warn "\nThis perl incorrectly assigns NV_MAX as Inf\n";
}
else {
  $nv_check = Rmpq_get_NV($q);
  cmp_ok($nv_check, '==', $big_nv, "NV_MAX survives \"set and get\" round trip");
}

Rmpq_set_NV($q, $set);
$nv_check = Rmpq_get_NV($q);

cmp_ok($nv_check, '==', $set, "$set survives \"set and get\" round trip");

cmp_ok(POK_flag("$nv_check"), '==', 1, "POK_flag set as expected"  );
cmp_ok(POK_flag(2.5)        , '==', 0, "POK_flag unset as expected");

my($nan, $ninf, $pinf);

if($have_mpfr > 0) {
  $nan = Math::MPFR::Rmpfr_get_NV(Math::MPFR->new(), 0);
  my $inf = Math::MPFR->new();
  Math::MPFR::Rmpfr_set_inf($inf, 1);
  $pinf = Math::MPFR::Rmpfr_get_NV($inf, 0);

  Math::MPFR::Rmpfr_set_inf($inf, -1);
  $ninf = Math::MPFR::Rmpfr_get_NV($inf, 0);
}
else {
  $pinf = $big_nv * 16;
  $ninf = -$pinf;
  $nan = $pinf / $pinf;
}

Rmpq_set_NV($q, 0.5);

cmp_ok(Rmpq_cmp_NV($q, $pinf), '<', 0, "Rmpq_cmp_NV(+inf) handled correctly");
cmp_ok(Rmpq_cmp_NV($q, $ninf), '>', 0, "Rmpq_cmp_NV(-inf) handled correctly");

eval { Rmpq_cmp_NV($q, $nan); };
like($@, qr/cannot compare/, "Rmpq_cmp_NV(nan) handled correctly");

eval { Rmpq_cmp_NV($q, 5); };
like($@, qr/2nd argument is not an NV/, "Rmpq_cmp_NV(nan) handled correctly");

eval { Rmpq_set_NV($q, $pinf); };
like($@, qr/cannot coerce/, "Rmpq_set_NV cannot set +inf");

eval { Rmpq_set_NV($q, $ninf); };
like($@, qr/cannot coerce/, "Rmpq_set_NV cannot set -inf");

eval { Rmpq_set_NV($q, $nan); };
like($@, qr/cannot coerce/, "Rmpq_set_NV cannot set nan");

eval { Rmpq_set_IV($q, 2.5, 1); };
like($@, qr/Arg provided to Rmpq_set_IV not an IV/, "Rmpq_set_IV cannot assign an NV");

eval { Rmpq_cmp_IV($q, 2.5, 1); };
like($@, qr/Arg provided to Rmpq_cmp_IV is not an IV/, "Rmpq_cmp_IV cannot compare an NV");

done_testing();
