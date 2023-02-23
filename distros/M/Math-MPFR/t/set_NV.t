use strict;
use warnings;
use Math::MPFR qw(:mpfr NOK_flag);
use Config;

use Test::More;


Rmpfr_set_default_prec(120);

my $fr1 = Rmpfr_init();
my $fr2 = Rmpfr_init();
my ($ret1, $ret2);

my $infinity = Math::MPFR->new();
Rmpfr_set_inf($infinity, 1); # positive infinity

my $inf = Rmpfr_get_NV($infinity, MPFR_RNDN);
my $nan = Rmpfr_get_NV(Math::MPFR->new(), MPFR_RNDN);
my $ninf = $inf * -1;

$ret1 = Rmpfr_set_NV($fr1, sqrt(3.0), MPFR_RNDN);

if(Math::MPFR::_has_longdouble() && !Math::MPFR::_nv_is_float128()) {
  $ret2 = Rmpfr_set_ld($fr2, sqrt(3.0), MPFR_RNDN);
}
elsif(Math::MPFR::_can_pass_float128()) {
  $ret2 = Rmpfr_set_float128($fr2, sqrt(3.0), MPFR_RNDN);
}
elsif(Math::MPFR::_nv_is_float128()) {
  $ret2 = Rmpfr_set_NV($fr2, sqrt(3.0), MPFR_RNDN); # tests 1 & 2 are bound to succeed
}
else {
  $ret2 = Rmpfr_set_d($fr2, sqrt(3.0), MPFR_RNDN);
}

cmp_ok($fr1, '==', $fr2, 'Both objects were assigned the same value');

cmp_ok($ret1, '==', $ret2, 'Both assignments returned the same "inexact" value');


cmp_ok($fr1, '==', sqrt(3.0), 'Confirmed that $fr1 was assigned the correct value');
cmp_ok($fr2, '==', sqrt(3.0), 'Confirmed that $fr2 was assigned the correct value');


Rmpfr_set_NV($fr1, $nan, MPFR_RNDN);
cmp_ok($fr1, '!=', $fr1, 'NaN != NaN');


Rmpfr_set_NV($fr1, $inf, MPFR_RNDN);
cmp_ok(Rmpfr_inf_p($fr1), '!=', 0, '$fr1 set to infinity');
cmp_ok($fr1, '>', 0, '$fr1 set to + infinity');


Rmpfr_set_NV($fr1, $ninf, MPFR_RNDN);
cmp_ok(Rmpfr_inf_p($fr1), '!=', 0, '$fr1 again set to infinity');
cmp_ok($fr1, '<', 0, '$fr1 set to - infinity');


if($Config{nvtype} eq '__float128') {
  my $nv_max = 1.18973149535723176508575932662800702e4932;
  my $max = Rmpfr_init2(113);
  Rmpfr_set_NV($max, $nv_max, MPFR_RNDN);
  cmp_ok($max, '==', $nv_max, '$max == NV_MAX');
  cmp_ok(Rmpfr_cmp_NV($max, $nv_max), '==', 0, 'Rmpfr_cmp_NV agrees with overloaded "=="');

  my $nv_small_neg = -2.75423489483742700033038566794997947e-4928;
  my $small_neg = Rmpfr_init2(113);
  Rmpfr_set_NV($small_neg, $nv_small_neg, MPFR_RNDN);
  cmp_ok($small_neg, '==', $nv_small_neg, 'negative value close to zero assigned correctly');
  cmp_ok(Rmpfr_cmp_NV($small_neg, $nv_small_neg), '==', 0, 'Rmpfr_cmp_NV again agrees with overloaded "=="');
}

# We'll now check some more values - even ones that are not NVs.
# If the value is an NV, Rmpfr_set_NV should agree with both
# MPFR_SET_NV() and MPFR_INIT_SET_NV().
# If the value is not an NV, then Rmpfr_set_NV should croak
# with expected error message that value is "not an NV".

my $bits = $Math::MPFR::NV_properties{bits};

if    ($bits == 53)                     { *MPFR_SET_NV      =\&Rmpfr_set_d;
                                          *MPFR_INIT_SET_NV =\&Rmpfr_init_set_d;
                                          *MPFR_CMP_NV      =\&Rmpfr_cmp_d;
                                          warn "\nUsing mpfr*_set_d and mpfr_cmp_d functions\n";   }

elsif($Config{nvtype} eq 'long double') { *MPFR_SET_NV      = \&Rmpfr_set_ld;
                                          *MPFR_INIT_SET_NV = \&Rmpfr_init_set_ld;
                                          *MPFR_CMP_NV      = \&Rmpfr_cmp_ld;
                                          warn "\nUsing mpfr*_set_ld and mpfr_cmp_ld functions\n";   }

else                                    { *MPFR_SET_NV      = \&Rmpfr_set_float128;
                                          *MPFR_INIT_SET_NV = \&Rmpfr_init_set_float128;
                                          *MPFR_CMP_NV      = \&Rmpfr_cmp_float128;
                                          warn "\nUsing mpfr_set_float128 function\n";   }
Rmpfr_set_default_prec($bits);

my $x = '42.3';
my $y = ~0;
my $z = -1;

my @in = (0, 'inf', '-inf', 'nan', '-nan', 'hello', ~0, -1, sqrt(2), Math::MPFR->new(),
    Math::MPFR->new(-11), $x, \$x, "$y", "$z", 2 ** 32, 2 ** 64, 2 ** -1069, 2 ** -16300,
    ~0 * 2, ~0 * -2, 'nan' + 0, 'inf' + 0, '-inf' + 0, '-nan' + 0);

for(@in) {

  no warnings 'numeric';

  # Create copies of $_ - and use each copy only once
  # as perl might change the flags.
  my($c1, $c2, $c3, $c4) = ($_, $_, $_, $_);

  my $rnd = int(rand(4));
  my($rop1, $inex1);

  if(NOK_flag($c1)) {
    ($rop1, $inex1) = Rmpfr_init_set_NV($c1, $rnd);
  }
  else {
    eval {($rop1, $inex1) = Rmpfr_init_set_NV($c1, $rnd);};
    like($@, qr/In Rmpfr_set_NV, 2nd argument is not an NV/, '$@ set as expected');
    next;
  }
  my($rop2, $inex2) = MPFR_INIT_SET_NV ($c2, $rnd);

  my $rop3  = Math::MPFR->new();
  my $rop4  = Math::MPFR->new();
  my $inex3 = Rmpfr_set_NV($rop3, $c3, $rnd);
  my $inex4 = MPFR_SET_NV ($rop4, $c4, $rnd);

  cmp_ok($inex1, '==', $inex2, "$rnd: $_: \$inex1 == \$inex2");
  cmp_ok($inex1, '==', $inex3, "$rnd: $_: \$inex1 == \$inex3");
  cmp_ok($inex1, '==', $inex4, "$rnd: $_: \$inex1 == \$inex4");

  next if(Rmpfr_nan_p($rop1) && Rmpfr_nan_p($rop2) &&
       Rmpfr_nan_p($rop3) && Rmpfr_nan_p($rop4));

  cmp_ok($rop1, '==', $rop2, "$rnd: $_: \$rop1 == \$rop2");
  cmp_ok($rop1, '==', $rop3, "$rnd: $_: \$rop1 == \$rop3");
  cmp_ok($rop1, '==', $rop4, "$rnd: $_: \$rop1 == \$rop2");
}

# We'll now run similar checks on Rmpfr_cmp_NV, using the
# values (in @in) that we've already used to check Rmpfr_set_NV.
# In all cases where the value is an NV, Rmpfr_cmp_NV should
# agree with MPFR_CMP_NV().

for(@in) {

  no warnings 'numeric';

  # Create copies of $_ - and use each copy only once
  # as perl might change the flags.
  my($c1, $c2, $c3,) = ($_, $_, $_);

  my $rop1  = Math::MPFR->new(10);

  if(!NOK_flag($c1)) {
    like($@, qr/not an NV/, '$@ set as expected');
  }
  elsif(Rmpfr_cmp_NV($rop1, $c1) < 0) {
    cmp_ok(MPFR_CMP_NV($rop1, $c3), '<', 0, "$_: comparisons concur");
  }
  elsif(Rmpfr_cmp_NV($rop1, $c2) == 0) {
    cmp_ok(MPFR_CMP_NV($rop1, $c3), '==', 0, "$_: comparisons concur");
  }
  else {
    cmp_ok(MPFR_CMP_NV($rop1, $c3), '>', 0, "$_: comparisons concur");
  }
}

done_testing();

# No longer used
#sub init_set_float128 {
#  no warnings 'numeric';
#  my $ret = Math::MPFR->new();
#  my $inex = Rmpfr_set_float128($ret, $_[0], $_[1]);
#  return ($ret, $inex);
#}
