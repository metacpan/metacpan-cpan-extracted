use strict;
use warnings;
use Math::FakeDD qw(:all);
use Config;

use Test::More;

my $nan  = dd_nan();   # nan
my $pinf = dd_inf();   # +ve inf
my $ninf = dd_inf(-1); # -ve inf
my $pzero = Math::FakeDD->new(0);
my $nzero = $pzero * -1;
my $dd_denorm_min = Math::FakeDD->new(Math::FakeDD::DBL_DENORM_MIN);
my ($dd1, $dd2,$rt);

cmp_ok(ulp_exponent($pinf),  '==', -1074, "ulp_exponent(inf)  returns -1074");
cmp_ok(ulp_exponent($ninf),  '==', -1074, "ulp_exponent(-inf) returns -1074");
cmp_ok(ulp_exponent($nan),   '==', -1074, "ulp_exponent(nan)  returns -1074");
cmp_ok(ulp_exponent($pzero), '==', -1074, "ulp_exponent(0)    returns -1074");
cmp_ok(ulp_exponent($nzero), '==', -1074, "ulp_exponent(-0)   returns -1074");

# Run some checks on is_subnormal()
cmp_ok(is_subnormal($pinf->{msd}),  '==', 0, "is_subnormal(inf)  returns 0");
cmp_ok(is_subnormal($ninf->{msd}),  '==', 0, "is_subnormal(-inf) returns 0");
cmp_ok(is_subnormal($nan->{msd}),   '==', 0, "is_subnormal(nan)  returns 0");
cmp_ok(is_subnormal($pzero->{msd}), '==', 1, "is_subnormal(0)    returns 1");
cmp_ok(is_subnormal($nzero->{msd}), '==', 1, "is_subnormal(-0)   returns 1");
cmp_ok(is_subnormal(2**-1022), '==', 0, "is_subnormal(2**-1022) returns 0");
cmp_ok(is_subnormal(2**-1023), '==', 1, "is_subnormal(2**-1023) returns 1");
cmp_ok(is_subnormal(2**-1022 + 2**-1023), '==', 0, "is_subnormal(2**-1022 + 2**-1023) returns 0");
cmp_ok(is_subnormal(2**-1022 - 2**-1074), '==', 1, "is_subnormal(2**-1022 - 2**-1074) returns 1");

my $nu = dd_nextup($nan);
cmp_ok(dd_is_nan($nu), '==', 1, "nextup from NaN is NaN");

my $nd= dd_nextdown($nan);
cmp_ok(dd_is_nan($nd), '==', 1, "nextdown from NaN is NaN");

$nu = dd_nextup($pinf);
cmp_ok($nu, '>', 0, "nextup from +Inf is greater than 0");
cmp_ok(dd_is_inf($nu), '==', 1, "nextup from +Inf is Inf");

$nd = dd_nextdown($pinf);
cmp_ok($nd, '==', $Math::FakeDD::DD_MAX, "nextdown from +Inf is " . $Math::FakeDD::DD_MAX);
cmp_ok(dd_is_inf(dd_nextup($nd)), '==', 1, 'nextup from $Math::FakeDD::DD_MAX is inf');

$nu = dd_nextup($ninf);
cmp_ok($nu, '==', -$Math::FakeDD::DD_MAX, "nextup from -Inf is " . -$Math::FakeDD::DD_MAX);

$nd = dd_nextdown($ninf);
cmp_ok($nd, '<', 0, "nextdown from -Inf is less than 0");
cmp_ok(dd_is_inf($nd), '!=', 0, "nextdown from -Inf is Inf");

if(4 > Math::MPFR::MPFR_VERSION_MAJOR ) {
  warn "Skipping tests that rely on mpfr library being at version 4 or later\n";
  done_testing();
  exit 0;
}

$nu = dd_nextup($pzero);
cmp_ok($nu, '==', Math::FakeDD::DBL_DENORM_MIN, "nextup from +0 is $dd_denorm_min");

$nd = dd_nextdown($pzero);
cmp_ok($nd, '==', -Math::FakeDD::DBL_DENORM_MIN, "nextdown from +0 is " . -$dd_denorm_min);

$nu = dd_nextup($nzero);
cmp_ok($nu, '==', Math::FakeDD::DBL_DENORM_MIN, "nextup from -0 is $dd_denorm_min");

$nd = dd_nextdown($nzero);
cmp_ok($nd, '==', -Math::FakeDD::DBL_DENORM_MIN, "nextdown from +0 is " . -$dd_denorm_min);

my $dd_norm_min = Math::FakeDD->new(2 ** -1022);
my $dd_subnorm_max = dd_nextdown($dd_norm_min);
cmp_ok(is_subnormal($dd_subnorm_max->{msd}), '==', 1, "nextdown from 2**-1022 is subnormal");
cmp_ok(dd_nextup($dd_subnorm_max), '==', $dd_norm_min, "nextup from max subnormal is normal");

###############################################################################################
my $dd = Math::FakeDD->new(2 ** -1022) + (2 ** -1074);
# [2.225073858507202e-308 0.0]

$nu = dd_nextup($dd);
# [2.2250738585072024e-308 0.0]

cmp_ok($nu, '==', Math::FakeDD->new(2 **-1022) + (2 ** -1073),
                 "dd_nextup(2 ** -1022) + (2 ** -1074)) == (2 ** -1022) + (2 ** -1073)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [2.2250738585072014e-308 0.0]

cmp_ok($nd, '==', Math::FakeDD->new(2 **-1022),
                 "dd_nextdown(2 ** -1022) + (2 ** -1074)) == (2 ** -1022)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 1)");
cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 1)");

$dd = Math::FakeDD->new(-(2 ** -1022)) - (2 ** -1074);
# [-2.225073858507202e-308 0.0]

$nu = dd_nextup($dd);
# [-2.2250738585072014e-308 0.0]

cmp_ok($nu, '==', Math::FakeDD->new(-(2 **-1022)),
                 "dd_nextup(-(2 ** -1022)) - (2 ** -1074)) == -(2 ** -1022)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [-2.2250738585072024e-308 0.0]

cmp_ok($nd, '==', Math::FakeDD->new(-(2 **-1022)) - (2 ** -1073),
                 "dd_nextdown(-(2 ** -1022)) - (2 ** -1074)) == -(2 ** -1022) - (2 ** -1073)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 2)");
cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 2)");

###############################################################################################
###############################################################################################
$dd = Math::FakeDD->new(2 ** -1000) + (2 ** -1052);
# [9.33263618503219e-302 0.0]

$nu = dd_nextup($dd);
# [9.33263618503219e-302 5e-324]

cmp_ok($nu, '==', Math::FakeDD->new(2 **-1000) + (2 ** -1052) + Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextup(2 ** -1000) + (2 ** -1052)) == (2 ** -1000) + (2 ** -1052) + (2 ** -1074)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [9.33263618503219e-302 -5e-324]

cmp_ok($nd, '==', Math::FakeDD->new(2 **-1000) + (2 ** -1052) - Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextdown(2 ** -1000) + (2 ** -1052)) == (2 ** -1000) + (2 ** -1052) -(2 ** -1074)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 3)");
cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 3)");

$dd = Math::FakeDD->new(-(2 ** -1000)) - (2 ** -1052);
# [-9.33263618503219e-302 0.0]

$nu = dd_nextup($dd);
# [-9.33263618503219e-302 5e-324]

cmp_ok($nu, '==', Math::FakeDD->new(-(2 **-1000)) - (2 ** -1052) + Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextup(-(2 ** -1000)) - (2 ** -1052)) == -(2 ** -1000) -(2 ** -1052) + (2 ** -1074)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [-9.33263618503219e-302 -5e-324]

cmp_ok($nd, '==', Math::FakeDD->new(-(2 **-1000)) - (2 ** -1052)  - Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextdown(-(2 ** -1000)) - (2 ** -1052)) == -(2 ** -1000) - (2 ** -1052) -(2 ** -1074)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 4)");
cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip group 4)");

###############################################################################################

for(1 .. 1000) {
  my $p1 = int(rand(1024));
  $p1 *= -1 if $_ % 2; # check for equal numbers of -ve and +ve powers
  my $p2 = $p1 - int(rand(52));

  my $first  = 2 ** $p1;
  my $second = 2 ** $p2;

  $dd = Math::FakeDD->new($first) + $second;

  if(dd_is_inf($dd)) {
     # AFAICT, this will happen only when int(rand(1024)) returns
     # 1023 && int(rand(52) returns 0. But this has happened:
     # http://www.cpantesters.org/cpan/report/797cfc22-6cfd-1014-a069-bac4e3396204

     cmp_ok(dd_nextup($dd), '==', dd_inf(), "nextup(inf) is inf");
     next; # remaining tests don't cater for Inf.
  }

  $nu = dd_nextup($dd);
  cmp_ok($nu, '>', $dd, "nextup >:$nu > $dd");
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");  ## line 167
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '<', $dd, "nextdown <:$nd < $dd");
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 5)");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 5)");

  $first  *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 6)");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 6)");

  $second *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 7)");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 7)");

  $first *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 8)");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 8)");

}
###############################################################################################

for(1 .. 1000) {
  my $p1 = int(rand(1024));
  $p1 *= -1 if $_ % 2; # check for equal numbers of -ve and +ve powers
  my $p2 = $p1 - int(rand(52));

  my $p3 = int(rand(1024));
  $p3 *= -1 if $_ % 3;
  my $p4 = $p3 - int(rand(52));

  my $first  = 2 ** $p1;
  my $second = 2 ** $p2;
  my $third  = 2 ** $p3;
  my $fourth = 2 ** $p4;

  my $dd1 = Math::FakeDD->new($first) + $second;
  my $dd2 = Math::FakeDD->new($third) + $fourth;
  my $dd  = $dd1 + $dd2;

  my $nu = dd_nextup($dd);
  my $nd = dd_nextdown($dd);

  if(dd_is_inf($dd)) {
    if($dd > 0) {
      cmp_ok($nu, '>', 0, "next up from +Inf is +ve");
      cmp_ok(dd_is_inf($nu), '==', 1, "next up from +Inf is an Inf");

      cmp_ok($nd, '==', $Math::FakeDD::DD_MAX, "next down from +Inf is $Math::FakeDD::DD_MAX");
      next;
    }

    cmp_ok($nd, '<', 0, "next down from -Inf is -ve");
    cmp_ok(dd_is_inf($nd), '==', 1, "next down from -Inf is an Inf");

    cmp_ok($nu, '==', -$Math::FakeDD::DD_MAX, "next up from -Inf is -$Math::FakeDD::DD_MAX");
    next;
  }
  cmp_ok($nu, '>', $dd, "nextup >:$nu > $dd");
  cmp_ok($nd, '<', $dd, "nextdown <:$nd < $dd");

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 9)");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 9)");

  $dd1 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  $nd = dd_nextdown($dd);

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 10)");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 10)");

  $dd2 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  $nd = dd_nextdown($dd);

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 11)");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip group 11)");

  $dd1 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  $nd = dd_nextdown($dd);

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 12)");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 12)");
}
###############################################################################################

my @ss = ('1' x 53, ('1' x 52) . '0', ('1' x 51) . '00', '1101' . ('1' x 49), '11101' . ('1' x 47) . '0',);
for(@ss) { die "Bad string in \@ss" if length($_) != 53 }

my @sm = ('000', '001', '010', '011', '100', '101', '110', '111',);
for(@sm) { die "Bad string in \@sm" if length($_) != 3 }

my @sf = ('0' . ('1' x 50), '1' x 51, '00'. ('1' x 49),);
for(@sf) { die "Bad string in \@sm" if length($_) != 51 }

my $mpfr = Math::MPFR::Rmpfr_init2(2098);

for(1 .. 1000) {
  my $start = $ss[int(rand(scalar(@ss)))];
  substr($start, 1 + int(rand(53)), 0, '.'); # randomly insert a radix point.
  die "starting string is of wrong length" unless length($start) == 54;
  my $middle = $sm[int(rand(scalar(@sm)))];
  my $finish = $sf[int(rand(scalar(@sf)))];

  my $mantissa = $start . $middle . $finish;
  my $exp = $_ % 2 ? 'p+' . int(rand(1024))
                   : 'p-' . int(rand(1075));
  my $binstring = $mantissa . $exp;

  Math::MPFR::Rmpfr_strtofr($mpfr, $binstring, 2, 0);
  my $dd = mpfr2dd($mpfr);
  my $nu = dd_nextup($dd);
  my $nd = dd_nextdown($dd);

  cmp_ok($nu, '>', $dd, "nextup >:$nu > $dd") unless dd_is_inf($dd);
  cmp_ok($nd, '<', $dd, "nextdown <:$nd < $dd");

  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 13)");
  unless(dd_is_inf($dd)) { # $dd could be +inf
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 13)");
  }

  $dd *= -1;
  $nu = dd_nextup($dd);
  $nd = dd_nextdown($dd);
  cmp_ok($nu, '>', $dd, "nextup >:$nu > $dd");
  cmp_ok($nd, '<', $dd, "nextdown <:$nd < $dd") unless dd_is_inf($dd);

  unless(dd_is_inf($dd)) { # $dd could be -inf
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 14)");
  }
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 14)");
}

###############################################################################################

@ss = ('1' x 53, ('1' x 52) . '0', ('1' x 51) . '00', '1101' . ('1' x 49), '11101' . ('1' x 47) . '0',);
for(@ss) { die "Bad string in \@ss" if length($_) != 53 }

@sm = ('000', '001', '010', '011', '100', '101', '110', '111',);
for(@sm) { die "Bad string in \@sm" if length($_) != 3 }

@sf = ('0' x 51,);
for(@sf) { die "Bad string in \@sm" if length($_) != 51 }

$mpfr = Math::MPFR::Rmpfr_init2(2098);

for(1 .. 1000) {
  my $start = $ss[int(rand(scalar(@ss)))];
  substr($start, 1 + int(rand(53)), 0, '.'); # randomly insert a radix point.
  die "starting string is of wrong length" unless length($start) == 54;
  my $middle = $sm[int(rand(scalar(@sm)))];
  #my $finish = $sf[int(rand(scalar(@sf)))];
  my $finish = $sf[0];

  my $mantissa = $start . $middle . $finish;
  my $exp = $_ % 2 ? 'p+' . int(rand(1024))
                   : 'p-' . int(rand(1075));

  my $binstring = $mantissa . $exp;

  Math::MPFR::Rmpfr_strtofr($mpfr, $binstring, 2, 0);

  my $dd = mpfr2dd($mpfr);
  my $nu = dd_nextup($dd);
  my $nd = dd_nextdown($dd);
  unless($dd > 0 && dd_is_inf($dd)) {
    cmp_ok($dd, '<', $nu, sprintx($dd) . " < " . sprintx($nu));
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up roundtrip for " . sprintx($dd) . "ok" );
  }

  unless($dd < 0 && dd_is_inf($dd)) {
    cmp_ok($dd, '>', $nd, sprintx($dd) . " > " . sprintx($nd));
    cmp_ok($dd, '==', dd_nextup($nd),   "up-down roundtrip for " . sprintx($dd) . "ok" );
  }

  $dd *= -1;
  $nu = dd_nextup($dd);
  $nd = dd_nextdown($dd);

  unless($dd < 0 && dd_is_inf($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip (group 15)");
  }
  unless($dd > 0 && dd_is_inf($dd)) {
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip (group 15)");
  }
}

## Some specific values that have caused problems:
my @probs = (
    [0x1.0010000000002p-796, 0x1p-849],
    [0x1p-967, -0x1p-1022],
    [-0x1.000003ffffffep-31, 0x1p-96],
    [-0x1.000fffffffffep-10, 0x1p-81],
   );

for(@probs) {
  # Test nextdown(nextup($dd))
  my @args = @$_;
  $dd = any2dd(@args);
  #warn sprintx($dd) . "\n";
  $nu = dd_nextup($dd);
  cmp_ok($nu, '>', $dd, sprintx($nu) . ' > ' . sprintx($dd));
  $rt = dd_nextdown($nu);
  cmp_ok($rt, '==', $dd, sprintx($rt) . ' == ' . sprintx($dd));

  $dd = any2dd(-$args[0], $args[1]);
  $nu = dd_nextup($dd);
  cmp_ok($nu, '>', $dd, sprintx($nu) . ' > ' . sprintx($dd));
  $rt = dd_nextdown($nu);
  cmp_ok($rt, '==', $dd, sprintx($rt) . ' == ' . sprintx($dd));

  $dd = any2dd($args[0], -$args[1]);
  $nu = dd_nextup($dd);
  cmp_ok($nu, '>', $dd, sprintx($nu) . ' > ' . sprintx($dd));
  $rt = dd_nextdown($nu);
  cmp_ok($rt, '==', $dd, sprintx($rt) . ' == ' . sprintx($dd));

  $dd = any2dd(-$args[0], -$args[1]);
  $nu = dd_nextup($dd);
  cmp_ok($nu, '>', $dd, sprintx($nu) . ' > ' . sprintx($dd));
  $rt = dd_nextdown($nu);
  cmp_ok($rt, '==', $dd, sprintx($rt) . ' == ' . sprintx($dd));
}

for(@probs) {
  # Test nextup(nextdown($dd))
  my @args = @$_;
  $dd = any2dd(@args);
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '<', $dd, sprintx($nd) . ' < ' . sprintx($dd));
  $rt = dd_nextup($nd);
  cmp_ok($rt, '==', $dd, sprintx($rt) . ' == ' . sprintx($dd));

  $dd = any2dd(-$args[0], $args[1]);
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '<', $dd, sprintx($nd) . ' < ' . sprintx($dd));
  $rt = dd_nextup($nd);
  cmp_ok($rt, '==', $dd, sprintx($rt) . ' == ' . sprintx($dd));

  $dd = any2dd($args[0], -$args[1]);
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '<', $dd, sprintx($nd) . ' < ' . sprintx($dd));
  $rt = dd_nextup($nd);
  cmp_ok($rt, '==', $dd, sprintx($rt) . ' == ' . sprintx($dd));

  $dd = any2dd(-$args[0], -$args[1]);
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '<', $dd, sprintx($nd) . ' < ' . sprintx($dd));
  $rt = dd_nextup($nd);
  cmp_ok($rt, '==', $dd, sprintx($rt) . ' == ' . sprintx($dd));
}

for(1..1000) {
  my $e1 = int(rand(1074));
  my $e2 = int(rand(1074));
  my $init;

  $e1 = -$e1 if $_ & 1;
  $e2 = -$e2 if $_ & 3;

  if($_ & 1) {
    $dd = Math::FakeDD->new(rand() * (2 ** $e1)) + (rand() * (2 ** $e2));
  }
  else {
    $dd = Math::FakeDD->new(rand() * (2 ** $e1)) + (rand() * (2 ** $e2));
  }


  my $nu = dd_nextup($dd);
  my $nd = dd_nextdown($dd);

  if($dd >= 0) {
    cmp_ok($nu, '>', $dd, "nextup >:$nu > $dd") unless dd_is_inf($dd);
    cmp_ok($nd, '<', $dd, "nextdown <:$nd < $dd");
  }
  else {
    cmp_ok($nu, '>', $dd, "nextup >:$nu > $dd");
    cmp_ok($nd, '<', $dd, "nextdown <:$nd < $dd") unless dd_is_inf($dd);
  }
}

#################
done_testing(); #
#################


